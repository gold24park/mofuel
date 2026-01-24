extends RigidBody3D

@onready var raycasts: Array = $Raycasts.get_children()

var start_pos: Vector3
var roll_strength = 30
var is_rolling: bool = false

signal roll_finished(value: int)

func _ready():
	start_pos = global_position
	
func _input(event: InputEvent):
	if event.is_action_pressed("ui_accept") && !is_rolling:
		_roll()
		
func _roll():
	# reset state
	sleeping = false
	freeze = false
	transform.origin = start_pos
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	
	# Random rotation
	transform.basis = Basis(Vector3.RIGHT, randf_range(0, 2 * PI)) * transform.basis
	transform.basis = Basis(Vector3.UP, randf_range(0, 2 * PI)) * transform.basis
	transform.basis = Basis(Vector3.FORWARD, randf_range(0, 2 * PI)) * transform.basis
	
	# Random throw impulse
	var throw_vector = Vector3(randf_range(-1, 1), 0, randf_range(-1, 1)).normalized()
	angular_velocity = throw_vector * roll_strength / 2
	apply_central_impulse(throw_vector * roll_strength)
	is_rolling = true
	
	


func _on_sleeping_state_changed() -> void:
	if sleeping && is_rolling:
		for raycast in raycasts:
			var rc = raycast as RayCast3D
			rc.force_raycast_update()
			if rc.is_colliding():
				roll_finished.emit(raycast.opposite_side)
				is_rolling = false
				return

		# 정확한 면에 안착 실패 - 다음 프레임에 다시 굴리기
		call_deferred("_roll")
