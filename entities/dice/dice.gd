extends RigidBody3D

@export var dice_index: int = 0

@onready var raycasts: Array = $Raycasts.get_children()
@onready var dice_mesh: Node3D = $dice

const OUTLINE_SHADER = preload("res://entities/dice/outline.gdshader")

enum State { IDLE, ROLLING, MOVING_TO_DISPLAY }

const ROLL_TIMEOUT: float = 5.0  # 최대 굴리기 시간 (초)

var current_state: State = State.IDLE
var roll_strength = 20
var is_selected: bool = false
var dice_instance = null  # DiceInstance
var display_position: Vector3 = Vector3.ZERO
var roll_start_position: Vector3 = Vector3.ZERO
var final_value: int = 0
var final_rotation: Basis = Basis.IDENTITY  # 굴린 후의 회전 저장
var outline_mesh: MeshInstance3D = null
var roll_start_time: float = 0.0

# Breathing animation
var is_breathing: bool = false
var breath_time: float = 0.0
const BREATH_SPEED: float = 4.0  # 숨쉬기 속도
const BREATH_SCALE_MIN: float = 1.0
const BREATH_SCALE_MAX: float = 1.15

signal roll_finished(dice_index: int, value: int)
signal dice_clicked(dice_index: int)


func _ready():
	input_ray_pickable = true
	_create_outline()


func _process(delta: float) -> void:
	# 굴리기 타임아웃 체크
	if current_state == State.ROLLING:
		if Time.get_ticks_msec() / 1000.0 - roll_start_time > ROLL_TIMEOUT:
			_force_settle()
			return

	if current_state == State.MOVING_TO_DISPLAY:
		var target_y = 3.0 if is_selected else 1.0
		var target_pos = Vector3(display_position.x, target_y, display_position.z)

		global_position = global_position.lerp(target_pos, delta * 10.0)

		# 반듯한 회전으로 정렬
		transform.basis = transform.basis.slerp(final_rotation, delta * 10.0)

		if global_position.distance_to(target_pos) < 0.05:
			global_position = target_pos
			transform.basis = final_rotation
			# 입력을 위해 충돌 활성화 (Layer 4: 정렬된 주사위, 입력 전용)
			# 굴리는 주사위(Layer 2)와 충돌하지 않음
			collision_layer = 4
			collision_mask = 0
			current_state = State.IDLE

	# 숨쉬기 애니메이션
	if is_breathing:
		breath_time += delta * BREATH_SPEED
		var scale_factor = lerpf(BREATH_SCALE_MIN, BREATH_SCALE_MAX, (sin(breath_time) + 1.0) / 2.0)
		dice_mesh.scale = Vector3.ONE * scale_factor
	elif dice_mesh.scale != Vector3.ONE:
		dice_mesh.scale = dice_mesh.scale.lerp(Vector3.ONE, delta * 10.0)


# 주사위 모델 기준 반듯한 회전 계산
# 기본 방향(Identity): 1이 위, 6이 아래
func _get_upright_rotation(top_face: int) -> Basis:
	match top_face:
		6: return Basis(Vector3.RIGHT, PI)           # X축 180° 회전
		5: return Basis(Vector3.RIGHT, -PI / 2)      # X축 -90° 회전
		4: return Basis(Vector3.FORWARD, -PI / 2)    # +X를 위로 (-Z축 기준 -90°)
		3: return Basis(Vector3.FORWARD, PI / 2)     # -X를 위로 (-Z축 기준 +90°)
		2: return Basis(Vector3.RIGHT, PI / 2)       # X축 90° 회전
		1, _: return Basis.IDENTITY                   # 기본 방향


func set_dice_instance(instance) -> void:
	dice_instance = instance


func setup(display_pos: Vector3, roll_pos: Vector3) -> void:
	display_position = display_pos
	roll_start_position = roll_pos
	# 초기 위치는 디스플레이 위치
	global_position = display_pos
	freeze = true
	# 초기 상태: 입력 전용 레이어
	collision_layer = 4
	collision_mask = 0
	final_value = 0  # 아직 굴리지 않음
	final_rotation = Basis.IDENTITY
	transform.basis = Basis.IDENTITY
	current_state = State.IDLE


func set_display_position(new_pos: Vector3) -> void:
	display_position = new_pos
	# IDLE 상태면 바로 이동 시작
	if current_state == State.IDLE:
		current_state = State.MOVING_TO_DISPLAY


func roll_dice() -> void:
	if current_state != State.ROLLING:
		is_selected = false
		if outline_mesh:
			outline_mesh.visible = false
		_roll()


func roll_dice_with_direction(direction: Vector2, strength: float) -> void:
	if current_state != State.ROLLING:
		is_selected = false
		if outline_mesh:
			outline_mesh.visible = false
		_roll_directed(direction, strength)


func _roll_directed(direction: Vector2, strength: float):
	current_state = State.ROLLING
	roll_start_time = Time.get_ticks_msec() / 1000.0

	# 롤 시작 위치로 이동
	global_position = roll_start_position

	# 물리 및 충돌 활성화 (Layer 2: 굴리는 주사위)
	# Mask: Layer 1(바닥) + Layer 2(다른 굴리는 주사위) + Layer 8(벽)
	collision_layer = 2
	collision_mask = 1 | 2 | 8
	sleeping = false
	freeze = false
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO

	# Random rotation
	transform.basis = Basis(Vector3.RIGHT, randf_range(0, 2 * PI)) * transform.basis
	transform.basis = Basis(Vector3.UP, randf_range(0, 2 * PI)) * transform.basis
	transform.basis = Basis(Vector3.FORWARD, randf_range(0, 2 * PI)) * transform.basis

	# 스와이프 방향 → 3D 던지는 방향
	# Screen Y는 아래로 증가하므로, 위로 스와이프하면 direction.y < 0
	# Godot 3D에서 -Z가 앞쪽이므로 direction.y를 그대로 사용
	var throw_vector = Vector3(direction.x, 0, direction.y).normalized()

	# 약간의 랜덤성 추가 (주사위마다 조금씩 다르게)
	throw_vector.x += randf_range(-0.2, 0.2)
	throw_vector.z += randf_range(-0.2, 0.2)
	throw_vector = throw_vector.normalized()

	angular_velocity = throw_vector * strength / 2
	apply_central_impulse(throw_vector * strength)


func _roll():
	current_state = State.ROLLING
	roll_start_time = Time.get_ticks_msec() / 1000.0

	# 롤 시작 위치로 이동
	global_position = roll_start_position

	# 물리 및 충돌 활성화 (Layer 2: 굴리는 주사위)
	# Mask: Layer 1(바닥) + Layer 2(다른 굴리는 주사위) + Layer 8(벽)
	collision_layer = 2
	collision_mask = 1 | 2 | 8
	sleeping = false
	freeze = false
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


func _on_sleeping_state_changed() -> void:
	if not sleeping:
		return
	if current_state != State.ROLLING:
		return

	# 상태를 먼저 변경하여 중복 호출 방지
	current_state = State.MOVING_TO_DISPLAY

	for raycast in raycasts:
		var rc = raycast as RayCast3D
		rc.force_raycast_update()
		if rc.is_colliding():
			# opposite_side는 이 raycast가 충돌할 때 위를 향하는 면의 숫자
			var physical_value = raycast.opposite_side

			# DiceInstance를 통해 효과 적용
			final_value = physical_value
			print("DEBUG dice[%d]: raycast=%s, opposite_side=%d, physical=%d" % [dice_index, raycast.name, raycast.opposite_side, physical_value])
			if dice_instance:
				final_value = dice_instance.roll(physical_value)
				print("DEBUG dice[%d]: current_value after roll=%d" % [dice_index, dice_instance.current_value])

			# 반듯한 회전 계산 (해당 면이 위로 오도록)
			final_rotation = _get_upright_rotation(physical_value)

			# 물리 정지 및 충돌 비활성화
			freeze = true
			collision_layer = 0
			collision_mask = 0
			roll_finished.emit(dice_index, final_value)
			return

	# 정확한 면에 안착 실패 - 다시 굴리기
	current_state = State.ROLLING
	call_deferred("_roll")


func _force_settle() -> void:
	# 타임아웃으로 강제 정착
	print("DEBUG dice[%d]: Force settling due to timeout" % dice_index)

	current_state = State.MOVING_TO_DISPLAY

	# 물리 정지
	freeze = true
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	collision_layer = 0
	collision_mask = 0

	# 현재 상태에서 윗면 감지 시도
	var physical_value = 1
	for raycast in raycasts:
		var rc = raycast as RayCast3D
		rc.force_raycast_update()
		if rc.is_colliding():
			physical_value = raycast.opposite_side
			break

	# 감지 실패 시 랜덤 값
	if physical_value == 0:
		physical_value = randi_range(1, 6)

	final_value = physical_value
	if dice_instance:
		final_value = dice_instance.roll(physical_value)

	final_rotation = _get_upright_rotation(physical_value)
	roll_finished.emit(dice_index, final_value)


# 클래스 레벨 변수 - 모든 주사위가 공유
static var _click_frame: int = -1
static var _closest_dice: RigidBody3D = null
static var _closest_distance: float = INF

func _input_event(camera: Camera3D, event: InputEvent, event_position: Vector3, _normal: Vector3, _shape_idx: int) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if current_state == State.IDLE:
				var current_frame = Engine.get_process_frames()
				var click_distance = camera.global_position.distance_to(event_position)

				# 새로운 프레임이면 초기화
				if current_frame != _click_frame:
					_click_frame = current_frame
					_closest_dice = null
					_closest_distance = INF
					# 프레임 끝에 가장 가까운 주사위 클릭 처리
					_schedule_click_processing.call_deferred()

				# 더 가까운 주사위면 업데이트
				if click_distance < _closest_distance:
					_closest_distance = click_distance
					_closest_dice = self


static func _schedule_click_processing() -> void:
	if _closest_dice and _closest_dice.current_state == State.IDLE:
		_closest_dice.dice_clicked.emit(_closest_dice.dice_index)


func set_selected(selected: bool) -> void:
	is_selected = selected
	# 윤곽선 표시
	if outline_mesh:
		outline_mesh.visible = selected
	# 선택 상태 변경 시 높이 조정을 위해 이동 시작
	if current_state == State.IDLE:
		current_state = State.MOVING_TO_DISPLAY


func start_breathing() -> void:
	is_breathing = true
	breath_time = 0.0


func stop_breathing() -> void:
	is_breathing = false


func _create_outline() -> void:
	# dice 노드에서 MeshInstance3D 찾기
	var mesh_instance: MeshInstance3D = null
	for child in dice_mesh.get_children():
		if child is MeshInstance3D:
			mesh_instance = child
			break

	if mesh_instance == null or mesh_instance.mesh == null:
		return

	# 윤곽선용 메쉬 생성
	outline_mesh = MeshInstance3D.new()
	outline_mesh.mesh = mesh_instance.mesh

	# 셰이더 머티리얼 생성
	var material = ShaderMaterial.new()
	material.shader = OUTLINE_SHADER
	material.set_shader_parameter("outline_color", Color(1.0, 0.8, 0.0, 1.0))  # 노란색
	material.set_shader_parameter("outline_width", 0.1)

	outline_mesh.material_override = material
	outline_mesh.visible = false

	dice_mesh.add_child(outline_mesh)
