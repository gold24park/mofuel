class_name PreRollState
extends GameStateBase

## 첫 굴림 전 상태: Swap 가능, Roll 버튼 활성화
## 라운드 전환 애니메이션도 이 상태의 enter()에서 처리

# Swap 모드 관리
enum SubState { IDLE, SWAP_SELECT }
var _sub_state: SubState = SubState.IDLE
var _swap_active_index: int = -1


func enter() -> void:
	GameState.current_phase = GameState.Phase.PRE_ROLL
	GameState.phase_changed.emit(GameState.current_phase)

	_sub_state = SubState.IDLE
	_connect_signals()

	# 라운드 전환 애니메이션 (비동기)
	_play_round_transition.call_deferred()


func exit() -> void:
	_disconnect_signals()
	game_root.hand_display.exit_swap_mode()
	game_root.action_buttons.visible = false
	game_root.roll_button.visible = false


func _connect_signals() -> void:
	game_root.roll_button.roll_pressed.connect(_on_roll_pressed)
	game_root.action_buttons.swap_pressed.connect(_on_swap_pressed)
	game_root.hand_display.dice_selected.connect(_on_hand_dice_selected)
	game_root.dice_manager.selection_changed.connect(_on_selection_changed)


func _disconnect_signals() -> void:
	game_root.roll_button.roll_pressed.disconnect(_on_roll_pressed)
	game_root.action_buttons.swap_pressed.disconnect(_on_swap_pressed)
	game_root.hand_display.dice_selected.disconnect(_on_hand_dice_selected)
	game_root.dice_manager.selection_changed.disconnect(_on_selection_changed)


#region Round Transition Animation
func _play_round_transition() -> void:
	var is_first_round := GameState.current_round == 0

	GameState.is_transitioning = true
	game_root.dice_labels.hide_all()
	game_root.hand_display.enter_manual_mode()

	if is_first_round:
		await _play_first_round_transition()
	else:
		await _play_next_round_transition()

	# Cleanup & UI 활성화
	game_root.hand_display.exit_manual_mode()
	game_root.dice_manager.clear_selection()
	GameState.is_transitioning = false

	# UI 표시
	game_root.action_buttons.visible = true
	game_root.roll_button.visible = true


func _play_first_round_transition() -> void:
	# 1. 데이터 초기화 (인벤토리, 핸드, Active 모두 설정)
	GameState.start_new_game()

	# 2. 3D 동기화
	game_root._sync_dice_instances()
	game_root.dice_manager.set_dice_to_hand_position()

	# 3. Hand UI 새로고침
	game_root.hand_display.exit_manual_mode()
	game_root.hand_display.enter_manual_mode()

	# 4. Rise 애니메이션
	await _animate_rise_to_active()


func _play_next_round_transition() -> void:
	# 1. Return 애니메이션: Active -> Hand
	await _animate_return_to_hand()

	# 2. Draw 애니메이션: Inventory -> Hand
	if GameState.get_inventory_count() > 0:
		await _animate_inventory_draw()

	# 3. 다음 라운드 데이터 준비
	GameState.start_next_round_data()

	# 4. 3D 동기화
	game_root._sync_dice_instances()
	game_root.dice_manager.set_dice_to_hand_position()

	# 5. Hand UI 새로고침
	game_root.hand_display.exit_manual_mode()
	game_root.hand_display.enter_manual_mode()

	# 6. Rise 애니메이션: Hand -> Active
	await _animate_rise_to_active()


func _animate_return_to_hand() -> void:
	var prev_active = game_root._prev_active_dice
	game_root.hand_display.prepare_incoming_slots(5, prev_active)

	await game_root.dice_manager.animate_dice_to_hand_with_callback(
		func(index: int):
			game_root.hand_display.animate_temp_slot_appear(index)
	)


func _animate_inventory_draw() -> void:
	var target_pos = game_root.hand_display.get_global_rect().get_center()
	await game_root.inventory_deck.animate_draw(target_pos)


func _animate_rise_to_active() -> void:
	game_root.hand_display.prepare_outgoing_slots(5, GameState.active_dice)

	var slot_index := [4]
	await game_root.dice_manager.animate_dice_to_active_with_callback(
		func(_index: int):
			game_root.hand_display.animate_temp_slot_disappear(slot_index[0])
			slot_index[0] -= 1
	)
#endregion


#region Roll
func _on_roll_pressed() -> void:
	if _sub_state != SubState.IDLE:
		return
	if GameState.is_transitioning:
		return

	game_root.dice_labels.hide_all()
	game_root.dice_manager.clear_selection()
	GameState.roll_dice()
	game_root.dice_manager.roll_all_radial_burst()

	transitioned.emit(self, "RollingState")
#endregion


#region Swap
func _on_swap_pressed() -> void:
	if GameState.is_transitioning:
		return

	var selected = game_root.dice_manager.get_selected_indices()
	if selected.size() != 1:
		return
	if not GameState.can_swap():
		return

	_swap_active_index = selected[0]
	_sub_state = SubState.SWAP_SELECT

	game_root.hand_display.enter_swap_mode()
	game_root.action_buttons.visible = false


func _on_hand_dice_selected(hand_index: int) -> void:
	if _sub_state != SubState.SWAP_SELECT:
		return

	if GameState.swap_dice(_swap_active_index, hand_index):
		game_root._sync_dice_instances()
		game_root.dice_manager.clear_selection()

	# Swap 모드 종료
	_sub_state = SubState.IDLE
	_swap_active_index = -1
	game_root.hand_display.exit_swap_mode()
	game_root.action_buttons.visible = true


func _on_selection_changed(indices: Array) -> void:
	game_root.action_buttons.set_selected_count(indices.size())
#endregion


func handle_input(event: InputEvent) -> bool:
	# ESC로 Swap 모드 취소
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		if _sub_state == SubState.SWAP_SELECT:
			_sub_state = SubState.IDLE
			_swap_active_index = -1
			game_root.hand_display.exit_swap_mode()
			game_root.action_buttons.visible = true
			return true
	return false
