class_name BiasEffect
extends DiceEffectResource
## 특정 값들이 더 자주 나오도록 확률 조작

@export var bias_values: Array[int] = [5, 6]
@export_range(0.0, 1.0) var bias_weight: float = 0.5


func apply_to_roll(base_value: int) -> int:
	if bias_values.is_empty():
		return base_value
	if randf() < bias_weight:
		return bias_values[randi() % bias_values.size()]
	return base_value
