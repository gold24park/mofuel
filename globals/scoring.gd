class_name Scoring
extends RefCounted

const NO_MATCH := -1  ## 패턴 미매칭 센티널

## 스트레이트 판정용 패턴 상수
const SMALL_STRAIGHT_PATTERNS := [[1, 2, 3, 4], [2, 3, 4, 5], [3, 4, 5, 6]]
const LARGE_STRAIGHT_PATTERNS := [[1, 2, 3, 4, 5], [2, 3, 4, 5, 6]]
const ALL_STRAIGHT_PATTERNS := [
	[1, 2, 3, 4, 5], [2, 3, 4, 5, 6],
	[1, 2, 3, 4], [2, 3, 4, 5], [3, 4, 5, 6],
]


#region Core Scoring
static func calculate_score(category, dice: Array) -> int:
	_process_score_effects(dice)
	var values := _get_effective_values(dice, category)
	var result := _evaluate_pattern(category, values)
	var base: int = result["base"]
	if base == NO_MATCH:
		return 0

	var pools := _collect_pools(dice)
	return int((base + pools["bonus"]) * pools["mult"])


static func _process_score_effects(dice: Array) -> void:
	var results := EffectProcessor.process_effects(dice)
	for i in dice.size():
		dice[i].score_effects.clear()
		if results.has(i):
			for r in results[i]:
				dice[i].score_effects.append(r)


static func calculate_score_with_upgrade(category, dice: Array) -> int:
	var base_score := calculate_score(category, dice)
	var upgrade := MetaState.get_upgrade(category.id)
	if upgrade:
		return int(base_score * upgrade.get_total_multiplier())
	return base_score


## bonus_pool (가산) + mult_pool (승산) 수집
static func _collect_pools(dice: Array) -> Dictionary:
	var bonus := 0
	var mult := 1.0
	for d in dice:
		bonus += d.get_total_bonus()
		mult += d.get_total_multiplier() - 1.0
	return {"bonus": bonus, "mult": mult}
#endregion


#region Effective Values (와일드카드 최적 할당)
## 주사위 인덱스 순서를 유지한 effective values 반환
## (와일드카드가 원래 위치에 배치됨 — get_pattern_indices에서 인덱스 대응 필요)
static func _get_effective_values(dice: Array, category) -> Array:
	var values: Array[int] = []
	var wildcard_indices: Array[int] = []

	# 1차: 일반 값은 제자리, 와일드카드는 플레이스홀더(0)
	for i in dice.size():
		if dice[i].is_wildcard():
			values.append(0)
			wildcard_indices.append(i)
		else:
			values.append(dice[i].current_value)

	# 2차: 와일드카드 최적 값 할당 (기존 일반 값 기반)
	var assigned: Array[int] = []
	for i in dice.size():
		if i not in wildcard_indices:
			assigned.append(values[i])

	for wc_idx in wildcard_indices:
		var best_value := _find_best_wildcard_value(assigned, category)
		values[wc_idx] = best_value
		dice[wc_idx].set_wildcard_value(best_value)
		assigned.append(best_value)

	return values


static func _find_best_wildcard_value(current_values: Array, category) -> int:
	var CT := CategoryResource.CategoryType
	match category.category_type:
		CT.HIGH_DICE:
			return GameState.MAX_FACE_VALUE

		CT.ONE_PAIR, CT.TRIPLE, CT.FOUR_CARD, CT.FIVE_CARD:
			return _get_most_common_value(current_values)

		CT.TWO_PAIR:
			return _get_two_pair_best_value(current_values)

		CT.FULL_HOUSE:
			return _get_fullhouse_best_value(current_values)

		CT.SMALL_STRAIGHT, CT.LARGE_STRAIGHT:
			return _get_straight_best_value(current_values)

	return GameState.MAX_FACE_VALUE
#endregion


#region Pattern Evaluation
## 패턴 평가: {"base": int, "indices": Array[int]} 반환
## base == NO_MATCH이면 패턴 미매칭
static func _evaluate_pattern(category, values: Array) -> Dictionary:
	var chips: int = category.base_chips
	var CT := CategoryResource.CategoryType

	match category.category_type:
		CT.HIGH_DICE:
			return {"base": chips + values.max(),
					"indices": _indices_of_max(values)}

		CT.ONE_PAIR:
			var idx := _indices_of_n_of_a_kind(values, 2)
			if idx.size() < 2:
				return _no_match()
			return {"base": chips + values[idx[0]] * 2, "indices": idx}

		CT.TWO_PAIR:
			var idx := _indices_of_two_pair(values)
			if idx.size() < 4:
				return _no_match()
			var pair_sum := 0
			for i in idx:
				pair_sum += values[i]
			return {"base": chips + pair_sum, "indices": idx}

		CT.TRIPLE:
			var idx := _indices_of_n_of_a_kind(values, 3)
			if idx.size() < 3:
				return _no_match()
			return {"base": chips + values[idx[0]] * 3, "indices": idx}

		CT.SMALL_STRAIGHT:
			var idx := _indices_of_straight(values, SMALL_STRAIGHT_PATTERNS)
			if idx.is_empty():
				return _no_match()
			return {"base": chips, "indices": idx}

		CT.FULL_HOUSE:
			if not _is_full_house(values):
				return _no_match()
			return {"base": chips + _sum_values(values),
					"indices": _all_indices(values.size())}

		CT.LARGE_STRAIGHT:
			var idx := _indices_of_straight(values, LARGE_STRAIGHT_PATTERNS)
			if idx.is_empty():
				return _no_match()
			return {"base": chips, "indices": _all_indices(values.size())}

		CT.FOUR_CARD:
			var idx := _indices_of_n_of_a_kind(values, 4)
			if idx.size() < 4:
				return _no_match()
			return {"base": chips + _sum_values(values),
					"indices": _all_indices(values.size())}

		CT.FIVE_CARD:
			var idx := _indices_of_n_of_a_kind(values, 5)
			if idx.size() < 5:
				return _no_match()
			return {"base": chips + _sum_values(values),
					"indices": _all_indices(values.size())}

	return _no_match()


static func _no_match() -> Dictionary:
	return {"base": NO_MATCH, "indices": []}
#endregion


#region Pattern Helpers
static func _count_values(values: Array) -> Dictionary:
	var counts := {}
	for v in values:
		counts[v] = counts.get(v, 0) + 1
	return counts


static func _get_unique_sorted(values: Array) -> Array[int]:
	var unique: Array[int] = []
	for v in values:
		if v not in unique:
			unique.append(v)
	unique.sort()
	return unique


static func _is_full_house(values: Array) -> bool:
	var freq := _count_values(values).values()
	freq.sort()
	match freq:
		[2, 3], [5]:
			return true
		_:
			return false


static func _all_indices(count: int) -> Array[int]:
	var result: Array[int] = []
	result.assign(range(count))
	return result


## 가장 높은 N of a Kind 값
static func _get_best_n_of_a_kind_value(values: Array, n: int) -> int:
	var counts := _count_values(values)
	var best := 0
	for value in counts:
		if counts[value] >= n and value > best:
			best = value
	return best


static func _sum_values(values: Array) -> int:
	var total := 0
	for v in values:
		total += v
	return total


## 최대값 주사위 인덱스 (1개만)
static func _indices_of_max(values: Array) -> Array[int]:
	var max_val: int = values.max()
	for i in values.size():
		if values[i] == max_val:
			return [i]
	return []


## N of a Kind 중 가장 높은 값의 인덱스 N개 반환
static func _indices_of_n_of_a_kind(values: Array, n: int) -> Array[int]:
	var target := _get_best_n_of_a_kind_value(values, n)
	var result: Array[int] = []
	for i in values.size():
		if values[i] == target and result.size() < n:
			result.append(i)
	return result


## 투 페어 인덱스 (상위 2개 페어, 각 2개씩)
static func _indices_of_two_pair(values: Array) -> Array[int]:
	var counts := _count_values(values)
	var pairs: Array[int] = []
	for value in counts:
		if counts[value] >= 2:
			pairs.append(value)
	pairs.sort()
	pairs.reverse()

	var result: Array[int] = []
	for p_idx in mini(pairs.size(), 2):
		var target: int = pairs[p_idx]
		var found := 0
		for i in values.size():
			if values[i] == target and found < 2:
				result.append(i)
				found += 1
	return result


## 스트레이트 패턴에 매칭되는 주사위 인덱스
static func _indices_of_straight(values: Array, patterns: Array) -> Array[int]:
	var unique := _get_unique_sorted(values)
	for pattern in patterns:
		var found := true
		for p in pattern:
			if p not in unique:
				found = false
				break
		if found:
			var result: Array[int] = []
			var used_values: Array[int] = []
			for p_val in pattern:
				for i in values.size():
					if values[i] == p_val and i not in result and p_val not in used_values:
						result.append(i)
						used_values.append(p_val)
						break
			return result
	return []
#endregion


#region Wildcard Helpers
static func _get_most_common_value(values: Array) -> int:
	var counts := _count_values(values)
	var best_value := GameState.MAX_FACE_VALUE
	var best_count := 0

	for value in counts:
		if counts[value] > best_count or (counts[value] == best_count and value > best_value):
			best_count = counts[value]
			best_value = value

	return best_value if best_count > 0 else GameState.MAX_FACE_VALUE


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
		for v in range(GameState.MAX_FACE_VALUE, 0, -1):
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
			for v2 in range(GameState.MAX_FACE_VALUE, 0, -1):
				if v2 != value:
					return v2

	# 2개짜리가 있으면 3개 만들기
	for value in counts:
		if counts[value] >= 2:
			return value

	return GameState.MAX_FACE_VALUE


static func _get_straight_best_value(values: Array) -> int:
	var unique := _get_unique_sorted(values)

	# 1개만 빠진 패턴 우선 (와일드카드로 완성 가능)
	for straight in ALL_STRAIGHT_PATTERNS:
		var missing: Array[int] = []
		for needed in straight:
			if needed not in unique:
				missing.append(needed)
		if missing.size() == 1:
			return missing[0]

	# 완성 불가 시 첫 번째 빈 숫자 반환
	for straight in ALL_STRAIGHT_PATTERNS:
		for needed in straight:
			if needed not in unique:
				return needed

	return GameState.MAX_FACE_VALUE
#endregion


#region Public Queries
static func calculate_all_scores(dice: Array) -> Dictionary:
	var results := {}
	for cat in CategoryRegistry.get_all_categories():
		results[cat.id] = calculate_score_with_upgrade(cat, dice)
	return results


## 최고 점수 카테고리 반환. 없으면 빈 Dictionary
static func get_best_category(dice: Array) -> Dictionary:
	var all_scores := calculate_all_scores(dice)
	var best_id: String = ""
	var best_score: int = 0
	for cat_id in all_scores:
		if all_scores[cat_id] > best_score:
			best_score = all_scores[cat_id]
			best_id = cat_id
	if best_id == "":
		return {}
	return {"category_id": best_id, "score": best_score,
			"category": CategoryRegistry.get_category(best_id)}


## 패턴을 이루는 주사위 인덱스 반환 (하이라이트용)
static func get_pattern_indices(category, dice: Array) -> Array[int]:
	var values := _get_effective_values(dice, category)
	var result := _evaluate_pattern(category, values)
	var indices: Array[int] = []
	if result["base"] != NO_MATCH:
		indices.assign(result["indices"])
	return indices


## ScoreDisplay용 분해 데이터 반환
static func get_score_breakdown(category, dice: Array) -> Dictionary:
	_process_score_effects(dice)
	var values := _get_effective_values(dice, category)
	var result := _evaluate_pattern(category, values)
	var base: int = result["base"]

	if base == NO_MATCH:
		return {"category_name": category.display_name, "base": 0,
				"bonus_pool": 0, "mult_pool": 1.0, "final": 0}

	var pools := _collect_pools(dice)
	return {"category_name": category.display_name, "base": base,
			"bonus_pool": pools["bonus"], "mult_pool": pools["mult"],
			"final": int((base + pools["bonus"]) * pools["mult"])}
#endregion
