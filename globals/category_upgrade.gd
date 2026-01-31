class_name CategoryUpgrade
extends RefCounted

var category: CategoryResource = null
var extra_uses: int = 0
var extra_multiplier: float = 0.0
var times_used: int = 0


func init_with_category(cat: CategoryResource) -> CategoryUpgrade:
	assert(cat != null, "CategoryUpgrade: category cannot be null")
	category = cat
	return self


func get_total_uses() -> int:
	assert(category != null, "CategoryUpgrade not initialized")
	return category.base_uses + extra_uses


func get_remaining_uses() -> int:
	return get_total_uses() - times_used


func get_total_multiplier() -> float:
	assert(category != null, "CategoryUpgrade not initialized")
	return category.base_multiplier + extra_multiplier


func can_use() -> bool:
	return get_remaining_uses() > 0


func use() -> void:
	times_used += 1


func reset_uses() -> void:
	times_used = 0


func can_upgrade_uses() -> bool:
	assert(category != null, "CategoryUpgrade not initialized")
	return get_total_uses() < category.max_uses


func can_upgrade_multiplier() -> bool:
	assert(category != null, "CategoryUpgrade not initialized")
	return get_total_multiplier() < category.max_multiplier


func upgrade_uses() -> bool:
	if can_upgrade_uses():
		extra_uses += 1
		return true
	return false


func upgrade_multiplier() -> bool:
	if can_upgrade_multiplier():
		extra_multiplier += category.multiplier_upgrade_step
		return true
	return false
