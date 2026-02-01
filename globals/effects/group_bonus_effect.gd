class_name GroupBonusEffect
extends DiceEffectResource
## 특정 그룹 태그를 가진 주사위에 보너스 부여


@export_group("Target Settings")
@export var target_group_name: String = ""  ## 타겟 그룹 태그 (예: "gem")

@export_group("Bonus Settings")
@export var bonus_value: int = 1
@export var bonus_multiplier: float = 1.0


func _init() -> void:
	trigger = Trigger.ON_SCORE
	target = Target.MATCHING_GROUP
	priority = 200
	effect_name = "그룹 보너스"


func evaluate(context) -> EffectResult:
	var result := EffectResult.new()

	# 조건 확인
	if condition and condition.has_method("evaluate"):
		if not condition.evaluate(context.source_dice, context.source_index):
			return result

	result.value_bonus = bonus_value
	result.value_multiplier = bonus_multiplier

	return result


## EffectProcessor에서 MATCHING_GROUP 타겟 계산 시 호출
func get_target_group() -> String:
	return target_group_name
