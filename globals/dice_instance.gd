class_name DiceInstance
extends RefCounted

var type: DiceTypeResource = null
var current_value: int = 0
var wildcard_assigned_value: int = 0


func init_with_type(dice_type: DiceTypeResource) -> DiceInstance:
	type = dice_type
	return self


#region Roll
func roll(physical_value: int = -1) -> int:
	var base_value := physical_value if physical_value > 0 else randi_range(1, 6)
	if type:
		current_value = type.apply_roll_effects(base_value)
	else:
		current_value = base_value
	return current_value
#endregion


#region Display (delegates to type)
func get_display_value() -> int:
	if wildcard_assigned_value > 0:
		return wildcard_assigned_value
	return current_value


func get_display_text() -> String:
	if type:
		return type.get_display_text(current_value)
	return str(current_value)
#endregion


#region Wildcard
func set_wildcard_value(value: int) -> void:
	if value >= 1 and value <= 6:
		wildcard_assigned_value = value


func clear_wildcard_value() -> void:
	wildcard_assigned_value = 0
#endregion


#region Scoring
func get_score_multiplier() -> float:
	if type:
		return type.get_score_multiplier()
	return 1.0


func apply_to_score(base_score: int) -> int:
	return int(base_score * get_score_multiplier())
#endregion
