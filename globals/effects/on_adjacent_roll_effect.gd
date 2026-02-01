class_name OnAdjacentRollEffect
extends DiceEffectResource
## 인접 주사위가 굴려졌을 때 자신에게 보너스 부여


@export_group("Bonus Settings")
@export var self_bonus: int = 1
@export var self_multiplier: float = 1.0

@export_group("Trigger Condition")
@export var require_triggering_value: bool = false  ## 특정 눈일 때만 발동
@export var triggering_values: Array[int] = []  ## 발동 조건 눈 목록


func _init() -> void:
	trigger = Trigger.ON_ADJACENT_ROLL
	target = Target.SELF
	priority = 150  # 롤 효과는 빠른 우선순위
	effect_name = "인접 굴림 보너스"


func evaluate(context) -> EffectResult:
	var result := EffectResult.new()

	# 기본 조건 확인
	if condition and condition.has_method("evaluate"):
		if not condition.evaluate(context.source_dice, context.source_index):
			return result

	# 트리거 주사위 값 조건 확인
	if require_triggering_value and context.triggering_dice:
		var triggering_value: int = context.triggering_dice.current_value
		if triggering_value not in triggering_values:
			return result

	result.value_bonus = self_bonus
	result.value_multiplier = self_multiplier

	return result
