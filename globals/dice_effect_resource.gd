class_name DiceEffectResource
extends Resource
## Base class for dice effects. Subclass this for specific effect types.
## Provides shared targeting + comparison infrastructure.


#region Enums
enum Target {
	SELF, ## 자신에게만 적용
	ADJACENT, ## 좌/우 인접 주사위에 적용
	ALL_DICE, ## 모든 활성 주사위에 적용
	MATCHING_VALUE, ## 같은 눈의 주사위에 적용
	MATCHING_GROUP, ## 같은 그룹 태그의 주사위에 적용
}

## 비교 대상 (comparison의 "a" 필드)
enum CompareField {
	TYPE,           ## 주사위 type.id
	GROUP,          ## 주사위 group 태그
	VALUE,          ## 굴린 눈 (current_value)
	PROBABILITY,    ## 확률 (0.0~1.0)
	INDEX,          ## 배치 위치 (0~4)
	ROLL_COUNT,     ## 누적 굴림 횟수
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
#endregion


var target: Target = Target.SELF
var comparisons: Array = []
var condition: EffectCondition = null
var effect_name: String = ""
var anim: String = ""
var sound: String = ""


#region Core Methods
## 효과 평가 - 서브클래스에서 오버라이드
func evaluate(context) -> EffectResult:
	var result := EffectResult.new()
	return result


## 타겟 인덱스 반환 (base 타겟에서 comparisons로 필터링)
func get_target_indices(context) -> Array[int]:
	var base_indices := _get_base_target_indices(context)
	if comparisons.is_empty():
		return base_indices

	var filtered: Array[int] = []
	for idx in base_indices:
		var dice = context.all_dice[idx]
		if _check_comparisons(dice, idx, context):
			filtered.append(idx)
	return filtered


## MATCHING_GROUP용 - 서브클래스에서 오버라이드
func get_target_group() -> String:
	return ""
#endregion


#region Target Resolution
## Target enum에 따른 기본 인덱스 계산 (필터링 전)
func _get_base_target_indices(context) -> Array[int]:
	match target:
		Target.SELF:
			return [context.source_index] as Array[int]

		Target.ADJACENT:
			return context.get_adjacent_indices()

		Target.ALL_DICE:
			var indices: Array[int] = []
			for i in context.all_dice.size():
				indices.append(i)
			return indices

		Target.MATCHING_VALUE:
			return context.get_matching_value_indices()

		Target.MATCHING_GROUP:
			var group := get_target_group()
			if group.is_empty():
				return [] as Array[int]
			return context.get_matching_group_indices(group)

	return [] as Array[int]
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
		CompareField.ROLL_COUNT:
			return dice.roll_count
		_:
			return null


## 비교 연산 수행
func _compare(actual: Variant, expected: Variant, op: CompareOp) -> bool:
	match op:
		CompareOp.EQ when actual is Array:
			return expected in actual
		CompareOp.EQ:
			return actual == expected
		CompareOp.NOT when actual is Array:
			return expected not in actual
		CompareOp.NOT:
			return actual != expected
		CompareOp.IN when expected is Array:
			return actual in expected
		CompareOp.IN:
			return actual == expected
		CompareOp.GTE:
			return actual >= expected
		CompareOp.LT:
			return actual < expected
		CompareOp.MOD when expected == 0:
			return false
		CompareOp.MOD:
			return int(actual) % int(expected) == 0
	return false
#endregion
