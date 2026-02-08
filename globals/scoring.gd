class_name Scoring
extends RefCounted


static func calculate_score(category, dice: Array) -> int:
	_process_score_effects(dice)

	var values := _get_effective_values(dice, category)
	var base := _calculate_base_score(category, values)

	# Balatro-style: 모든 주사위의 bonus/mult를 풀로 합산
	var bonus_pool := 0
	var mult_pool := 1.0
	for d in dice:
		bonus_pool += d.get_total_bonus()
		mult_pool += d.get_total_multiplier() - 1.0

	return int((base + bonus_pool) * mult_pool)


## 효과 처리
static func _process_score_effects(dice: Array) -> void:
	var results := EffectProcessor.process_effects(dice)

	# 각 주사위에 결과 할당
	for i in dice.size():
		dice[i].score_effects.clear()
		if results.has(i):
			for result in results[i]:
				dice[i].score_effects.append(result)


static func calculate_score_with_upgrade(category, dice: Array) -> int:
	var base_score := calculate_score(category, dice)
	var upgrade := MetaState.get_upgrade(category.id)
	if upgrade:
		return int(base_score * upgrade.get_total_multiplier())
	return base_score


#region Effective Values (와일드카드 최적 할당)
static func _get_effective_values(dice: Array, category) -> Array:
	var values: Array[int] = []
	var wildcards: Array = []

	# 일반 값과 와일드카드 분리
	for d in dice:
		if d.is_wildcard():
			wildcards.append(d)
		else:
			values.append(d.current_value)

	# 와일드카드 최적 값 계산
	for wc in wildcards:
		var best_value := _find_best_wildcard_value(values, category)
		values.append(best_value)
		wc.set_wildcard_value(best_value)

	return values


static func _find_best_wildcard_value(current_values: Array, category) -> int:
	var CT := CategoryResource.CategoryType
	match category.category_type:
		CT.HIGH_DICE:
			return 6

		CT.ONE_PAIR, CT.TRIPLE, CT.FOUR_CARD, CT.FIVE_CARD:
			return _get_most_common_value(current_values)

		CT.TWO_PAIR:
			return _get_two_pair_best_value(current_values)

		CT.FULL_HOUSE:
			return _get_fullhouse_best_value(current_values)

		CT.SMALL_STRAIGHT, CT.LARGE_STRAIGHT:
			return _get_straight_best_value(current_values)

	return 6
#endregion


#region Base Score Calculation (raw values only, 효과는 pool에서 적용)
static func _calculate_base_score(category, values: Array) -> int:
	var CT := CategoryResource.CategoryType
	match category.category_type:
		CT.HIGH_DICE:
			return values.max()
		CT.ONE_PAIR when _has_n_of_a_kind(values, 2):
			return _get_best_n_of_a_kind_value(values, 2) * 2
		CT.TWO_PAIR when _is_two_pair(values):
			return _calculate_two_pair_base(values)
		CT.TRIPLE when _has_n_of_a_kind(values, 3):
			return _get_best_n_of_a_kind_value(values, 3) * 3
		CT.SMALL_STRAIGHT when _is_small_straight(values):
			return category.fixed_score
		CT.FULL_HOUSE when _is_full_house(values):
			return _sum_values(values)
		CT.LARGE_STRAIGHT when _is_large_straight(values):
			return category.fixed_score
		CT.FOUR_CARD when _has_n_of_a_kind(values, 4):
			return _sum_values(values)
		CT.FIVE_CARD when _has_n_of_a_kind(values, 5):
			return category.fixed_score
	return 0
#endregion


#region Score Helpers
## 가장 높은 N of a Kind 값
static func _get_best_n_of_a_kind_value(values: Array, n: int) -> int:
	var counts := _count_values(values)
	var best := 0
	for value in counts:
		if counts[value] >= n and value > best:
			best = value
	return best


## 투 페어 base 점수
static func _calculate_two_pair_base(values: Array) -> int:
	var counts := _count_values(values)
	var pairs: Array[int] = []
	for value in counts:
		if counts[value] >= 2:
			pairs.append(value)
	pairs.sort()
	pairs.reverse()
	if pairs.size() < 2:
		return 0
	return (pairs[0] + pairs[1]) * 2


## 값 합산
static func _sum_values(values: Array) -> int:
	var total := 0
	for v in values:
		total += v
	return total
#endregion


#region Pattern Detection
static func _count_values(values: Array) -> Dictionary:
	var counts := {}
	for v in values:
		counts[v] = counts.get(v, 0) + 1
	return counts


static func _has_n_of_a_kind(values: Array, n: int) -> bool:
	var counts := _count_values(values)
	for count in counts.values():
		if count >= n:
			return true
	return false


static func _is_two_pair(values: Array) -> bool:
	var counts := _count_values(values)
	var pair_count := 0
	for count in counts.values():
		if count >= 2:
			pair_count += 1
	return pair_count >= 2


static func _is_full_house(values: Array) -> bool:
	var freq := _count_values(values).values()
	freq.sort()
	match freq:
		[2, 3], [5]:
			return true
		_:
			return false


static func _get_unique_sorted(values: Array) -> Array[int]:
	var unique: Array[int] = []
	for v in values:
		if v not in unique:
			unique.append(v)
	unique.sort()
	return unique


static func _is_small_straight(values: Array) -> bool:
	var unique := _get_unique_sorted(values)

	var patterns := [[1, 2, 3, 4], [2, 3, 4, 5], [3, 4, 5, 6]]
	for pattern in patterns:
		var found := true
		for p in pattern:
			if p not in unique:
				found = false
				break
		if found:
			return true

	return false


static func _is_large_straight(values: Array) -> bool:
	match _get_unique_sorted(values):
		[1, 2, 3, 4, 5], [2, 3, 4, 5, 6]:
			return true
		_:
			return false
#endregion


#region Wildcard Helpers
static func _get_most_common_value(values: Array) -> int:
	var counts := _count_values(values)
	var best_value := 6
	var best_count := 0

	for value in counts:
		if counts[value] > best_count or (counts[value] == best_count and value > best_value):
			best_count = counts[value]
			best_value = value

	return best_value if best_count > 0 else 6


static func _get_two_pair_best_value(values: Array) -> int:
	var counts := _count_values(values)

	# 이미 페어가 있으면 다른 페어 만들기
	var has_pair := false
	for count in counts.values():
		if count >= 2:
			has_pair = true
			break

	if has_pair:
		# 가장 높은 단독 값으로 페어 만들기
		for v in range(6, 0, -1):
			if counts.get(v, 0) == 1:
				return v
		# 단독이 없으면 최대값 페어 강화
		return _get_most_common_value(values)

	return _get_most_common_value(values)


static func _get_fullhouse_best_value(values: Array) -> int:
	var counts := _count_values(values)

	# 3개짜리가 있으면 2개짜리 만들기
	for value in counts:
		if counts[value] == 3:
			for v2 in range(6, 0, -1):
				if v2 != value:
					return v2

	# 2개짜리가 있으면 3개 만들기
	for value in counts:
		if counts[value] >= 2:
			return value

	return 6


static func _get_straight_best_value(values: Array) -> int:
	var unique := _get_unique_sorted(values)

	# 연속 수열 완성을 위한 빈 숫자 찾기
	var straights := [[1, 2, 3, 4, 5], [2, 3, 4, 5, 6], [1, 2, 3, 4], [2, 3, 4, 5], [3, 4, 5, 6]]

	for straight in straights:
		for needed in straight:
			if needed not in unique:
				return needed

	return 6
#endregion


static func calculate_all_scores(dice: Array) -> Dictionary:
	var results := {}
	for cat in CategoryRegistry.get_all_categories():
		results[cat.id] = calculate_score_with_upgrade(cat, dice)
	return results
