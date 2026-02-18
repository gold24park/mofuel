extends Node

signal upgrade_changed(category_id: String)

var category_upgrades: Dictionary[String, CategoryUpgrade] = {}
var ornament_grid := OrnamentGrid.new()
var owned_ornaments: Array[OrnamentInstance] = []


func _ready() -> void:
	_init_upgrades()
	_init_ornaments()


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


func upgrade_multiplier(category_id: String) -> bool:
	var upgrade := get_upgrade(category_id)
	if upgrade and upgrade.upgrade_multiplier():
		upgrade_changed.emit(category_id)
		return true
	return false


func get_all_upgrades() -> Array[CategoryUpgrade]:
	var result: Array[CategoryUpgrade] = []
	result.assign(category_upgrades.values())
	return result


#region Ornaments
func _init_ornaments() -> void:
	await get_tree().process_frame
	for ornament_id in OrnamentTypes.STARTING_ORNAMENTS:
		var instance := OrnamentRegistry.create_instance(ornament_id)
		if instance:
			owned_ornaments.append(instance)


func get_unplaced_ornaments() -> Array[OrnamentInstance]:
	var result: Array[OrnamentInstance] = []
	for ornament in owned_ornaments:
		if not ornament.is_placed:
			result.append(ornament)
	return result


func add_ornament(id: String) -> OrnamentInstance:
	var instance := OrnamentRegistry.create_instance(id)
	if instance:
		owned_ornaments.append(instance)
	return instance
#endregion
