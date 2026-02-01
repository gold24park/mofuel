class_name CompositeCondition
extends EffectCondition
## 복합 조건 - AND/OR로 여러 조건 조합


enum Logic {
	AND,  ## 모든 조건 만족
	OR,   ## 하나 이상 만족
}


@export var logic: Logic = Logic.AND
@export var conditions: Array[EffectCondition] = []


## 조건 평가 (부모 메서드 오버라이드)
func evaluate(dice: DiceInstance, index: int) -> bool:
	if conditions.is_empty():
		return true

	match logic:
		Logic.AND:
			for cond in conditions:
				if not cond.evaluate(dice, index):
					return false
			return true

		Logic.OR:
			for cond in conditions:
				if cond.evaluate(dice, index):
					return true
			return false

	return false


## 디버그용 문자열
func to_string() -> String:
	var logic_str := "AND" if logic == Logic.AND else "OR"
	var cond_strs: Array[String] = []
	for cond in conditions:
		cond_strs.append(cond.to_string())
	return "(%s: %s)" % [logic_str, ", ".join(cond_strs)]
