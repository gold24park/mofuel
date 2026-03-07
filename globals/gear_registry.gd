extends Node
## 기어 로더 — DiceRegistry 패턴
## Autoload: GearTypes.ALL → GearResource 파싱

var gear_types: Dictionary[String, GearResource] = {}


func _ready() -> void:
	_load_gear_types()


func _load_gear_types() -> void:
	for entry: Dictionary in GearTypes.ALL:
		var gear := _parse_gear(entry)
		if gear:
			gear_types[gear.id] = gear


func _parse_gear(data: Dictionary) -> GearResource:
	var g := GearResource.new()
	g.id = data["id"]
	g.display_name = data["display_name"]
	g.description = data["description"]

	# Color (Array[float] → Color)
	var c: Array = data.get("color", [1.0, 1.0, 1.0])
	g.color = Color(c[0], c[1], c[2])

	# Shape (Vector2i 배열)
	var shape: Array[Vector2i] = []
	for v in data.get("shape", [Vector2i.ZERO]):
		shape.append(v)
	g.shape = shape

	# Passive effects
	var passives: Array[Dictionary] = []
	for p in data.get("passive_effects", []):
		passives.append(p)
	g.passive_effects = passives

	# Dice effects (공유 팩토리 사용)
	var dice_effects: Array[DiceEffectResource] = []
	for effect_data: Dictionary in data.get("dice_effects", []):
		var effect := DiceEffectResource.create_from_data(effect_data)
		if effect:
			dice_effects.append(effect)
	g.dice_effects = dice_effects

	return g


func get_gear(id: String) -> GearResource:
	if gear_types.has(id):
		return gear_types[id]
	push_error("GearRegistry: Unknown gear type: %s" % id)
	return null


func create_instance(id: String) -> GearInstance:
	var gear_type := get_gear(id)
	if gear_type == null:
		return null
	return GearInstance.new(gear_type)
