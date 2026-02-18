class_name JuiceFX
extends Node

## 게임 쥬스 컴포넌트 — 카메라 쉐이크, 히트 프리즈, 스크린 플래시, 파티클, 플로팅 텍스트

var _camera: Camera3D
var _world_3d: Node3D

# Camera shake
var _shake_strength: float = 0.0
var _shake_decay: float = 8.0
var _camera_base_pos: Vector3

# Screen flash
var _flash_rect: ColorRect

# Hit freeze (wall-clock 기반 — Engine.time_scale 영향 없음)
var _freeze_end_msec: int = 0


func setup(cam: Camera3D, world: Node3D) -> void:
	_camera = cam
	_camera_base_pos = cam.global_position
	_world_3d = world
	_create_flash_overlay()


func _process(delta: float) -> void:
	_update_shake(delta)
	_update_freeze()


#region Camera Shake
func shake(strength: float = 0.5, decay: float = 8.0) -> void:
	_shake_strength = maxf(_shake_strength, strength)
	_shake_decay = decay


func _update_shake(delta: float) -> void:
	if _camera == null:
		return
	if _shake_strength > 0.01:
		_camera.global_position = _camera_base_pos + Vector3(
			randf_range(-1, 1) * _shake_strength, 0,
			randf_range(-1, 1) * _shake_strength
		)
		_shake_strength = lerpf(_shake_strength, 0.0, _shake_decay * delta)
	elif _camera.global_position != _camera_base_pos:
		_camera.global_position = _camera_base_pos
#endregion


#region Hit Freeze
## 히트 프리즈 — 시간을 잠깐 느리게 만들었다 복구 (wall-clock 기반, await 불필요)
func freeze(duration: float = 0.06, scale: float = 0.05) -> void:
	Engine.time_scale = scale
	_freeze_end_msec = maxi(_freeze_end_msec, Time.get_ticks_msec() + int(duration * 1000))


func _update_freeze() -> void:
	if _freeze_end_msec > 0 and Time.get_ticks_msec() >= _freeze_end_msec:
		_freeze_end_msec = 0
		Engine.time_scale = 1.0
#endregion


#region Screen Flash
func _create_flash_overlay() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 100
	add_child(layer)

	_flash_rect = ColorRect.new()
	_flash_rect.color = Color(1, 1, 1, 0)
	_flash_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_flash_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(_flash_rect)


func flash(color: Color = Color.WHITE, intensity: float = 0.6, duration: float = 0.15) -> void:
	_flash_rect.color = Color(color.r, color.g, color.b, intensity)
	var tween := create_tween()
	tween.tween_property(_flash_rect, "color:a", 0.0, duration) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
#endregion


#region Particles
## 착지 먼지 — 주사위가 떨어질 때 바닥에서 퍼지는 입자
func dust(world_pos: Vector3) -> void:
	var p := _make_particles(8, 0.4, Color(0.8, 0.7, 0.5, 0.8))
	p.direction = Vector3(0, 0, -1) # 화면 위쪽
	p.spread = 180.0
	p.initial_velocity_min = 2.0
	p.initial_velocity_max = 4.0
	p.gravity = Vector3(0, 0, 8) # 화면 아래로 당김
	p.scale_amount_min = 0.08
	p.scale_amount_max = 0.15
	_emit_at(p, world_pos)


func _make_particles(amount: int, lifetime: float, color: Color) -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.emitting = false
	p.one_shot = true
	p.amount = amount
	p.lifetime = lifetime
	p.explosiveness = 1.0
	p.color = color

	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.12, 0.12, 0.12)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = color
	mesh.material = mat
	p.mesh = mesh
	return p


func _emit_at(p: CPUParticles3D, pos: Vector3) -> void:
	_world_3d.add_child(p)
	p.global_position = pos
	p.emitting = true
	get_tree().create_timer(p.lifetime + 0.5).timeout.connect(p.queue_free)
#endregion


#region Floating Text
## 플로팅 텍스트 — 주사위 위에서 떠올라 사라지는 보너스/배수 표시
func floating_text(world_pos: Vector3, text: String, color: Color = Color.WHITE, size: int = 64) -> void:
	var label := Label3D.new()
	label.text = text
	label.font_size = size
	label.modulate = color
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.pixel_size = 0.01
	label.outline_size = 8
	label.outline_modulate = Color(0, 0, 0, 0.8)

	_world_3d.add_child(label)
	label.global_position = world_pos + Vector3(0, 2, 0)

	var tween := create_tween()
	tween.set_parallel(true)
	# 화면 위로 떠오름 (-Z = 화면 위)
	tween.tween_property(label, "global_position:z", world_pos.z - 3.0, 0.7) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	# 페이드아웃
	tween.tween_property(label, "modulate:a", 0.0, 0.7) \
		.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	tween.finished.connect(label.queue_free)
#endregion
