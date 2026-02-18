extends RigidBody3D

@export var dice_index: int = 0
@onready var dice_mesh: Node3D = $dice

enum State {
	IDLE,
	ROLLING,
	MOVING_TO_DISPLAY
}

const ROLL_TIMEOUT: float = 5.0 # 최대 굴리기 시간 (초)

## 물리 스케일링 기본값 (_ready에서 .tscn 초기값 캡처)
var _base_gravity_scale: float
var _base_linear_damp: float
var _base_angular_damp: float
var _physics_scale: float = 1.0

var current_state: State = State.IDLE
var is_selected: bool = false
var dice_instance: DiceInstance = null
var display_position: Vector3 = Vector3.ZERO
var final_value: int = 0
var final_rotation: Basis = Basis.IDENTITY # 굴린 후의 회전 저장
var outline_mesh: MeshInstance3D = null
var _spotlight: OmniLight3D = null
var roll_start_time: float = 0.0
var _used_burst_mask: bool = false # 버스트 마스크 사용 여부

# Breathing animation
var is_breathing: bool = false
var breath_time: float = 0.0
const BREATH_SPEED: float = 4.0 # 숨쉬기 속도
const BREATH_SCALE_MIN: float = 1.0
const BREATH_SCALE_MAX: float = 1.15

signal roll_finished(dice_index: int, value: int)
signal dice_clicked(dice_index: int)
signal dice_hovered(dice_index: int)
signal dice_unhovered(dice_index: int)


func _ready():
	_base_gravity_scale = gravity_scale
	_base_linear_damp = linear_damp
	_base_angular_damp = angular_damp
	input_ray_pickable = true
	_create_outline()
	_create_spotlight()
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)


func _process(delta: float) -> void:
	match current_state:
		State.ROLLING:
			_process_rolling()
		State.MOVING_TO_DISPLAY:
			_process_moving_to_display(delta)

	_process_breathing(delta)


func _process_rolling() -> void:
	var elapsed := Time.get_ticks_msec() / 1000.0 - roll_start_time

	if elapsed > ROLL_TIMEOUT:
		_force_settle()

	# 0.3초 후 주사위끼리 충돌 활성화 (버스트 시에만)
	if _used_burst_mask and elapsed > 0.3:
		collision_mask = CollisionLayers.ROLLING_MASK
		_used_burst_mask = false

	# 스케일 펀치 복구 (버스트 후)
	if dice_mesh.scale != Vector3.ONE:
		dice_mesh.scale = dice_mesh.scale.lerp(Vector3.ONE, 0.15)


func _process_moving_to_display(delta: float) -> void:
	var target_y = 3.0 if is_selected else 1.0
	var target_pos = Vector3(display_position.x, target_y, display_position.z)

	global_position = global_position.lerp(target_pos, delta * 10.0)

	# 반듯한 회전으로 정렬
	transform.basis = transform.basis.slerp(final_rotation, delta * 10.0)

	if global_position.distance_to(target_pos) < 0.05:
		global_position = target_pos
		transform.basis = final_rotation
		collision_layer = CollisionLayers.ALIGNED_DICE
		collision_mask = 0
		current_state = State.IDLE


func _process_breathing(delta: float) -> void:
	if is_breathing:
		breath_time += delta * BREATH_SPEED
		var scale_factor = lerpf(BREATH_SCALE_MIN, BREATH_SCALE_MAX, (sin(breath_time) + 1.0) / 2.0)
		dice_mesh.scale = Vector3.ONE * scale_factor
	elif dice_mesh.scale != Vector3.ONE:
		dice_mesh.scale = dice_mesh.scale.lerp(Vector3.ONE, delta * 10.0)


# 주사위 모델 기준 반듯한 회전 계산
# 기본 방향(Identity): 1이 위(+Y), 6이 아래(-Y)
func _get_upright_rotation(top_face: int) -> Basis:
	match top_face:
		6: return Basis(Vector3.RIGHT, PI) # -Y → +Y (X축 180°)
		2: return Basis(Vector3.RIGHT, -PI / 2) # +Z → +Y (X축 -90°)
		5: return Basis(Vector3.RIGHT, PI / 2) # -Z → +Y (X축 90°)
		3: return Basis(Vector3.FORWARD, -PI / 2) # +X → +Y (Z축 -90°)
		4: return Basis(Vector3.FORWARD, PI / 2) # -X → +Y (Z축 90°)
		1, _: return Basis.IDENTITY # 기본 방향


# 현재 회전에서 윗면 계산 (회전 행렬 기반)
func _get_top_face_from_rotation() -> int:
	# 각 면의 로컬 법선 벡터 (모델 기준)
	const FACE_NORMALS := {
		1: Vector3.UP, # +Y
		6: Vector3.DOWN, # -Y
		2: Vector3.BACK, # +Z
		5: Vector3.FORWARD, # -Z
		3: Vector3.RIGHT, # +X
		4: Vector3.LEFT, # -X
	}

	var best_face := 1
	var best_dot := -INF

	for face in FACE_NORMALS:
		var world_normal: Vector3 = transform.basis * FACE_NORMALS[face]
		var dot: float = world_normal.dot(Vector3.UP)
		if dot > best_dot:
			best_dot = dot
			best_face = face

	return best_face


func set_dice_instance(instance: DiceInstance) -> void:
	dice_instance = instance
	_apply_visual()


func setup(display_pos: Vector3) -> void:
	display_position = display_pos
	# 초기 위치는 디스플레이 위치
	global_position = display_pos
	freeze = true
	collision_layer = CollisionLayers.ALIGNED_DICE
	collision_mask = 0
	final_value = 0 # 아직 굴리지 않음
	final_rotation = Basis.IDENTITY
	transform.basis = Basis.IDENTITY
	current_state = State.IDLE


## 물리 시뮬레이션 속도 스케일 설정 (UI에 영향 없음)
## s=2.0이면 같은 궤적을 절반 시간에 완료
func set_physics_scale(s: float) -> void:
	_physics_scale = s
	gravity_scale = _base_gravity_scale * s * s
	linear_damp = _base_linear_damp * s
	angular_damp = _base_angular_damp * s


func set_display_position(new_pos: Vector3) -> void:
	display_position = new_pos
	# IDLE 상태면 바로 이동 시작
	if current_state == State.IDLE:
		current_state = State.MOVING_TO_DISPLAY


#region Radial Burst
func roll_dice_radial_burst(center: Vector3, direction: Vector3, strength: float) -> void:
	if current_state == State.ROLLING:
		return

	is_selected = false
	if outline_mesh:
		outline_mesh.visible = false
	set_spotlight(false)

	# 즉시 중앙에 위치
	current_state = State.ROLLING
	roll_start_time = Time.get_ticks_msec() / 1000.0
	global_position = center

	# 랜덤 회전
	transform.basis = Basis(Vector3.RIGHT, randf_range(0, TAU)) * transform.basis
	transform.basis = Basis(Vector3.UP, randf_range(0, TAU)) * transform.basis
	transform.basis = Basis(Vector3.FORWARD, randf_range(0, TAU)) * transform.basis

	# 물리 활성화 (버스트 중에는 주사위끼리 충돌 안 함)
	collision_layer = CollisionLayers.ROLLING_DICE
	collision_mask = CollisionLayers.BURST_MASK
	_used_burst_mask = true
	sleeping = false
	freeze = false
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO

	# 스케일 펀치 (팡! 효과)
	dice_mesh.scale = Vector3.ONE * 1.5

	# 버스트 임펄스 - 높은 곳에서 떨어뜨리면서 퍼짐
	var s := _physics_scale
	var dir: Vector3 = direction.normalized()
	var horizontal_strength: float = strength * 0.4
	var downward_speed: float = strength * 0.7

	linear_velocity = Vector3(0, -downward_speed * s, 0) # 아래로 떨어지는 초기 속도

	var impulse := dir * horizontal_strength
	impulse += Vector3(randf_range(-1, 1), 0, randf_range(-1, 1))
	apply_central_impulse(impulse * s)

	# 강한 회전
	var spin_axis := dir.cross(Vector3.UP)
	if spin_axis.length() < 0.1:
		spin_axis = Vector3.RIGHT
	angular_velocity = (spin_axis.normalized() * strength * 0.7 + Vector3(
		randf_range(-8, 8),
		randf_range(-8, 8),
		randf_range(-8, 8)
	)) * s
#endregion


#region Spin In Place (Reroll)
## Tween 기반 제자리 스핀 — 물리 없이 빠르게 회전 후 결과 면에 정착
func spin_in_place() -> void:
	if current_state == State.ROLLING:
		return

	is_selected = false
	if outline_mesh:
		outline_mesh.visible = false
	set_spotlight(false)

	current_state = State.ROLLING
	roll_start_time = Time.get_ticks_msec() / 1000.0

	# 랜덤 결과 면 (1~6)
	var target_face := randi_range(1, 6)
	final_value = target_face
	if dice_instance:
		final_value = dice_instance.roll(target_face)

	final_rotation = _get_upright_rotation(target_face)
	var target_euler := final_rotation.get_euler()

	# 빠르게 시작 → 자연 감속하며 목표 면에 정착 (1.5~2바퀴, 0.55초)
	var spin_target := target_euler + Vector3(
		randf_range(1.5, 2.0) * TAU * (1.0 if randf() > 0.5 else -1.0),
		randf_range(1.0, 1.5) * TAU * (1.0 if randf() > 0.5 else -1.0),
		randf_range(1.0, 1.5) * TAU * (1.0 if randf() > 0.5 else -1.0)
	)

	var tween := create_tween()
	tween.tween_property(self, "rotation", spin_target, 0.55) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)

	await tween.finished

	# 최종 정렬
	transform.basis = final_rotation

	# Phase 3: 탕! 스케일 펀치 + 기울기 (선택 펀치와 동일한 쫀득한 느낌)
	var tilt := Vector3(
		randf_range(-0.2, 0.2),
		0,
		randf_range(-0.2, 0.2)
	)
	var slam := create_tween()
	# 팽창 + 기울기 (동시)
	slam.tween_property(dice_mesh, "scale", Vector3.ONE * 1.15, 0.06) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	slam.parallel().tween_property(dice_mesh, "rotation", tilt, 0.06) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	# 수축
	slam.tween_property(dice_mesh, "scale", Vector3.ONE * 0.92, 0.06) \
		.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	# 정착 + 기울기 복귀 (동시)
	slam.tween_property(dice_mesh, "scale", Vector3.ONE, 0.12) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
	slam.parallel().tween_property(dice_mesh, "rotation", Vector3.ZERO, 0.15) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	await slam.finished
	dice_mesh.rotation = Vector3.ZERO

	# 결과 확인 대기
	await get_tree().create_timer(0.5).timeout

	collision_layer = CollisionLayers.ALIGNED_DICE
	collision_mask = 0
	current_state = State.IDLE
	roll_finished.emit(dice_index, final_value)
#endregion


func _on_sleeping_state_changed() -> void:
	if not sleeping or current_state != State.ROLLING:
		return

	# 상태를 먼저 변경하여 중복 호출 방지
	current_state = State.MOVING_TO_DISPLAY
	set_physics_scale(1.0)

	# 회전 행렬에서 윗면 계산
	var physical_value := _get_top_face_from_rotation()

	# DiceInstance를 통해 효과 적용
	final_value = physical_value
	if dice_instance:
		final_value = dice_instance.roll(physical_value)

	# 반듯한 회전 계산 (해당 면이 위로 오도록)
	final_rotation = _get_upright_rotation(physical_value)

	# 물리 정지 및 충돌 비활성화
	freeze = true
	collision_layer = 0
	collision_mask = 0
	roll_finished.emit(dice_index, final_value)


func _force_settle() -> void:
	current_state = State.MOVING_TO_DISPLAY
	set_physics_scale(1.0)

	# 물리 정지
	freeze = true
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	collision_layer = 0
	collision_mask = 0

	# 회전 행렬에서 윗면 계산
	var physical_value := _get_top_face_from_rotation()

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
	if is_selected == selected:
		return
	is_selected = selected
	if current_state == State.IDLE:
		current_state = State.MOVING_TO_DISPLAY
	_punch_scale()


## 윤곽선만 표시/숨김 (높이 변경 없음, quick score 호버용)
func set_highlighted(highlighted: bool) -> void:
	if outline_mesh:
		outline_mesh.visible = highlighted


func set_spotlight(enabled: bool) -> void:
	if _spotlight:
		_spotlight.visible = enabled
		if enabled:
			# 주사위 회전 역보정 — 월드 기준 항상 위쪽에 위치
			_spotlight.position = transform.basis.inverse() * Vector3(0, 2.5, 0)


## 선택/해제 시 쫀득한 스케일 펀치 + 기울기 (발라트로 스타일)
func _punch_scale() -> void:
	var was_breathing := is_breathing
	is_breathing = false

	# 랜덤 기울기 방향
	var tilt := Vector3(
		randf_range(-0.2, 0.2),
		0,
		randf_range(-0.2, 0.2)
	)

	var tween := create_tween()
	# 팽창 + 기울기 (동시)
	tween.tween_property(dice_mesh, "scale", Vector3.ONE * 1.15, 0.06) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tween.parallel().tween_property(dice_mesh, "rotation", tilt, 0.06) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	# 수축
	tween.tween_property(dice_mesh, "scale", Vector3.ONE * 0.92, 0.06) \
		.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	# 정착 + 기울기 복귀 (동시)
	tween.tween_property(dice_mesh, "scale", Vector3.ONE, 0.12) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
	tween.parallel().tween_property(dice_mesh, "rotation", Vector3.ZERO, 0.15) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.finished.connect(func(): is_breathing = was_breathing)


func start_breathing() -> void:
	is_breathing = true
	breath_time = 0.0


func stop_breathing() -> void:
	is_breathing = false


#region Effect Animations
## 효과 애니메이션 재생 (await 가능, breathing과 충돌 방지)
func play_effect_anim(anim_type: String) -> void:
	# breathing 일시 정지 (둘 다 dice_mesh.scale을 건드리므로)
	var was_breathing := is_breathing
	is_breathing = false
	dice_mesh.scale = Vector3.ONE

	match anim_type:
		"bounce":
			await _anim_bounce()
		"scale":
			await _anim_scale()
		"flash":
			await _anim_flash()
		"shake":
			await _anim_shake()
		_:
			# 알 수 없는 타입이면 기본 bounce
			await _anim_bounce()

	# breathing 복구
	is_breathing = was_breathing


func _anim_bounce() -> void:
	var tween := create_tween()
	tween.tween_property(dice_mesh, "scale", Vector3.ONE * 1.3, 0.08) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(dice_mesh, "scale", Vector3.ONE, 0.15) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
	await tween.finished


func _anim_scale() -> void:
	var tween := create_tween()
	tween.tween_property(dice_mesh, "scale", Vector3.ONE * 1.5, 0.12) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(dice_mesh, "scale", Vector3.ONE, 0.18) \
		.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	await tween.finished


func _anim_flash() -> void:
	var tween := create_tween()
	tween.tween_property(dice_mesh, "scale", Vector3.ONE * 0.8, 0.04)
	tween.tween_property(dice_mesh, "scale", Vector3.ONE * 1.2, 0.04)
	tween.tween_property(dice_mesh, "scale", Vector3.ONE * 0.9, 0.04)
	tween.tween_property(dice_mesh, "scale", Vector3.ONE, 0.08)
	await tween.finished


func _anim_shake() -> void:
	var original_pos := dice_mesh.position
	var tween := create_tween()
	for i in range(4):
		var offset := Vector3(randf_range(-0.15, 0.15), 0, randf_range(-0.15, 0.15))
		tween.tween_property(dice_mesh, "position", original_pos + offset, 0.03)
	tween.tween_property(dice_mesh, "position", original_pos, 0.04)
	await tween.finished
#endregion


func _get_mesh_instance() -> MeshInstance3D:
	return _find_mesh_recursive(dice_mesh)


func _find_mesh_recursive(node: Node) -> MeshInstance3D:
	for child in node.get_children():
		if child is MeshInstance3D:
			return child
		var found := _find_mesh_recursive(child)
		if found:
			return found
	return null


func _apply_visual() -> void:
	if dice_instance == null or dice_instance.type == null:
		return
	dice_instance.type.apply_visual(_get_mesh_instance())


func _create_outline() -> void:
	var mesh_instance := _get_mesh_instance()
	if mesh_instance == null or mesh_instance.mesh == null:
		return

	# 윤곽선용 메쉬 생성 - 스케일 방식으로 변경
	outline_mesh = MeshInstance3D.new()
	outline_mesh.mesh = mesh_instance.mesh

	# 간단한 단색 머티리얼 (셰이더 대신)
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(1.0, 0.8, 0.0, 1.0) # 노란색
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.cull_mode = BaseMaterial3D.CULL_FRONT # 뒷면만 렌더링

	outline_mesh.material_override = material
	outline_mesh.visible = false

	# 메쉬와 같은 부모에 추가
	mesh_instance.get_parent().add_child(outline_mesh)
	outline_mesh.transform = mesh_instance.transform
	outline_mesh.scale = Vector3(1.1, 1.1, 1.1)


func _create_spotlight() -> void:
	_spotlight = OmniLight3D.new()
	_spotlight.light_energy = 10.0
	_spotlight.omni_range = 2.0
	_spotlight.omni_attenuation = 3.0
	_spotlight.light_color = Color(1.0, 0.95, 0.85) # warm white
	_spotlight.shadow_enabled = false
	_spotlight.visible = false
	_spotlight.position = Vector3(0, 2.5, 0)
	add_child(_spotlight)


func _on_mouse_entered() -> void:
	if current_state == State.IDLE:
		dice_hovered.emit(dice_index)


func _on_mouse_exited() -> void:
	dice_unhovered.emit(dice_index)
