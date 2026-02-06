class_name ModifierEffect
extends DiceEffectResource
## 범용 수정 효과 - JSON에서 target/comparisons/value_to_change/diff 조합으로 정의
## 이전의 AdjacentBonusEffect, GroupBonusEffect, AdjacentGroupBonusEffect,
## ScoreMultiplierEffect, OnAdjacentRollEffect를 모두 대체


#region Enums
## 비교 대상 (comparison의 "a" 필드)
enum CompareField {
	TYPE,           ## 주사위 type.id
	GROUP,          ## 주사위 group 태그
	VALUE,          ## 굴린 눈 (current_value)
	PROBABILITY,    ## 확률 (0.0~1.0)
	INDEX,          ## 배치 위치 (0~4)
}

## 비교 연산자
enum CompareOp {
	EQ,   ## 같음 (기본값)
	NOT,  ## 같지 않음
	IN,   ## 배열에 포함
	GTE,  ## 크거나 같음
	LT,   ## 작음
	MOD,  ## 나머지가 0
}

## 수정 대상 (value_to_change 필드)
enum ModifyTarget {
	VALUE_BONUS,            ## 임시 가산 (EffectResult.value_bonus)
	VALUE_MULTIPLIER,       ## 임시 배수 (EffectResult.value_multiplier)
	PERMANENT_BONUS,        ## 영구 가산 (EffectResult.permanent_bonus)
	PERMANENT_MULTIPLIER,   ## 영구 배수 (EffectResult.permanent_multiplier)
}
#endregion


#region Configuration
## 타겟에 적용할 필터 조건들 (AND 결합)
## 각 항목: { "a": CompareField, "b": Variant, "op": CompareOp }
var comparisons: Array[Dictionary] = []

## 수정 대상
var modify_target: ModifyTarget = ModifyTarget.VALUE_BONUS

## 변경량 (int 또는 float)
var diff: float = 0.0

## 피드백: 애니메이션 타입 (""이면 없음, 예: "bounce", "scale", "flash")
var anim: String = ""

## 피드백: 사운드 이펙트 ID (""이면 없음)
var sound: String = ""
#endregion


#region Core Methods
## 타겟 인덱스 반환 — base 타겟에서 comparisons로 필터링
func get_target_indices(context) -> Array[int]:
	var base_indices := super.get_target_indices(context)
	if comparisons.is_empty():
		return base_indices

	var filtered: Array[int] = []
	for idx in base_indices:
		var dice = context.all_dice[idx]
		if _check_comparisons(dice, idx, context):
			filtered.append(idx)
	return filtered


## 효과 평가 — modify_target에 따라 EffectResult 필드 설정
func evaluate(context) -> EffectResult:
	var result := EffectResult.new()

	match modify_target:
		ModifyTarget.VALUE_BONUS:
			result.value_bonus = int(diff)
		ModifyTarget.VALUE_MULTIPLIER:
			result.value_multiplier = diff
		ModifyTarget.PERMANENT_BONUS:
			result.permanent_bonus = int(diff)
		ModifyTarget.PERMANENT_MULTIPLIER:
			result.permanent_multiplier = diff

	# 피드백 정보 전달
	result.anim = anim
	result.sound = sound

	return result
#endregion


#region Comparison Evaluation
## 모든 comparisons를 AND로 평가
func _check_comparisons(dice, idx: int, context) -> bool:
	for comp in comparisons:
		if not _evaluate_comparison(comp, dice, idx, context):
			return false
	return true


## 단일 comparison 평가
func _evaluate_comparison(comp: Dictionary, dice, idx: int, _context) -> bool:
	var field: CompareField = comp["a"]
	var expected = comp["b"]
	var op: CompareOp = comp.get("op", CompareOp.EQ)

	var actual = _get_field_value(field, dice, idx)

	# probability는 특수 처리: 확률 체크
	if field == CompareField.PROBABILITY:
		return randf() < expected

	return _compare(actual, expected, op)


## 비교 필드에서 실제 값 추출
func _get_field_value(field: CompareField, dice, idx: int) -> Variant:
	match field:
		CompareField.TYPE:
			return dice.type.id
		CompareField.GROUP:
			return dice.type.groups
		CompareField.VALUE:
			return dice.current_value
		CompareField.INDEX:
			return idx
		_:
			return null


## 비교 연산 수행
func _compare(actual: Variant, expected: Variant, op: CompareOp) -> bool:
	match op:
		CompareOp.EQ:
			# GROUP 필드: actual이 Array이면 expected가 그 안에 있는지 확인
			if actual is Array:
				return expected in actual
			return actual == expected
		CompareOp.NOT:
			if actual is Array:
				return expected not in actual
			return actual != expected
		CompareOp.IN:
			# expected가 Array, actual이 그 안에 있는지
			if expected is Array:
				return actual in expected
			return actual == expected
		CompareOp.GTE:
			return actual >= expected
		CompareOp.LT:
			return actual < expected
		CompareOp.MOD:
			# actual % expected == 0
			if expected == 0:
				return false
			return int(actual) % int(expected) == 0
	return false
#endregion
