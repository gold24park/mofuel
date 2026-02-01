extends SubViewportContainer

const DICE_MODEL = preload("res://assets/dice/dice.glb")

@onready var viewport: SubViewport = $SubViewport
@onready var dice_holder: Node3D = $SubViewport/DiceHolder

var dice_model: Node3D = null
var rotation_speed: float = 1.0
var dice_instance = null


func _ready():
	_setup_dice()


func _process(delta: float):
	if dice_model:
		dice_model.rotate_y(rotation_speed * delta)


func _setup_dice():
	dice_model = DICE_MODEL.instantiate()
	dice_holder.add_child(dice_model)
	dice_model.position = Vector3.ZERO
	dice_model.rotation = Vector3.ZERO


func set_dice_instance(instance: DiceInstance) -> void:
	dice_instance = instance
	if dice_instance and dice_instance.type:
		dice_instance.type.apply_visual(_get_mesh_instance())


func _get_mesh_instance() -> MeshInstance3D:
	return _find_mesh_recursive(dice_model)


func _find_mesh_recursive(node: Node) -> MeshInstance3D:
	if node == null:
		return null
	for child in node.get_children():
		if child is MeshInstance3D:
			return child
		var found := _find_mesh_recursive(child)
		if found:
			return found
	return null
