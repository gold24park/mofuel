class_name ScoreMultiplierEffect
extends DiceEffectResource
## 점수에 배수 적용

@export var multiplier: float = 2.0


func get_score_multiplier() -> float:
	return multiplier
