class_name EffectCondition
extends Resource
## 효과 발동 조건 - Resource 기반으로 Inspector에서 편집 가능


enum Variable {
	FACE_VALUE,   ## 주사위 눈 (1-6)
	DICE_TYPE,    ## 주사위 타입 ID
	HAS_GROUP,    ## 특정 그룹 보유 여부
	POSITION,     ## 정렬 위치 (0-4)
}

enum Operator {
	EQUALS,         ## 같음
	NOT_EQUALS,     ## 다름
	GREATER_THAN,   ## 초과
	LESS_THAN,      ## 미만
	GREATER_OR_EQ,  ## 이상
	LESS_OR_EQ,     ## 이하
	CONTAINS,       ## 포함 (그룹용)
}


@export var variable: Variable = Variable.FACE_VALUE
@export var operator: Operator = Operator.EQUALS
@export var int_value: int = 0
@export var string_value: String = ""


## 조건 평가
func evaluate(dice: DiceInstance, index: int) -> bool:
	var target_value: Variant = _get_variable_value(dice, index)
	return _compare(target_value)


## 변수 값 추출
func _get_variable_value(dice: DiceInstance, index: int) -> Variant:
	match variable:
		Variable.FACE_VALUE:
			return dice.current_value
		Variable.DICE_TYPE:
			return dice.type.id
		Variable.HAS_GROUP:
			return dice.type.groups
		Variable.POSITION:
			return index
	return null


## 비교 연산 수행
func _compare(target_value: Variant) -> bool:
	match operator:
		Operator.EQUALS when variable == Variable.HAS_GROUP:
			return string_value in (target_value as Array)
		Operator.EQUALS:
			return target_value == _get_compare_value()
		Operator.NOT_EQUALS when variable == Variable.HAS_GROUP:
			return string_value not in (target_value as Array)
		Operator.NOT_EQUALS:
			return target_value != _get_compare_value()
		Operator.GREATER_THAN:
			return target_value > int_value
		Operator.LESS_THAN:
			return target_value < int_value
		Operator.GREATER_OR_EQ:
			return target_value >= int_value
		Operator.LESS_OR_EQ:
			return target_value <= int_value
		Operator.CONTAINS when target_value is Array:
			return string_value in target_value
	return false


## 비교할 값 반환
func _get_compare_value() -> Variant:
	match variable:
		Variable.FACE_VALUE, Variable.POSITION:
			return int_value
		Variable.DICE_TYPE, Variable.HAS_GROUP:
			return string_value
	return null


## 디버그용 문자열
func _to_string() -> String:
	var var_str: String = Variable.keys()[variable]
	var op_str: String = Operator.keys()[operator]
	var val_str: String = str(int_value) if variable in [Variable.FACE_VALUE, Variable.POSITION] else string_value
	return "%s %s %s" % [var_str, op_str, val_str]
