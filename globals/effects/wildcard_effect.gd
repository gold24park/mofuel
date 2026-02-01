class_name WildcardEffect
extends DiceEffectResource
## 특정 값(들)일 때 와일드카드로 사용 가능

## trigger_values must contain valid dice values (1-6)
## 기본값은 모든 값 (항상 와일드카드)
@export var trigger_values: Array[int] = [1, 2, 3, 4, 5, 6]:
	set(value):
		trigger_values = value
		for v in trigger_values:
			assert(v >= 1 and v <= 6, "trigger_values must be 1-6, got %d" % v)


func _init() -> void:
	trigger = Trigger.ON_SCORE
	target = Target.SELF
	priority = 100
	effect_name = "와일드카드"


func evaluate(context) -> EffectResult:
	var result := EffectResult.new()
	var current_value: int = context.source_dice.current_value
	if current_value in trigger_values:
		result.is_wildcard = true
	return result
