extends Node

var dice_types: Dictionary = {} # id -> DiceTypeResource
var _error_type: DiceTypeResource = null


func _ready():
	_load_dice_types()
	_error_type = dice_types.get("_error")


func _load_dice_types():
	for entry: Dictionary in DiceTypes.ALL:
		var dice_type := _parse_dice_type(entry)
		if dice_type:
			dice_types[dice_type.id] = dice_type


func _parse_dice_type(data: Dictionary) -> DiceTypeResource:
	var dt := DiceTypeResource.new()
	dt.id = data["id"]
	dt.display_name = data["display_name"]
	dt.description = data["description"]

	# Groups
	var groups_data: Array = data.get("groups", [])
	var groups: Array[String] = []
	for g in groups_data:
		groups.append(g)
	dt.groups = groups

	# Face values (면 매핑, 기본값: identity)
	if data.has("face_values"):
		dt.face_values = _to_array_int(data["face_values"])

	# Texture (경로 문자열 → load)
	var tex_path: String = data.get("texture", "res://assets/dice/uv/dice_uv_error.png")
	dt.texture = load(tex_path)

	# Material (경로 문자열 → load)
	var mat_path: String = data.get("material", "")
	if mat_path != "":
		dt.material = load(mat_path)

	# Effects (enum 값이 이미 들어있으므로 직접 전달)
	var effects: Array[DiceEffectResource] = []
	for effect_data: Dictionary in data.get("effects", []):
		var effect := _parse_dice_effect(effect_data)
		if effect:
			effects.append(effect)
	dt.effects = effects

	return dt


func _parse_dice_effect(data: Dictionary) -> DiceEffectResource:
	var type_name: String = data.get("type", "")
	match type_name:
		"ModifierEffect":
			return ModifierEffect.new({
				"target": data["target"],
				"modify_target": data["modify_target"],
				"delta": float(data["delta"]),
				"effect_name": data.get("effect_name", ""),
				"comparisons": data.get("comparisons", []),
				"anim": data.get("anim", ""),
				"sound": data.get("sound", ""),
			})
		"ActionEffect":
			return ActionEffect.new({
				"target": data["target"],
				"action": data["action"],
				"delta": int(data.get("delta", 0)),
				"params": data.get("params", {}),
				"effect_name": data.get("effect_name", ""),
				"comparisons": data.get("comparisons", []),
				"anim": data.get("anim", ""),
				"sound": data.get("sound", ""),
			})
		_:
			push_warning("DiceRegistry: Unknown effect type: " + type_name)
			return null


## const Array → Array[int] 변환 (const 배열은 untyped이므로 필요)
func _to_array_int(raw: Array) -> Array[int]:
	var result: Array[int] = []
	for v in raw:
		result.append(int(v))
	return result


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
	assert(dice_type != null, "DiceRegistry: Both requested type and error type are null")
	return DiceInstance.new(dice_type)


func is_error_dice(instance: DiceInstance) -> bool:
	return instance != null and instance.type == _error_type
