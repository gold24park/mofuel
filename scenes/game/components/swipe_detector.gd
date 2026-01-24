extends Node
## Swipe input detector component
## Handles raw InputEvents and emits high-level swipe signals

signal swiped(direction: Vector2, strength: float)

@export_group("Swipe Settings")
@export var min_swipe_distance: float = 50.0   # Minimum swipe distance (pixels)
@export var max_swipe_distance: float = 400.0  # Distance for maximum strength
@export var min_strength: float = 15.0         # Minimum roll strength
@export var max_strength: float = 30.0         # Maximum roll strength

@export_group("Detection Zone")
@export var top_margin: float = 100.0          # Exclude top area (HUD)
@export var bottom_margin: float = 150.0       # Exclude bottom area (buttons/Reserve)

# Swipe state
var _swipe_start_position: Vector2 = Vector2.ZERO
var _swipe_start_time: float = 0.0
var _is_swiping: bool = false
var _active_touch_index: int = -1  # Track first touch for multi-touch handling

var _enabled: bool = true


func _ready() -> void:
	set_process_input(true)


func set_enabled(enabled: bool) -> void:
	_enabled = enabled
	if not enabled:
		_cancel_swipe()


func _input(event: InputEvent) -> void:
	if not _enabled:
		return

	# Touch input (mobile)
	if event is InputEventScreenTouch:
		_handle_touch(event)
	elif event is InputEventScreenDrag:
		_handle_drag(event)
	# Mouse input (desktop/testing)
	elif event is InputEventMouseButton:
		_handle_mouse_button(event)
	elif event is InputEventMouseMotion:
		_handle_mouse_motion(event)


#region Touch Input (Mobile)
func _handle_touch(event: InputEventScreenTouch) -> void:
	if event.pressed:
		# Only track first finger
		if _active_touch_index == -1:
			_active_touch_index = event.index
			_try_start_swipe(event.position)
	else:
		# Release - only respond to tracked finger
		if event.index == _active_touch_index:
			_try_end_swipe(event.position)
			_active_touch_index = -1


func _handle_drag(_event: InputEventScreenDrag) -> void:
	# Could add visual feedback during drag
	pass
#endregion


#region Mouse Input (Desktop)
func _handle_mouse_button(event: InputEventMouseButton) -> void:
	if event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_try_start_swipe(event.position)
		else:
			_try_end_swipe(event.position)


func _handle_mouse_motion(_event: InputEventMouseMotion) -> void:
	# Could add visual feedback during swipe
	pass
#endregion


#region Swipe Detection
func _is_in_swipe_zone(pos: Vector2) -> bool:
	var viewport_size := get_viewport().get_visible_rect().size
	return pos.y > top_margin and pos.y < viewport_size.y - bottom_margin


func _try_start_swipe(pos: Vector2) -> void:
	if not _is_in_swipe_zone(pos):
		return

	_is_swiping = true
	_swipe_start_position = pos
	_swipe_start_time = Time.get_ticks_msec() / 1000.0


func _try_end_swipe(pos: Vector2) -> void:
	if not _is_swiping:
		return

	_is_swiping = false

	var swipe_vector := pos - _swipe_start_position
	var swipe_distance := swipe_vector.length()

	# Ignore if below minimum distance
	if swipe_distance < min_swipe_distance:
		return

	# Calculate direction and strength
	var direction := swipe_vector.normalized()
	var distance_factor := clampf(swipe_distance / max_swipe_distance, 0.0, 1.0)

	# Speed bonus (faster swipe = stronger)
	var elapsed_time := (Time.get_ticks_msec() / 1000.0) - _swipe_start_time
	var speed := swipe_distance / maxf(elapsed_time, 0.01)
	var speed_factor := clampf(speed / 1000.0, 0.0, 1.0)  # 1000 px/sec = max

	# Combine distance and speed
	var strength_factor := (distance_factor + speed_factor) / 2.0
	var strength := lerpf(min_strength, max_strength, strength_factor)

	swiped.emit(direction, strength)


func _cancel_swipe() -> void:
	_is_swiping = false
	_active_touch_index = -1
#endregion
