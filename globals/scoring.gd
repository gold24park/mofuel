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
	# 카테고리에 따라 최적의 와일드카드 값 결정
	match category.category_type:
		0:  # ONES
			return 1
		1:  # TWOS
			return 2
		2:  # THREES
			return 3
		3:  # FOURS
			return 4
		4:  # FIVES
			return 5
		5:  # SIXES
			return 6
		10, 6:  # YACHT, FOUR_OF_A_KIND
			return _get_most_common_value(current_values)
		7:  # FULL_HOUSE
			return _get_fullhouse_best_value(current_values)
		8, 9:  # SMALL_STRAIGHT, LARGE_STRAIGHT
			return _get_straight_best_value(current_values)
		11:  # CHANCE
			return 6

	return 6


static func _get_most_common_value(values: Array) -> int:
	var counts = _count_values(values)
	var best_value = 6
	var best_count = 0

	for value in counts:
		if counts[value] > best_count or (counts[value] == best_count and value > best_value):
			best_count = counts[value]
			best_value = value

	return best_value if best_count > 0 else 6


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


static func _calculate_base_score(category, values: Array, dice: Array) -> int:
	match category.category_type:
		0, 1, 2, 3, 4, 5:  # ONES through SIXES
			return _calculate_number_score(category.target_number, values, dice)

		6:  # FOUR_OF_A_KIND
			if _has_n_of_a_kind(values, 4):
				return _calculate_sum_with_effects(values, dice)
			return 0

		7:  # FULL_HOUSE
			if _is_full_house(values):
				return _calculate_sum_with_effects(values, dice)
			return 0

		8:  # SMALL_STRAIGHT
			if _is_small_straight(values):
				return _apply_fixed_score_with_effects(category.fixed_score, dice)
			return 0

		9:  # LARGE_STRAIGHT
			if _is_large_straight(values):
				return _apply_fixed_score_with_effects(category.fixed_score, dice)
			return 0

		10:  # YACHT
			if _has_n_of_a_kind(values, 5):
				return _apply_fixed_score_with_effects(category.fixed_score, dice)
			return 0

		11:  # CHANCE
			return _calculate_sum_with_effects(values, dice)

	return 0


static func _calculate_number_score(target: int, values: Array, dice: Array) -> int:
	var score = 0
	for i in range(values.size()):
		if values[i] == target:
			if i < dice.size():
				score += dice[i].get_scoring_value()
			else:
				score += target
	return score


static func _calculate_sum_with_effects(_values: Array, dice: Array) -> int:
	var score = 0
	for i in range(dice.size()):
		score += dice[i].get_scoring_value()
	return score


static func _apply_fixed_score_with_effects(fixed_score: int, dice: Array) -> int:
	var total_multiplier := 1.0
	for d in dice:
		total_multiplier *= d.get_total_score_multiplier()
	return int(fixed_score * total_multiplier)


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


static func calculate_all_scores(dice: Array) -> Dictionary:
	var results = {}
	for cat in CategoryRegistry.get_all_categories():
		results[cat.id] = calculate_score_with_upgrade(cat, dice)
	return results
