extends SubViewportContainer

const DICE_MODEL = preload("res://entities/dice/dice.glb")

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


func set_dice_instance(instance) -> void:
	dice_instance = instance
	# 주사위 타입에 따른 시각적 변경 (추후 확장 가능)
