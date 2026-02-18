extends Node
## 오너먼트 로더 — DiceRegistry 패턴
## Autoload: OrnamentTypes.ALL → OrnamentResource 파싱

var ornament_types: Dictionary[String, OrnamentResource] = {}


func _ready() -> void:
	_load_ornament_types()


func _load_ornament_types() -> void:
	for entry: Dictionary in OrnamentTypes.ALL:
		var ornament := _parse_ornament(entry)
		if ornament:
			ornament_types[ornament.id] = ornament


func _parse_ornament(data: Dictionary) -> OrnamentResource:
	var orn := OrnamentResource.new()
	orn.id = data["id"]
	orn.display_name = data["display_name"]
	orn.description = data["description"]

	# Color (Array[float] → Color)
	var c: Array = data.get("color", [1.0, 1.0, 1.0])
	orn.color = Color(c[0], c[1], c[2])

	# Shape (Vector2i 배열)
	var shape: Array[Vector2i] = []
	for v in data.get("shape", [Vector2i.ZERO]):
		shape.append(v)
	orn.shape = shape

	# Passive effects
	var passives: Array[Dictionary] = []
	for p in data.get("passive_effects", []):
		passives.append(p)
	orn.passive_effects = passives

	# Dice effects (DiceRegistry와 동일한 파싱)
	var dice_effects: Array[DiceEffectResource] = []
	for effect_data: Dictionary in data.get("dice_effects", []):
		var effect := _parse_dice_effect(effect_data)
		if effect:
			dice_effects.append(effect)
	orn.dice_effects = dice_effects

	return orn


func _parse_dice_effect(data: Dictionary) -> DiceEffectResource:
	var type_name: String = data.get("type", "")
	match type_name:
		"ModifierEffect":
			return ModifierEffect.new(data)
		"ActionEffect":
			return ActionEffect.new(data)
		_:
			assert(false, "OrnamentRegistry: Unknown effect type: %s" % type_name)
			return null


func get_ornament(id: String) -> OrnamentResource:
	if ornament_types.has(id):
		return ornament_types[id]
	push_error("OrnamentRegistry: Unknown ornament type: %s" % id)
	return null


func create_instance(id: String) -> OrnamentInstance:
	var ornament_type := get_ornament(id)
	if ornament_type == null:
		return null
	return OrnamentInstance.new(ornament_type)
