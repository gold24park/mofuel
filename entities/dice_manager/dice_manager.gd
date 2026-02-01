extends Node3D

const DICE_SCENE = preload("res://entities/dice/dice.tscn")
const DICE_COUNT: int = 5

## 위치 설정 (에디터에서 조정 가능)
@export_group("Positions")
@export var roll_height: float = 25.0
@export var display_height: float = 1.0
@export var display_z: float = 0.0
@export var dice_spacing: float = 3.0
@export var hand_height: float = 1.0  ## Hand 영역 높이
@export var hand_z: float = 12.0  ## 화면 하단 (카메라 기준 아래쪽)

## 애니메이션 설정
@export_group("Animation")
@export var transition_duration: float = 0.4
@export var stagger_delay: float = 0.05  ## 각 주사위 간 딜레이

## 방사형 버스트 설정
@export_group("Radial Burst")
@export var burst_height: float = 20.0
@export var burst_strength: float = 28.0

## 롤 속도 설정
@export_group("Roll Speed")
@export var roll_time_scale: float = 2.0

const BASE_PHYSICS_TICKS: int = 60

## 주사위 노드 (타입 명시)
var dice_nodes: Array[RigidBody3D] = []

## 롤 상태 관리
var _rolling_indices: Array[int] = []
var _pending_results: Dictionary = {}  # {index: value}
var _cached_values: Array[int] = [0, 0, 0, 0, 0]

## 선택 상태 관리
var _selected_indices: Array[int] = []

signal all_dice_finished(values: Array[int])
signal selection_changed(indices: Array[int])
signal effects_applied(effect_data: Array[Dictionary])  ## UI 연출용 (from, to, name)
signal round_transition_finished


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
func roll_all_radial_burst() -> void:
	_reset_state()
	_roll_dice_radial_burst(_get_all_indices())


func reroll_selected_radial_burst() -> void:
	var indices := _selected_indices.duplicate()
	if indices.size() > 0:
		_roll_dice_radial_burst(indices)
	clear_selection()


func _roll_dice_radial_burst(indices: Array[int]) -> void:
	_rolling_indices = indices.duplicate()
	_pending_results.clear()
	_set_fast_physics(true)

	var center := Vector3(0, burst_height, 0)
	var angle_step := TAU / indices.size()

	for i in range(indices.size()):
		var idx := indices[i]
		# 각 주사위마다 방사형 방향 계산 (인덱스는 _selected_indices 또는 _get_all_indices에서 보장)
		var base_angle := angle_step * i
		var random_offset := randf_range(-0.15, 0.15)  # 약간의 랜덤
		var angle := base_angle + random_offset

		var direction := Vector3(cos(angle), 0, sin(angle))
		dice_nodes[idx].roll_dice_radial_burst(center, direction, burst_strength)
#endregion


#region 롤 내부 구현
func _set_fast_physics(enabled: bool) -> void:
	if enabled:
		Engine.time_scale = roll_time_scale
		Engine.physics_ticks_per_second = int(BASE_PHYSICS_TICKS * roll_time_scale)
	else:
		Engine.time_scale = 1.0
		Engine.physics_ticks_per_second = BASE_PHYSICS_TICKS


func _on_dice_finished(dice_index: int, value: int) -> void:
	_pending_results[dice_index] = value
	_cached_values[dice_index] = value

	if _pending_results.size() == _rolling_indices.size():
		_set_fast_physics(false)

		# ON_ROLL 효과 처리
		_process_roll_effects()

		# ON_ADJACENT_ROLL 효과 처리 (각 굴린 주사위에 대해)
		for rolled_idx in _rolling_indices:
			_process_adjacent_roll_effects(rolled_idx)

		_rolling_indices.clear()
		all_dice_finished.emit(_cached_values.duplicate())


## ON_ROLL 효과 처리
func _process_roll_effects() -> void:
	var all_dice := _get_all_dice_instances()
	if all_dice.is_empty():
		return

	var results := EffectProcessor.process_trigger(
		DiceEffectResource.Trigger.ON_ROLL,
		all_dice
	)

	# 각 주사위에 결과 할당 및 적용
	var effect_data: Array[Dictionary] = []
	for i in range(all_dice.size()):
		all_dice[i].roll_effects.clear()
		if results.has(i):
			for result in results[i]:
				all_dice[i].add_roll_effect(result)
				# 시각적 피드백 데이터 수집
				if result.source_index >= 0 and result.source_index != i:
					effect_data.append({
						"from": result.source_index,
						"to": i,
						"name": result.effect_name
					})
		all_dice[i].apply_roll_effects_from_results()

	if not effect_data.is_empty():
		effects_applied.emit(effect_data)


## ON_ADJACENT_ROLL 효과 처리
func _process_adjacent_roll_effects(triggering_index: int) -> void:
	var all_dice := _get_all_dice_instances()
	if all_dice.is_empty():
		return

	var results := EffectProcessor.process_trigger(
		DiceEffectResource.Trigger.ON_ADJACENT_ROLL,
		all_dice,
		triggering_index
	)

	# 기존 roll_effects에 병합
	var effect_data: Array[Dictionary] = []
	for i in range(all_dice.size()):
		if results.has(i):
			for result in results[i]:
				all_dice[i].add_roll_effect(result)
				if result.source_index >= 0:
					effect_data.append({
						"from": result.source_index,
						"to": i,
						"name": result.effect_name,
						"trigger": "adjacent_roll"
					})

	if not effect_data.is_empty():
		effects_applied.emit(effect_data)


## 모든 주사위 인스턴스 반환
func _get_all_dice_instances() -> Array:
	var instances: Array = []
	for node in dice_nodes:
		if node.has_method("get_dice_instance"):
			var instance = node.get_dice_instance()
			if instance:
				instances.append(instance)
		elif "dice_instance" in node:
			if node.dice_instance:
				instances.append(node.dice_instance)
	return instances
#endregion


#region 선택 관리
func _on_dice_clicked(dice_index: int) -> void:
	# Validate at entry point (dice signals should always send valid indices)
	assert(dice_index >= 0 and dice_index < DICE_COUNT,
		"Invalid dice_index from click: %d" % dice_index)

	# 전환 애니메이션 중에는 선택 불가
	if GameState.is_transitioning:
		return

	# ROUND_START (Swap용) 또는 ACTION (Reroll용)에서만 선택 가능
	var phase := GameState.current_phase
	if phase != GameState.Phase.ROUND_START and phase != GameState.Phase.ACTION:
		return

	# 선택 토글
	if dice_index in _selected_indices:
		_selected_indices.erase(dice_index)
		dice_nodes[dice_index].set_selected(false)
	else:
		_selected_indices.append(dice_index)
		dice_nodes[dice_index].set_selected(true)

	selection_changed.emit(_selected_indices.duplicate())


func clear_selection() -> void:
	# _selected_indices는 _on_dice_clicked에서 검증됨
	for idx in _selected_indices:
		dice_nodes[idx].set_selected(false)
	_selected_indices.clear()
	selection_changed.emit([])


func get_selected_indices() -> Array[int]:
	return _selected_indices.duplicate()


func get_selected_count() -> int:
	return _selected_indices.size()
#endregion


#region 상태 관리
func _reset_state() -> void:
	_reset_all_to_display()
	_selected_indices.clear()
	_cached_values = [0, 0, 0, 0, 0]


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


## External API - indices should be validated by caller but we guard defensively
func start_breathing(indices: Array) -> void:
	for i in indices:
		if not Guard.verify(i >= 0 and i < dice_nodes.size(),
				"Invalid breathing index %d" % i):
			continue
		dice_nodes[i].start_breathing()


func stop_all_breathing() -> void:
	for die in dice_nodes:
		die.stop_breathing()
#endregion


#region 라운드 전환 애니메이션
## Active → 화면 하단 중앙으로 이동 + 콜백 (라운드 종료 시)
func animate_dice_to_hand_with_callback(on_each_finished: Callable) -> void:
	var center := Vector3(0, hand_height, hand_z)

	for i in range(dice_nodes.size()):
		var die := dice_nodes[i]
		var tween := create_tween()
		tween.set_ease(Tween.EASE_IN)
		tween.set_trans(Tween.TRANS_QUAD)
		tween.set_parallel(true)

		# 위치 이동 (중앙으로)
		tween.tween_property(die, "global_position", center, transition_duration)
		# 회전 (랜덤 방향으로 1~2바퀴)
		var random_rotation := Vector3(
			randf_range(-TAU, TAU) * 2,
			randf_range(-TAU, TAU),
			randf_range(-TAU, TAU) * 2
		)
		tween.tween_property(die, "rotation", die.rotation + random_rotation, transition_duration)

		await tween.finished
		on_each_finished.call(i)

	# 모든 주사위 내려간 후 잠시 대기
	await get_tree().create_timer(0.1).timeout


## 화면 아래 중앙 → Active 위치로 상승 + 콜백 (라운드 시작 시)
func animate_dice_to_active_with_callback(on_each_finished: Callable) -> void:
	for i in range(dice_nodes.size()):
		var die := dice_nodes[i]
		var target := _get_display_position(i)
		var tween := create_tween()
		tween.set_ease(Tween.EASE_OUT)
		tween.set_trans(Tween.TRANS_BACK)
		tween.set_parallel(true)

		# 위치 이동
		tween.tween_property(die, "global_position", target, transition_duration)
		# 회전 (Vector.UP 방향으로 정렬)
		tween.tween_property(die, "rotation", Vector3.ZERO, transition_duration)

		await tween.finished
		on_each_finished.call(i)

	round_transition_finished.emit()


## 모든 주사위를 화면 하단 중앙으로 즉시 이동 (초기 위치 설정용)
func set_dice_to_hand_position() -> void:
	var center := Vector3(0, hand_height, hand_z)
	for i in range(dice_nodes.size()):
		var die := dice_nodes[i]
		die.global_position = center
		die.rotation = Vector3(randf() * TAU, randf() * TAU, randf() * TAU)
#endregion
