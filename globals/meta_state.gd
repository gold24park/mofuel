extends Node

const CategoryUpgradeScript = preload("res://globals/category_upgrade.gd")

signal upgrade_changed(category_id: String)

var category_upgrades: Dictionary = {}  # id -> CategoryUpgrade


func _ready():
	_init_upgrades()


func _init_upgrades():
	# CategoryRegistry가 먼저 로드된 후 호출됨
	await get_tree().process_frame
	for cat in CategoryRegistry.get_all_categories():
		var upgrade = CategoryUpgradeScript.new()
		category_upgrades[cat.id] = upgrade.init_with_category(cat)


func get_upgrade(category_id: String):
	if category_upgrades.has(category_id):
		return category_upgrades[category_id]

	# 아직 초기화되지 않은 경우
	var cat = CategoryRegistry.get_category(category_id)
	if cat:
		var upgrade = CategoryUpgradeScript.new()
		category_upgrades[category_id] = upgrade.init_with_category(cat)
		return category_upgrades[category_id]

	return null


func upgrade_uses(category_id: String) -> bool:
	var upgrade = get_upgrade(category_id)
	if upgrade and upgrade.upgrade_uses():
		upgrade_changed.emit(category_id)
		return true
	return false


func upgrade_multiplier(category_id: String) -> bool:
	var upgrade = get_upgrade(category_id)
	if upgrade and upgrade.upgrade_multiplier():
		upgrade_changed.emit(category_id)
		return true
	return false


func reset_all_uses():
	for upgrade in category_upgrades.values():
		upgrade.reset_uses()


func get_all_upgrades() -> Array:
	var result = []
	for upgrade in category_upgrades.values():
		result.append(upgrade)
	return result
