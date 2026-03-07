extends Node

signal upgrade_changed(hand_rank_id: String)

var hand_rank_upgrades: Dictionary[String, HandRankUpgrade] = {}
var gear_grid := GearGrid.new()
var owned_gears: Array[GearInstance] = []


func _ready() -> void:
	_init_upgrades()
	_init_gears()


func _init_upgrades() -> void:
	# HandRankRegistry가 먼저 로드된 후 호출됨
	await get_tree().process_frame
	for hr in HandRankRegistry.get_all_hand_ranks():
		hand_rank_upgrades[hr.id] = _create_upgrade(hr)


func _create_upgrade(hr: HandRankResource) -> HandRankUpgrade:
	var upgrade := HandRankUpgrade.new()
	return upgrade.init_with_hand_rank(hr)


func get_upgrade(hand_rank_id: String) -> HandRankUpgrade:
	if hand_rank_upgrades.has(hand_rank_id):
		return hand_rank_upgrades[hand_rank_id]

	# 아직 초기화되지 않은 경우
	var hr := HandRankRegistry.get_hand_rank(hand_rank_id)
	if hr:
		hand_rank_upgrades[hand_rank_id] = _create_upgrade(hr)
		return hand_rank_upgrades[hand_rank_id]

	return null


func upgrade_multiplier(hand_rank_id: String) -> bool:
	var upgrade := get_upgrade(hand_rank_id)
	if upgrade and upgrade.upgrade_multiplier():
		upgrade_changed.emit(hand_rank_id)
		return true
	return false


func get_all_upgrades() -> Array[HandRankUpgrade]:
	var result: Array[HandRankUpgrade] = []
	result.assign(hand_rank_upgrades.values())
	return result


#region Gears
func _init_gears() -> void:
	await get_tree().process_frame
	for gear_id in GearTypes.STARTING_GEARS:
		var instance := GearRegistry.create_instance(gear_id)
		if instance:
			owned_gears.append(instance)


func get_unplaced_gears() -> Array[GearInstance]:
	var result: Array[GearInstance] = []
	for gear in owned_gears:
		if not gear.is_placed:
			result.append(gear)
	return result


func add_gear(id: String) -> GearInstance:
	var instance := GearRegistry.create_instance(id)
	if instance:
		owned_gears.append(instance)
	return instance
#endregion
