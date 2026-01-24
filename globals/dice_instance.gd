extends RefCounted

var type = null  # DiceTypeResource
var current_value: int = 0
var wildcard_assigned_value: int = 0


func init_with_type(dice_type):
	type = dice_type
	return self


func roll(physical_value: int = -1) -> int:
	var base_value = physical_value if physical_value > 0 else randi_range(1, 6)
	current_value = _apply_roll_effects(base_value)
	return current_value


func _apply_roll_effects(base_value: int) -> int:
	if type == null:
		return base_value

	# FIXED_VALUE 효과
	var fixed_effect = _get_effect(2)  # FIXED_VALUE = 2
	if fixed_effect:
		return fixed_effect.get_param("fixed_value", 6)

	# BIAS 효과
	var bias_effect = _get_effect(1)  # BIAS = 1
	if bias_effect:
		var bias_values: Array = bias_effect.get_param("bias_values", [5, 6])
		var bias_weight: float = bias_effect.get_param("bias_weight", 0.5)
		if randf() < bias_weight:
			return bias_values[randi() % bias_values.size()]

	return base_value


func _get_effect(effect_type: int):
	if type == null or type.effects == null:
		return null
	for effect in type.effects:
		if effect.type == effect_type:
			return effect
	return null


func _has_effect(effect_type: int) -> bool:
	return _get_effect(effect_type) != null


func get_display_value() -> int:
	if is_wildcard() and wildcard_assigned_value > 0:
		return wildcard_assigned_value
	return current_value


func is_wildcard() -> bool:
	return _has_effect(4)  # WILDCARD = 4


func set_wildcard_value(value: int) -> void:
	if is_wildcard() and value >= 1 and value <= 6:
		wildcard_assigned_value = value


func get_score_multiplier() -> float:
	var mult_effect = _get_effect(3)  # SCORE_MULTIPLIER = 3
	if mult_effect:
		return mult_effect.get_param("multiplier", 2.0)
	return 1.0


func apply_to_score(base_score: int) -> int:
	return int(base_score * get_score_multiplier())
