extends Node

var dice_types: Dictionary = {}  # id -> DiceTypeResource
var _error_type: DiceTypeResource = null


func _ready():
	_load_all_dice_types()
	_error_type = dice_types.get("_error")


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
			if res is DiceTypeResource:
				dice_types[res.id] = res
		file_name = dir.get_next()

	dir.list_dir_end()


func get_dice_type(id: String) -> DiceTypeResource:
	if dice_types.has(id):
		return dice_types[id]
	push_error("DiceRegistry: Unknown dice type: " + id)
	return _error_type


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


func create_instance(type_id: String) -> DiceInstance:
	var dice_type := get_dice_type(type_id)
	# get_dice_type은 실패 시 _error_type 반환
	# _error_type도 null이면 (error.tres 로드 실패) 치명적 오류
	assert(dice_type != null, "DiceRegistry: Both requested type and error type are null")
	return DiceInstance.new(dice_type)


## 에러 주사위인지 확인 (디버깅/UI용)
func is_error_dice(instance: DiceInstance) -> bool:
	return instance != null and instance.type == _error_type
