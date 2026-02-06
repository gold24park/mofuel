class_name BiasEffect
extends DiceEffectResource
## 특정 값들이 더 자주 나오도록 확률 조작

## bias_values must contain valid dice values (1-6)
@export var bias_values: Array[int] = []:
	set(value):
		bias_values = value
		for v in bias_values:
			assert(v >= 1 and v <= 6, "bias_values must be 1-6, got %d" % v)

@export_range(0.0, 1.0) var bias_weight: float = 0.5


func _init() -> void:
	trigger = Trigger.ON_ROLL
	target = Target.SELF
	priority = 50 # 롤 변경은 빠른 우선순위
	effect_name = "확률 조작"


func evaluate(_context) -> EffectResult:
	var result := EffectResult.new()
	if bias_values.is_empty():
		return result
	if randf() < bias_weight:
		result.modified_roll_value = bias_values[randi() % bias_values.size()]
	return result
