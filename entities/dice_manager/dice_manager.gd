extends Node3D

const DICE_SCENE = preload("res://entities/dice/dice.tscn")
const DICE_COUNT: int = 5

## 위치 설정 (에디터에서 조정 가능)
@export_group("Positions")
@export var roll_height: float = 12.0
@export var display_height: float = 1.0
@export var display_z: float = 0.0
@export var keep_z: float = -4.0
@export var dice_spacing: float = 3.0

## 주사위 노드 (타입 명시)
var dice_nodes: Array[RigidBody3D] = []

## 롤 상태 관리
var _rolling_indices: Array[int] = []
var _pending_results: Dictionary = {}  # {index: value}
var _cached_values: Array[int] = [0, 0, 0, 0, 0]

## Keep 상태 관리
var _kept_indices: Array[int] = []
var _locked_kept_indices: Array[int] = []

signal all_dice_finished(values: Array[int])
signal selection_changed(indices: Array[int])


func _ready() -> void:
	_spawn_dice()


#region 위치 계산
func _get_roll_position(index: int) -> Vector3:
	# 분산된 시작 위치 (충돌 최소화)
	var positions: Array[Vector3] = [
		Vector3(-dice_spacing * 2, roll_height, -dice_spacing),
		Vector3(dice_spacing * 2, roll_height, -dice_spacing),
		Vector3(-dice_spacing, roll_height, 0),
		Vector3(dice_spacing, roll_height, 0),
		Vector3(0, roll_height, dice_spacing)
	]
	return positions[index] if index < positions.size() else Vector3.ZERO


func _get_display_position(index: int) -> Vector3:
	var x_offset = (index - 2) * dice_spacing  # -2, -1, 0, 1, 2 기준
	return Vector3(x_offset, display_height, display_z)


func _get_keep_position(slot: int) -> Vector3:
	var x_offset = (slot - 2) * dice_spacing
	return Vector3(x_offset, display_height, keep_z)
#endregion


#region 초기화
func _spawn_dice() -> void:
	for i in range(DICE_COUNT):
		var die := DICE_SCENE.instantiate() as RigidBody3D
		die.dice_index = i
		add_child(die)
		die.setup(_get_display_position(i), _get_roll_position(i))
		die.roll_finished.connect(_on_dice_finished)
		die.dice_clicked.connect(_on_dice_clicked)
		dice_nodes.append(die)


func set_dice_instances(instances: Array) -> void:
	for i in range(mini(instances.size(), dice_nodes.size())):
		dice_nodes[i].set_dice_instance(instances[i])
#endregion


#region 롤 API
func roll_all_with_direction(direction: Vector2, strength: float) -> void:
	_reset_state()
	_roll_dice(_get_all_indices(), direction, strength)


func reroll_unkept_with_direction(direction: Vector2, strength: float) -> void:
	_lock_current_kept()
	var indices := _get_unkept_indices()
	if indices.size() > 0:
		_roll_dice(indices, direction, strength)
#endregion


#region 롤 내부 구현
func _roll_dice(indices: Array[int], direction: Vector2 = Vector2.ZERO, strength: float = 0.0) -> void:
	_rolling_indices = indices.duplicate()
	_pending_results.clear()

	var use_direction := direction != Vector2.ZERO and strength > 0.0

	for i in indices:
		if i >= 0 and i < dice_nodes.size():
			if use_direction:
				dice_nodes[i].roll_dice_with_direction(direction, strength)
			else:
				dice_nodes[i].roll_dice()


func _on_dice_finished(dice_index: int, value: int) -> void:
	_pending_results[dice_index] = value
	_cached_values[dice_index] = value

	if _pending_results.size() == _rolling_indices.size():
		_rolling_indices.clear()
		all_dice_finished.emit(_cached_values.duplicate())
#endregion


#region Keep 관리
func _on_dice_clicked(dice_index: int) -> void:
	if GameState.current_phase != GameState.Phase.ACTION:
		return

	# 잠긴 Keep은 해제 불가
	if dice_index in _locked_kept_indices:
		return

	# 현재 턴에 Keep한 주사위는 토글 가능
	if dice_index in _kept_indices:
		_kept_indices.erase(dice_index)
	else:
		_kept_indices.append(dice_index)

	_update_dice_positions()
	selection_changed.emit(_kept_indices.duplicate())


func keep_dice(dice_index: int) -> void:
	if dice_index in _kept_indices:
		return
	_kept_indices.append(dice_index)
	_update_dice_positions()


func clear_kept() -> void:
	for idx in _kept_indices:
		if idx >= 0 and idx < dice_nodes.size():
			dice_nodes[idx].set_selected(false)
	_kept_indices.clear()
	_update_dice_positions()
	selection_changed.emit([])


func get_kept_indices() -> Array[int]:
	return _kept_indices.duplicate()


func get_unkept_count() -> int:
	return DICE_COUNT - _kept_indices.size()
#endregion


#region 상태 관리
func _reset_state() -> void:
	_reset_all_to_display()
	_kept_indices.clear()
	_locked_kept_indices.clear()
	_cached_values = [0, 0, 0, 0, 0]


func _lock_current_kept() -> void:
	for idx in _kept_indices:
		if idx not in _locked_kept_indices:
			_locked_kept_indices.append(idx)


func _update_dice_positions() -> void:
	var keep_slot := 0
	for i in range(DICE_COUNT):
		var die := dice_nodes[i]
		var is_kept := i in _kept_indices
		die.set_selected(is_kept)
		if is_kept:
			die.set_display_position(_get_keep_position(keep_slot))
			keep_slot += 1
		else:
			die.set_display_position(_get_display_position(i))


func _reset_all_to_display() -> void:
	for i in range(DICE_COUNT):
		var die := dice_nodes[i]
		die.set_selected(false)
		die.set_display_position(_get_display_position(i))
#endregion


#region 헬퍼
func _get_all_indices() -> Array[int]:
	var indices: Array[int] = []
	for i in range(DICE_COUNT):
		indices.append(i)
	return indices


func _get_unkept_indices() -> Array[int]:
	var indices: Array[int] = []
	for i in range(DICE_COUNT):
		if i not in _kept_indices:
			indices.append(i)
	return indices


func start_breathing(indices: Array) -> void:
	for i in indices:
		if i >= 0 and i < dice_nodes.size():
			dice_nodes[i].start_breathing()


func stop_all_breathing() -> void:
	for die in dice_nodes:
		die.stop_breathing()
#endregion
