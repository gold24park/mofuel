extends Node

signal upgrade_changed(category_id: String)

var category_upgrades: Dictionary[String, CategoryUpgrade] = {}


func _ready() -> void:
	_init_upgrades()


func _init_upgrades() -> void:
	# CategoryRegistry가 먼저 로드된 후 호출됨
	await get_tree().process_frame
	for cat in CategoryRegistry.get_all_categories():
		category_upgrades[cat.id] = _create_upgrade(cat)


func _create_upgrade(cat: CategoryResource) -> CategoryUpgrade:
	var upgrade := CategoryUpgrade.new()
	return upgrade.init_with_category(cat)


func get_upgrade(category_id: String) -> CategoryUpgrade:
	if category_upgrades.has(category_id):
		return category_upgrades[category_id]

	# 아직 초기화되지 않은 경우
	var cat := CategoryRegistry.get_category(category_id)
	if cat:
		category_upgrades[category_id] = _create_upgrade(cat)
		return category_upgrades[category_id]

	return null


func upgrade_uses(category_id: String) -> bool:
	var upgrade := get_upgrade(category_id)
	if upgrade and upgrade.upgrade_uses():
		upgrade_changed.emit(category_id)
		return true
	return false


func upgrade_multiplier(category_id: String) -> bool:
	var upgrade := get_upgrade(category_id)
	if upgrade and upgrade.upgrade_multiplier():
		upgrade_changed.emit(category_id)
		return true
	return false


func reset_all_uses() -> void:
	for upgrade in category_upgrades.values():
		upgrade.reset_uses()


func get_all_upgrades() -> Array[CategoryUpgrade]:
	var result: Array[CategoryUpgrade] = []
	result.assign(category_upgrades.values())
	return result
