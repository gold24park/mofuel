class_name Scoring
extends RefCounted


static func calculate_score(category, dice: Array) -> int:
	# ON_SCORE 효과 처리
	_process_score_effects(dice)

	var values = _get_effective_values(dice, category)
	var base_score = _calculate_base_score(category, values, dice)

	# 영구 보너스/배수 적용
	var permanent_bonus := 0
	var permanent_multiplier := 1.0
	for d in dice:
		for result in d.score_effects:
			permanent_bonus += result.permanent_bonus
			permanent_multiplier *= result.permanent_multiplier

	return int((base_score + permanent_bonus) * permanent_multiplier)


## 효과 처리
static func _process_score_effects(dice: Array) -> void:
	var results := EffectProcessor.process_effects(dice)

	# 각 주사위에 결과 할당
	for i in range(dice.size()):
		dice[i].score_effects.clear()
		if results.has(i):
			for result in results[i]:
				dice[i].score_effects.append(result)


static func calculate_score_with_upgrade(category, dice: Array) -> int:
	var base_score = calculate_score(category, dice)
	var upgrade = MetaState.get_upgrade(category.id)
	if upgrade:
		return int(base_score * upgrade.get_total_multiplier())
	return base_score


#region Effective Values (와일드카드 최적 할당)
static func _get_effective_values(dice: Array, category) -> Array:
	var values = []
	var wildcards = []

	# 일반 값과 와일드카드 분리
	for d in dice:
		if d.is_wildcard():
			wildcards.append(d)
		else:
			values.append(d.current_value)

	# 와일드카드 최적 값 계산
	for wc in wildcards:
		var best_value = _find_best_wildcard_value(values, category)
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


#region Base Score Calculation
static func _calculate_base_score(category, values: Array, dice: Array) -> int:
	var CT := CategoryResource.CategoryType
	match category.category_type:
		CT.HIGH_DICE:
			return _calculate_high_dice(dice)

		CT.ONE_PAIR:
			if _has_n_of_a_kind(values, 2):
				return _calculate_pair_score(values, dice, 1)
			return 0

		CT.TWO_PAIR:
			if _is_two_pair(values):
				return _calculate_two_pair_score(values, dice)
			return 0

		CT.TRIPLE:
			if _has_n_of_a_kind(values, 3):
				return _calculate_n_of_a_kind_score(values, dice, 3)
			return 0

		CT.SMALL_STRAIGHT:
			if _is_small_straight(values):
				return _apply_fixed_score_with_effects(category.fixed_score, dice)
			return 0

		CT.FULL_HOUSE:
			if _is_full_house(values):
				return _calculate_sum_with_effects(dice)
			return 0

		CT.LARGE_STRAIGHT:
			if _is_large_straight(values):
				return _apply_fixed_score_with_effects(category.fixed_score, dice)
			return 0

		CT.FOUR_CARD:
			if _has_n_of_a_kind(values, 4):
				return _calculate_sum_with_effects(dice)
			return 0

		CT.FIVE_CARD:
			if _has_n_of_a_kind(values, 5):
				return _apply_fixed_score_with_effects(category.fixed_score, dice)
			return 0

	return 0
#endregion


#region Score Helpers
## 하이다이스 — 가장 높은 주사위 1개의 점수
static func _calculate_high_dice(dice: Array) -> int:
	var best := 0
	for d in dice:
		var score: int = d.get_scoring_value()
		if score > best:
			best = score
	return best


## 원 페어 — 가장 높은 페어의 합 (효과 적용)
static func _calculate_pair_score(values: Array, dice: Array, _pair_count: int) -> int:
	var counts := _count_values(values)
	var best_pair_value := 0

	for value in counts:
		if counts[value] >= 2 and value > best_pair_value:
			best_pair_value = value

	if best_pair_value == 0:
		return 0

	# 해당 값의 주사위 2개 점수 합산
	var score := 0
	var counted := 0
	for i in range(values.size()):
		if values[i] == best_pair_value and counted < 2:
			score += dice[i].get_scoring_value() if i < dice.size() else best_pair_value
			counted += 1
	return score


## 투 페어 — 두 페어의 합 (효과 적용)
static func _calculate_two_pair_score(values: Array, dice: Array) -> int:
	var counts := _count_values(values)
	var pairs: Array[int] = []

	for value in counts:
		if counts[value] >= 2:
			pairs.append(value)

	pairs.sort()
	pairs.reverse()  # 높은 값 우선

	if pairs.size() < 2:
		return 0

	var score := 0
	for pair_idx in range(2):
		var pair_value: int = pairs[pair_idx]
		var counted := 0
		for i in range(values.size()):
			if values[i] == pair_value and counted < 2:
				score += dice[i].get_scoring_value() if i < dice.size() else pair_value
				counted += 1
	return score


## N of a Kind — 해당 값의 N개 합 (효과 적용)
static func _calculate_n_of_a_kind_score(values: Array, dice: Array, n: int) -> int:
	var counts := _count_values(values)
	var target_value := 0

	for value in counts:
		if counts[value] >= n and value > target_value:
			target_value = value

	if target_value == 0:
		return 0

	var score := 0
	var counted := 0
	for i in range(values.size()):
		if values[i] == target_value and counted < n:
			score += dice[i].get_scoring_value() if i < dice.size() else target_value
			counted += 1
	return score


## 전체 합 (효과 적용)
static func _calculate_sum_with_effects(dice: Array) -> int:
	var score = 0
	for d in dice:
		score += d.get_scoring_value()
	return score


## 고정 점수 (배수 효과만 적용)
static func _apply_fixed_score_with_effects(fixed_score: int, dice: Array) -> int:
	var total_multiplier := 1.0
	for d in dice:
		total_multiplier *= d.get_total_score_multiplier()
	return int(fixed_score * total_multiplier)
#endregion


#region Pattern Detection
static func _count_values(values: Array) -> Dictionary:
	var counts = {}
	for v in values:
		counts[v] = counts.get(v, 0) + 1
	return counts


static func _has_n_of_a_kind(values: Array, n: int) -> bool:
	var counts = _count_values(values)
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
	var counts = _count_values(values)
	var has_three = false
	var has_two = false

	for count in counts.values():
		if count == 3:
			has_three = true
		elif count == 2:
			has_two = true
		elif count == 5:
			return true

	return has_three and has_two


static func _is_small_straight(values: Array) -> bool:
	var unique = []
	for v in values:
		if v not in unique:
			unique.append(v)
	unique.sort()

	var patterns = [[1, 2, 3, 4], [2, 3, 4, 5], [3, 4, 5, 6]]
	for pattern in patterns:
		var found = true
		for p in pattern:
			if p not in unique:
				found = false
				break
		if found:
			return true

	return false


static func _is_large_straight(values: Array) -> bool:
	var unique = []
	for v in values:
		if v not in unique:
			unique.append(v)
	unique.sort()

	return unique == [1, 2, 3, 4, 5] or unique == [2, 3, 4, 5, 6]
#endregion


#region Wildcard Helpers
static func _get_most_common_value(values: Array) -> int:
	var counts = _count_values(values)
	var best_value = 6
	var best_count = 0

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
	var counts = _count_values(values)

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
	var unique = []
	for v in values:
		if v not in unique:
			unique.append(v)
	unique.sort()

	# 연속 수열 완성을 위한 빈 숫자 찾기
	var straights = [[1, 2, 3, 4, 5], [2, 3, 4, 5, 6], [1, 2, 3, 4], [2, 3, 4, 5], [3, 4, 5, 6]]

	for straight in straights:
		for needed in straight:
			if needed not in unique:
				return needed

	return 6
#endregion


static func calculate_all_scores(dice: Array) -> Dictionary:
	var results = {}
	for cat in CategoryRegistry.get_all_categories():
		results[cat.id] = calculate_score_with_upgrade(cat, dice)
	return results
