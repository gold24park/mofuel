class_name AdjacentGroupBonusEffect
extends DiceEffectResource
## 인접하면서 특정 그룹에 속한 주사위에만 보너스 부여


@export_group("Target Settings")
@export var target_group_name: String = ""  ## 타겟 그룹 태그 (예: "peasant")

@export_group("Bonus Settings")
@export var bonus_value: int = 1
@export var bonus_multiplier: float = 1.0


func _init() -> void:
	trigger = Trigger.ON_SCORE
	target = Target.ADJACENT
	priority = 200  # 보너스는 중간 우선순위
	effect_name = "인접 그룹 보너스"


## 인접 + 그룹 조건을 AND로 결합
func get_target_indices(context) -> Array[int]:
	if target_group_name.is_empty():
		return [] as Array[int]

	var adjacent: Array[int] = context.get_adjacent_indices()
	var group_matches: Array[int] = context.get_matching_group_indices(target_group_name)

	var result: Array[int] = []
	for idx in adjacent:
		if idx in group_matches:
			result.append(idx)
	return result


func evaluate(context) -> EffectResult:
	var result := EffectResult.new()

	# 조건 확인
	if condition:
		if not condition.evaluate(context.source_dice, context.source_index):
			return result

	result.value_bonus = bonus_value
	result.value_multiplier = bonus_multiplier

	return result
