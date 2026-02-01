class_name ScoreMultiplierEffect
extends DiceEffectResource
## 점수에 배수 적용

@export var multiplier: float = 2.0


func _init() -> void:
	trigger = Trigger.ON_SCORE
	target = Target.SELF
	priority = 300  # 배수는 나중에 적용
	effect_name = "점수 배수"


func evaluate(_context) -> EffectResult:
	var result := EffectResult.new()
	result.value_multiplier = multiplier
	return result
