class_name PreRollState
extends GameStateBase

## PRE_ROLL 상태
## - 기본: Hand에서 주사위 클릭 → Active로 이동
## - Discard: Hand 주사위를 DiscardSlot으로 드래그 앤 드롭
## - Hand == 5 & Active == 0 → 자동 활성화 (순차 애니메이션)
## - Draw 버튼: deck pool에서 hand로 드로우

var _is_animating: bool = false


func enter() -> void:
	_connect_signals()
	GameState.current_phase = GameState.Phase.PRE_ROLL
	GameState.phase_changed.emit(GameState.current_phase)

	GameState.current_round += 1
	GameState.round_changed.emit(GameState.current_round)

	GameState.rerolls_remaining = GameState.MAX_REROLLS
	GameState.rerolls_changed.emit(GameState.rerolls_remaining)
	GameState.is_double_down = false

	# 드로우 횟수 리셋
	GameState.draws_remaining = GameState.max_draws_per_round
	GameState.draws_changed.emit(GameState.draws_remaining)

	_is_animating = false

	# 라운드 전환 애니메이션 (비동기)
	_play_round_transition.call_deferred()


func exit() -> void:
	_disconnect_signals()
	game_root.roll_button.visible = false


func _connect_signals() -> void:
	game_root.roll_button.roll_pressed.connect(_on_roll_pressed)
	game_root.hand_display.dice_clicked.connect(_on_hand_dice_clicked)
	game_root.hand_display.dice_discarded.connect(_on_dice_discarded)
	game_root.dice_manager.active_dice_clicked.connect(_on_active_dice_clicked)
	game_root.hand_display.draw_pressed.connect(_on_draw_pressed)


func _disconnect_signals() -> void:
	game_root.roll_button.roll_pressed.disconnect(_on_roll_pressed)
	game_root.hand_display.dice_clicked.disconnect(_on_hand_dice_clicked)
	game_root.hand_display.dice_discarded.disconnect(_on_dice_discarded)
	game_root.dice_manager.active_dice_clicked.disconnect(_on_active_dice_clicked)
	game_root.hand_display.draw_pressed.disconnect(_on_draw_pressed)


#region Round Transition Animation
func _play_round_transition() -> void:
	var is_first_round := GameState.current_round == 1

	GameState.is_transitioning = true
	game_root.hand_display.enter_manual_mode()

	if is_first_round:
		await _play_first_round_transition()
	else:
		await _play_next_round_transition()

	# Cleanup & UI 활성화
	game_root.hand_display.exit_manual_mode()
	game_root.dice_manager._reset_state()
	GameState.is_transitioning = false

	game_root.roll_button.visible = true
	_update_draw_ui()
	_try_auto_activate()


func _play_first_round_transition() -> void:
	game_root.dice_manager.set_dice_to_hand_position()
	game_root.hand_display.exit_manual_mode()
	game_root.hand_display.enter_manual_mode()
	await game_root.get_tree().create_timer(0.1).timeout


func _play_next_round_transition() -> void:
	await _animate_return_to_hand()
	GameState.deck.return_active_to_hand()
	game_root.dice_manager.set_dice_to_hand_position()
	game_root.hand_display.exit_manual_mode()
	game_root.hand_display.enter_manual_mode()


func _animate_return_to_hand() -> void:
	game_root.hand_display.prepare_incoming_slots(GameState.DICE_COUNT, GameState.active_dice)

	await game_root.dice_manager.animate_dice_to_hand_with_callback(
		func(index: int):
			game_root.hand_display.animate_temp_slot_appear(index)
	)
#endregion


#region 자동 활성화 (공통 체크)
## Hand == 5 & Active 비어있음 → 순차 애니메이션
func _try_auto_activate() -> void:
	if _is_animating:
		return
	if GameState.deck.hand.size() != GameState.DICE_COUNT:
		return
	if GameState.active_dice.size() != 0:
		return

	var indices: Array[int] = []
	indices.assign(range(GameState.DICE_COUNT))
	GameState.deck.move_hand_to_active(indices)

	game_root._sync_dice_instances()
	game_root.dice_manager.set_dice_to_hand_position()

	_is_animating = true
	for i in GameState.DICE_COUNT:
		game_root.dice_manager.animate_single_to_active(i)
		await game_root.get_tree().create_timer(0.08).timeout
	_is_animating = false

	game_root.roll_button.visible = true
	_update_draw_ui()


func _update_draw_ui() -> void:
	game_root.hand_display.set_draw_enabled(GameState.can_draw())
#endregion


#region Hand → Active 클릭 처리
func _on_hand_dice_clicked(hand_index: int) -> void:
	if _is_animating or GameState.is_transitioning:
		return

	var active_index := GameState.move_single_to_active(hand_index)
	if active_index == -1:
		return

	_is_animating = true
	game_root._sync_dice_instances()
	await game_root.dice_manager.animate_single_to_active(active_index)
	_is_animating = false
#endregion


#region Active → Hand 클릭 처리
func _on_active_dice_clicked(active_index: int) -> void:
	if _is_animating or GameState.is_transitioning:
		return
	if active_index < 0 or active_index >= GameState.active_dice.size():
		return

	GameState.move_single_to_hand(active_index)
	game_root._sync_dice_instances()
	game_root.dice_manager.set_active_positions_immediate(GameState.active_dice.size())
#endregion


#region 버리기 처리 (드래그 앤 드롭으로 트리거)
func _on_dice_discarded(hand_index: int) -> void:
	if _is_animating or GameState.is_transitioning:
		return
	GameState.deck.discard_from_hand(hand_index)
	_update_draw_ui()
	_try_auto_activate()
#endregion


#region 수동 드로우
func _on_draw_pressed() -> void:
	if _is_animating or GameState.is_transitioning:
		return

	if not GameState.draw_one():
		return

	_is_animating = true
	var target_pos = game_root.hand_display.get_global_rect().get_center()
	await game_root.inventory_deck.animate_draw(target_pos)
	_is_animating = false

	_update_draw_ui()
	_try_auto_activate()
#endregion


#region Roll
func _on_roll_pressed() -> void:
	if _is_animating or GameState.is_transitioning:
		return
	game_root.dice_manager.roll_dice_radial_burst()
	transitioned.emit(self , "RollingState")
#endregion


func handle_input(_event: InputEvent) -> bool:
	return false
