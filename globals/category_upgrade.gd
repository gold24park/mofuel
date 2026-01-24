extends RefCounted

var category = null  # CategoryResource
var extra_uses: int = 0
var extra_multiplier: float = 0.0
var times_used: int = 0


func init_with_category(cat):
	category = cat
	return self


func get_total_uses() -> int:
	if category == null:
		return 1
	return category.base_uses + extra_uses


func get_remaining_uses() -> int:
	return get_total_uses() - times_used


func get_total_multiplier() -> float:
	if category == null:
		return 1.0
	return category.base_multiplier + extra_multiplier


func can_use() -> bool:
	return get_remaining_uses() > 0


func use() -> void:
	times_used += 1


func reset_uses() -> void:
	times_used = 0


func can_upgrade_uses() -> bool:
	if category == null:
		return false
	return get_total_uses() < category.max_uses


func can_upgrade_multiplier() -> bool:
	if category == null:
		return false
	return get_total_multiplier() < category.max_multiplier


func upgrade_uses() -> bool:
	if can_upgrade_uses():
		extra_uses += 1
		return true
	return false


func upgrade_multiplier() -> bool:
	if can_upgrade_multiplier():
		extra_multiplier += 0.5
		return true
	return false
