extends Node

var dice_types: Dictionary[String, DiceTypeResource] = {}
var _error_type: DiceTypeResource = null


func _ready() -> void:
	_load_dice_types()
	_error_type = dice_types.get("_error")


func _load_dice_types() -> void:
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
	var groups: Array[String] = []
	for g in data.get("groups", []):
		groups.append(g)
	dt.groups = groups

	# Face values (면 매핑, 기본값: identity)
	match data:
		{"face_values": var fv, ..}:
			var face_values: Array[int] = []
			for v in fv:
				face_values.append(int(v))
			dt.face_values = face_values

	# Texture (경로 문자열 → load)
	var tex_path: String = data.get("texture", "res://assets/dice/uv/dice_uv_error.png")
	dt.texture = load(tex_path)

	# Material (경로 문자열 → load)
	match data:
		{"material": var mat_path, ..} when mat_path != "":
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
			return ModifierEffect.new(data)
		"ActionEffect":
			return ActionEffect.new(data)
		_:
			assert(false, "DiceRegistry: Unknown effect type: %s" % type_name)
			return null


func get_dice_type(id: String) -> DiceTypeResource:
	if dice_types.has(id):
		return dice_types[id]
	push_error("DiceRegistry: Unknown dice type: %s" % id)
	return _error_type


func create_instance(type_id: String) -> DiceInstance:
	var dice_type := get_dice_type(type_id)
	assert(dice_type != null, "DiceRegistry: Both requested type and error type are null")
	return DiceInstance.new(dice_type)
