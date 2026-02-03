extends Node3D

const DICE_SCENE = preload("res://entities/dice/dice.tscn")
const DICE_COUNT: int = 5

## 위치 설정 (에디터에서 조정 가능)
@export_group("Positions")
@export var roll_height: float = 25.0
@export var display_height: float = 1.0
@export var display_z: float = 0.0
@export var dice_spacing: float = 3.0
@export var hand_height: float = 1.0 ## Hand 영역 높이
@export var hand_z: float = 12.0 ## 화면 하단 (카메라 기준 아래쪽)

## 애니메이션 설정
@export_group("Animation")
@export var transition_duration: float = 0.4
@export var stagger_delay: float = 0.05 ## 각 주사위 간 딜레이

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
var _pending_results: Dictionary = {} # {index: value}
var _cached_values: Array[int] = [0, 0, 0, 0, 0]

## 선택 상태 관리
var _selected_indices: Array[int] = []

signal all_dice_finished(values: Array[int])
signal selection_changed(indices: Array[int])
signal effects_applied(effect_data: Array[Dictionary]) ## UI 연출용 (from, to, name)
signal round_transition_finished
signal dice_hovered(dice_index: int)
signal dice_unhovered(dice_index: int)
signal active_dice_clicked(active_index: int) ## PRE_ROLL에서 Active 주사위 클릭 시


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
	var x_offset = (index - 2) * dice_spacing # -2, -1, 0, 1, 2 기준
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
		die.dice_hovered.connect(_on_dice_hovered)
		die.dice_unhovered.connect(_on_dice_unhovered)
		dice_nodes.append(die)


func set_dice_instances(instances: Array) -> void:
	for i in range(mini(instances.size(), dice_nodes.size())):
		dice_nodes[i].set_dice_instance(instances[i])
#endregion


#region 롤 API

func roll_dice_radial_burst() -> void:
	var indices: Array[int] = []
	for i in range(DICE_COUNT):
		indices.append(i)
	_roll_dice_radial_burst(indices)
	_reset_state()

func reroll_selected_radial_burst() -> void:
	var indices := _selected_indices.duplicate()
	if indices.size() > 0:
		_roll_dice_radial_burst(indices)
	_reset_state()


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
		var random_offset := randf_range(-0.15, 0.15) # 약간의 랜덤
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

		# 주사위 정렬 (규칙 3)
		await _sort_and_animate_dice()

		_rolling_indices.clear()
		all_dice_finished.emit(_cached_values.duplicate())


## 주사위 눈금 순으로 정렬 및 애니메이션
func _sort_and_animate_dice() -> void:
	# 1. 정렬 데이터 준비
	var sort_data = []
	for i in range(DICE_COUNT):
		sort_data.append({
			"old_index": i,
			"value": _cached_values[i],
			"node": dice_nodes[i]
		})
	
	# 값 오름차순 정렬
	sort_data.sort_custom(func(a, b): return a.value < b.value)
	
	# 2. 매핑 및 데이터 갱신
	var new_dice_nodes: Array[RigidBody3D] = []
	new_dice_nodes.resize(DICE_COUNT)
	var new_cached_values: Array[int] = []
	new_cached_values.resize(DICE_COUNT)
	var old_to_new = {}
	
	var new_order_indices: Array[int] = [] # InventoryManager용
	
	for new_idx in range(DICE_COUNT):
		var item = sort_data[new_idx]
		var old_idx = item.old_index
		
		new_dice_nodes[new_idx] = item.node
		new_cached_values[new_idx] = item.value
		old_to_new[old_idx] = new_idx
		new_order_indices.append(old_idx)
		
		# 내부 인덱스 업데이트
		item.node.dice_index = new_idx
	
	# 3. InventoryManager 업데이트 (Active Dice 순서)
	GameState.inventory_manager.reorder_active_dice(new_order_indices)
	
	# 4. Rolling Indices 업데이트 (효과 처리를 위해 트리거 위치 갱신)
	var new_rolling_indices: Array[int] = []
	for old_idx in _rolling_indices:
		if old_to_new.has(old_idx):
			new_rolling_indices.append(old_to_new[old_idx])
	_rolling_indices = new_rolling_indices

	# 5. 내부 배열 갱신
	dice_nodes = new_dice_nodes
	_cached_values = new_cached_values
	
	# 6. 애니메이션 (Dice.gd의 내부 상태 업데이트 및 이동)
	# Tween 대신 set_display_position을 사용하여 Dice 내부의 display_position 변수를 갱신해야 함.
	# 그렇지 않으면 나중에 클릭/선택 시 이전 위치로 돌아가는 버그(겹침 현상) 발생.
	for i in range(DICE_COUNT):
		var die = dice_nodes[i]
		var target = _get_display_position(i)
		die.set_display_position(target)
		
	# 이동 시간 대기 (Dice.gd의 이동 속도 고려)
	await get_tree().create_timer(0.6).timeout


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


## Scoring 단계에서 효과 연출 및 적용 (비동기)
func play_scoring_effects_sequence() -> void:
	# 1. ON_ROLL 효과 처리
	var all_dice := _get_all_dice_instances()
	if all_dice.is_empty():
		return

	var roll_results := EffectProcessor.process_trigger(
		DiceEffectResource.Trigger.ON_ROLL,
		all_dice
	)
	
	# 2. ON_ADJACENT_ROLL 효과 처리 (모든 주사위에 대해 시뮬레이션)
	# 인접 롤 트리거는 원래 개별적으로 발생하지만, 여기서는 한 번에 모아서 처리
	# 각 주사위가 서로에게 트리거가 됨
	var adj_results_list = []
	for i in range(DICE_COUNT):
		var res = EffectProcessor.process_trigger(
			DiceEffectResource.Trigger.ON_ADJACENT_ROLL,
			all_dice,
			i
		)
		if not res.is_empty():
			adj_results_list.append(res)
			
	# 3. 효과 적용 및 연출 (순차적)
	# 왼쪽(0)부터 오른쪽(4)으로 순회하며 연출
	for i in range(DICE_COUNT):
		var has_effect = false
		
		# 이 주사위가 소스인 ON_ROLL 효과 찾기
		if roll_results.has(i) or _has_source_effect(roll_results, i):
			has_effect = true
			
		# 이 주사위가 소스인 ADJ 효과 찾기
		for res in adj_results_list:
			if res.has(i) or _has_source_effect(res, i):
				has_effect = true
				
		if has_effect:
			# 연출: 흔들기 + 소리
			dice_nodes[i].start_breathing() # 임시 연출
			# TODO: Play sound
			await get_tree().create_timer(0.3).timeout
			dice_nodes[i].stop_breathing()
			
			# 실제 데이터 적용 (여기서 적용해야 연출과 싱크가 맞음)
			# 하지만 EffectProcessor 구조상 결과가 Target 인덱스로 묶여있음.
			# 단순히 여기서 모두 적용해버리고 넘어가도 됨.
			
	# 데이터 일괄 적용 (연출 후)
	_apply_results_to_dice(roll_results, all_dice)
	for res in adj_results_list:
		_apply_results_to_dice(res, all_dice)
		
	# 결과 UI 갱신 요청 등을 위해 시그널 발송 가능
	# effects_applied.emit(...)


func _has_source_effect(results: Dictionary, source_idx: int) -> bool:
	for target_idx in results:
		for effect in results[target_idx]:
			if effect.source_index == source_idx:
				return true
	return false


func _apply_results_to_dice(results: Dictionary, all_dice: Array) -> void:
	for i in range(all_dice.size()):
		if results.has(i):
			all_dice[i].roll_effects.clear() # 기존 효과 초기화? 주의: 누적되어야 할 수도 있음
			# ON_ROLL은 라운드마다 초기화되는게 맞음.
			for result in results[i]:
				all_dice[i].add_roll_effect(result)
			all_dice[i].apply_roll_effects_from_results()


#region 선택 관리
func _on_dice_clicked(dice_index: int) -> void:
	# Validate at entry point (dice signals should always send valid indices)
	assert(
		dice_index >= 0 and dice_index < DICE_COUNT,
		"Invalid dice_index from click: %d" % dice_index
	)

	# 전환 애니메이션 중에는 선택 불가
	if GameState.is_transitioning:
		return

	var phase := GameState.current_phase

	if phase == GameState.Phase.PRE_ROLL:
		# PRE_ROLL: Active 주사위 클릭 시 Hand로 복귀 시그널 발생
		# 실제 Active에 있는 주사위인지 확인 (dice_index가 Active 개수 내)
		if dice_index < GameState.active_dice.size():
			active_dice_clicked.emit(dice_index)
		return

	if phase == GameState.Phase.POST_ROLL:
		# POST_ROLL: Reroll용 다중 선택 토글
		var is_already_selected := dice_index in _selected_indices
		_set_dice_selection(dice_index, not is_already_selected)
		selection_changed.emit(_selected_indices.duplicate())

func get_selected_indices() -> Array[int]:
	return _selected_indices.duplicate()


func get_selected_count() -> int:
	return _selected_indices.size()


## 내부 헬퍼: 선택 상태 변경 및 비주얼 동기화
func _set_dice_selection(index: int, selected: bool) -> void:
	if selected:
		if index not in _selected_indices:
			_selected_indices.append(index)
			dice_nodes[index].set_selected(true)
	else:
		if index in _selected_indices:
			_selected_indices.erase(index)
			dice_nodes[index].set_selected(false)

#endregion


#region 상태 관리
func _reset_state() -> void:
	_reset_all_to_display()
	_selected_indices.clear()
	# _cached_values는 초기화하지 않음 (유지해야 안 굴린 주사위 값 보존)
	selection_changed.emit([])


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
		die.visible = false # 처음엔 모두 숨김


## 단일 주사위를 Hand 위치에서 Active 위치로 애니메이션
## @param active_index Active 내 인덱스 (표시 위치 결정용)
func animate_single_to_active(active_index: int) -> void:
	if active_index < 0 or active_index >= DICE_COUNT:
		return

	var die := dice_nodes[active_index]
	var hand_center := Vector3(0, hand_height, hand_z)
	var target := _get_display_position(active_index)

	# 시작 위치 설정 (Hand 중앙)
	die.global_position = hand_center
	die.rotation = Vector3(randf() * TAU, randf() * TAU, randf() * TAU)
	die.visible = true

	var tween := create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_parallel(true)

	tween.tween_property(die, "global_position", target, transition_duration)
	tween.tween_property(die, "rotation", Vector3.ZERO, transition_duration)

	await tween.finished


## 단일 주사위를 Active 위치에서 Hand 위치로 애니메이션 후 숨김
## @param active_index Active 내 인덱스
func animate_single_to_hand(active_index: int) -> void:
	if active_index < 0 or active_index >= DICE_COUNT:
		return

	var die := dice_nodes[active_index]
	var hand_center := Vector3(0, hand_height, hand_z)

	var tween := create_tween()
	tween.set_ease(Tween.EASE_IN)
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_parallel(true)

	tween.tween_property(die, "global_position", hand_center, transition_duration * 0.8)
	var random_rotation := Vector3(
		randf_range(-TAU, TAU),
		randf_range(-TAU, TAU),
		randf_range(-TAU, TAU)
	)
	tween.tween_property(die, "rotation", die.rotation + random_rotation, transition_duration * 0.8)

	await tween.finished
	die.visible = false


## Active 주사위 재배치 애니메이션 (인덱스 변경 시)
func reposition_active_dice(count: int) -> void:
	for i in range(DICE_COUNT):
		var die := dice_nodes[i]
		if i < count:
			# Active에 있는 주사위 - 표시하고 새 위치로 이동
			die.visible = true
			var target := _get_display_position(i)
			var tween := create_tween()
			tween.set_ease(Tween.EASE_OUT)
			tween.set_trans(Tween.TRANS_QUAD)
			tween.set_parallel(true)
			tween.tween_property(die, "global_position", target, transition_duration * 0.5)
			tween.tween_property(die, "rotation", Vector3.ZERO, transition_duration * 0.5)
		else:
			# Active에 없는 주사위 - 숨김
			die.visible = false


## Active 주사위 재배치 (await 가능)
func reposition_active_dice_async(count: int) -> void:
	var tweens: Array = []

	for i in range(DICE_COUNT):
		var die := dice_nodes[i]
		if i < count:
			die.visible = true
			var target := _get_display_position(i)
			var tween := create_tween()
			tween.set_ease(Tween.EASE_OUT)
			tween.set_trans(Tween.TRANS_QUAD)
			tween.set_parallel(true)
			tween.tween_property(die, "global_position", target, transition_duration * 0.4)
			tween.tween_property(die, "rotation", Vector3.ZERO, transition_duration * 0.4)
			tweens.append(tween)
		else:
			die.visible = false

	# 마지막 트윈 완료 대기
	if not tweens.is_empty():
		await tweens[-1].finished


## 주사위 제거 + 나머지 밀어서 채우기
## 데이터 이동 후 호출 - dice_nodes[0..count-1]에 이미 새 데이터가 할당된 상태
## @param removed_index 제거된 3D 주사위 인덱스 (숨길 대상)
## @param count 현재 Active 개수
func animate_remove_and_shift(removed_index: int, count: int) -> void:
	var duration := 0.15
	var tweens: Array = []

	# 제거된 인덱스의 3D 주사위: 축소 후 숨김
	var removed_die := dice_nodes[removed_index]
	var remove_tween := create_tween()
	remove_tween.set_trans(Tween.TRANS_LINEAR)
	remove_tween.tween_property(removed_die, "scale", Vector3.ONE * 0.1, duration)
	tweens.append(remove_tween)

	# 현재 Active에 해당하는 주사위들: 올바른 위치로 이동
	for i in range(count):
		var die := dice_nodes[i]
		die.visible = true
		var target := _get_display_position(i)
		var tween := create_tween()
		tween.set_trans(Tween.TRANS_LINEAR)
		tween.set_parallel(true)
		tween.tween_property(die, "global_position", target, duration)
		tween.tween_property(die, "rotation", Vector3.ZERO, duration)
		tweens.append(tween)

	# count 이상의 주사위 숨김
	for i in range(count, DICE_COUNT):
		if i != removed_index: # removed_index는 애니메이션 후 처리
			dice_nodes[i].visible = false

	# 애니메이션 완료 대기
	if not tweens.is_empty():
		await tweens[0].finished

	# 제거된 주사위 숨기고 스케일 복구
	removed_die.visible = false
	removed_die.scale = Vector3.ONE


## 주사위 표시/숨김 설정
func set_dice_visible(index: int, visibility: bool) -> void:
	if index >= 0 and index < DICE_COUNT:
		dice_nodes[index].visible = visibility


## Active 주사위 즉시 배치 (애니메이션 없음)
func set_active_positions_immediate(count: int) -> void:
	for i in range(DICE_COUNT):
		var die := dice_nodes[i]
		if i < count:
			die.visible = true
			die.global_position = _get_display_position(i)
			die.rotation = Vector3.ZERO
		else:
			die.visible = false
#endregion


#region 호버 처리
func _on_dice_hovered(dice_index: int) -> void:
	dice_hovered.emit(dice_index)


func _on_dice_unhovered(dice_index: int) -> void:
	dice_unhovered.emit(dice_index)
#endregion
