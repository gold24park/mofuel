class_name DiceEffectResource
extends Resource
## Base class for dice effects. Subclass this for specific effect types.


## Override: 롤 결과를 변환 (BIAS, FIXED_VALUE, FACE_MAP 등)
func apply_to_roll(base_value: int) -> int:
	return base_value


## Override: 점수 배수 반환 (SCORE_MULTIPLIER)
func get_score_multiplier() -> float:
	return 1.0


## Override: 이 값이 와일드카드인지 (WILDCARD, CONDITIONAL_WILDCARD)
func is_wildcard_value(_value: int) -> bool:
	return false
