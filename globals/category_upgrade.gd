class_name CategoryUpgrade
extends RefCounted

var category: CategoryResource = null
var extra_multiplier: float = 0.0


func init_with_category(cat: CategoryResource) -> CategoryUpgrade:
	assert(cat != null, "CategoryUpgrade: category cannot be null")
	category = cat
	return self


func get_total_multiplier() -> float:
	assert(category != null, "CategoryUpgrade not initialized")
	return category.base_multiplier + extra_multiplier


func can_upgrade_multiplier() -> bool:
	assert(category != null, "CategoryUpgrade not initialized")
	return get_total_multiplier() < category.max_multiplier


func upgrade_multiplier() -> bool:
	if can_upgrade_multiplier():
		extra_multiplier += category.multiplier_upgrade_step
		return true
	return false
