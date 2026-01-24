extends Node

const DiceTypeResourceScript = preload("res://globals/dice_type_resource.gd")
const DiceInstanceScript = preload("res://globals/dice_instance.gd")

var dice_types: Dictionary = {}  # id -> DiceTypeResource


func _ready():
	_load_all_dice_types()


func _load_all_dice_types():
	var path = "res://resources/dice_types/"
	var dir = DirAccess.open(path)

	if dir == null:
		push_warning("DiceRegistry: Cannot open directory: " + path)
		return

	dir.list_dir_begin()
	var file_name = dir.get_next()

	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".tres"):
			var res = load(path + file_name)
			if res != null and res.get_script() == DiceTypeResourceScript:
				dice_types[res.id] = res
				print("DiceRegistry: Loaded dice type: ", res.id)
		file_name = dir.get_next()

	dir.list_dir_end()
	print("DiceRegistry: Loaded ", dice_types.size(), " dice types")


func get_dice_type(id: String) -> Resource:
	if dice_types.has(id):
		return dice_types[id]
	push_warning("DiceRegistry: Unknown dice type: " + id)
	return null


func get_all_types() -> Array:
	var result = []
	for type in dice_types.values():
		result.append(type)
	return result


func get_all_by_rarity(target_rarity: int) -> Array:
	var result = []
	for type in dice_types.values():
		if type.rarity == target_rarity:
			result.append(type)
	return result


func create_instance(type_id: String):
	var dice_type = get_dice_type(type_id)
	if dice_type:
		var instance = DiceInstanceScript.new()
		return instance.init_with_type(dice_type)
	return null
