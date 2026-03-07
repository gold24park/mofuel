extends Camera2D

## 서브픽셀 카메라 — 픽셀 스냅 + 셰이더 보정으로 부드러운 스크롤

@export var follow_speed: float = 3.0

var _actual_pos: Vector2

@onready var _player: Player = %Player
@onready var _viewport_material: ShaderMaterial = get_viewport().get_parent().material


func _ready() -> void:
	_actual_pos = _player.global_position


func _physics_process(delta: float) -> void:
	_actual_pos = _actual_pos.lerp(_player.global_position, delta * follow_speed)
	global_position = _actual_pos.round()
	var subpixel_offset := _actual_pos.round() - _actual_pos
	_viewport_material.set_shader_parameter("cam_offset", subpixel_offset)
