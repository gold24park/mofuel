class_name WildcardEffect
extends DiceEffectResource
## 특정 값(들)일 때 와일드카드로 사용 가능

## 와일드카드로 인정되는 값들. 기본값은 모든 값 (항상 와일드카드)
@export var trigger_values: Array[int] = [1, 2, 3, 4, 5, 6]


func is_wildcard_value(value: int) -> bool:
	return value in trigger_values
