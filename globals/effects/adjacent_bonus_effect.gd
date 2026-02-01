class_name AdjacentBonusEffect
extends DiceEffectResource
## 인접 주사위에 보너스 부여


@export_group("Bonus Settings")
@export var bonus_value: int = 1
@export var bonus_multiplier: float = 1.0


func _init() -> void:
	trigger = Trigger.ON_SCORE
	target = Target.ADJACENT
	priority = 200  # 보너스는 중간 우선순위
	effect_name = "인접 보너스"


func evaluate(context) -> EffectResult:
	var result := EffectResult.new()

	# 조건 확인
	if condition and condition.has_method("evaluate"):
		if not condition.evaluate(context.source_dice, context.source_index):
			return result

	result.value_bonus = bonus_value
	result.value_multiplier = bonus_multiplier

	return result
