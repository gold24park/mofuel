class_name PreRollState
extends GameStateBase

## 첫 굴림 전 상태: Hand에서 5개를 선택하여 Active로 배치
## Hand 주사위 클릭 → Active로 이동 (애니메이션)
## Active 주사위 클릭 → Hand로 복귀 (애니메이션)
## 5개 선택 완료 시 Roll 버튼 활성화

var _is_animating: bool = false ## 애니메이션 중 클릭 방지


func enter() -> void:
	_connect_signals()
	GameState.current_phase = GameState.Phase.PRE_ROLL
	GameState.phase_changed.emit(GameState.current_phase)

	GameState.current_round += 1
	GameState.round_changed.emit(GameState.current_round)

	GameState.rerolls_remaining = 2
	GameState.rerolls_changed.emit(GameState.rerolls_remaining)

	GameState.inventory_manager.draw_to_hand(1)

	_is_animating = false

	# 라운드 전환 애니메이션 (비동기)
	_play_round_transition.call_deferred()


func exit() -> void:
	_disconnect_signals()
	game_root.action_buttons.visible = false
	game_root.roll_button.visible = false


func _connect_signals() -> void:
	game_root.roll_button.roll_pressed.connect(_on_roll_pressed)
	game_root.hand_display.dice_clicked.connect(_on_hand_dice_clicked)
	game_root.dice_manager.active_dice_clicked.connect(_on_active_dice_clicked)


func _disconnect_signals() -> void:
	game_root.roll_button.roll_pressed.disconnect(_on_roll_pressed)
	game_root.hand_display.dice_clicked.disconnect(_on_hand_dice_clicked)
	game_root.dice_manager.active_dice_clicked.disconnect(_on_active_dice_clicked)


#region Round Transition Animation
func _play_round_transition() -> void:
	var is_first_round := GameState.current_round == 1

	GameState.is_transitioning = true
	game_root.dice_labels.hide_all()
	game_root.hand_display.enter_manual_mode()

	if is_first_round:
		await _play_first_round_transition()
	else:
		await _play_next_round_transition()

	# Cleanup & UI 활성화
	game_root.hand_display.exit_manual_mode()
	game_root.dice_manager._reset_state()
	GameState.is_transitioning = false

	# UI 표시 - Roll 버튼은 보이지만 5개 선택 전까지 비활성화
	game_root.roll_button.visible = true


func _play_first_round_transition() -> void:
	# 1. 3D 주사위를 화면 아래로 숨김
	game_root.dice_manager.set_dice_to_hand_position()

	# 2. Hand UI 새로고침
	game_root.hand_display.exit_manual_mode()
	game_root.hand_display.enter_manual_mode()

	# 짧은 대기 (UI 반영용)
	await game_root.get_tree().create_timer(0.1).timeout


func _play_next_round_transition() -> void:
	# 1. Return 애니메이션: Active -> Hand (3D 주사위 내려가기)
	await _animate_return_to_hand()

	# 데이터 이동 (애니메이션 후 처리하여 중복 표시 방지)
	GameState.inventory_manager.return_active_to_hand()

	# 2. Draw 애니메이션: Inventory -> Hand
	if GameState.inventory_manager.get_inventory_count() > 0:
		await _animate_inventory_draw()

	# 4. 3D 주사위 숨김
	game_root.dice_manager.set_dice_to_hand_position()

	# 5. Hand UI 새로고침
	game_root.hand_display.exit_manual_mode()
	game_root.hand_display.enter_manual_mode()


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
#endregion


#region Hand → Active 클릭 처리
func _on_hand_dice_clicked(hand_index: int) -> void:
	if _is_animating or GameState.is_transitioning:
		return

	# 데이터 이동
	var active_index := GameState.move_single_to_active(hand_index)
	if active_index == -1:
		return

	_is_animating = true

	# 3D 동기화 (새로 추가된 주사위에 인스턴스 설정)
	game_root._sync_dice_instances()

	# 애니메이션
	await game_root.dice_manager.animate_single_to_active(active_index)

	_is_animating = false
#endregion


#region Active → Hand 클릭 처리
func _on_active_dice_clicked(active_index: int) -> void:
	if _is_animating or GameState.is_transitioning:
		return

	# Active 범위 확인
	if active_index < 0 or active_index >= GameState.active_dice.size():
		return

	# 1. 데이터 이동
	GameState.move_single_to_hand(active_index)

	# 2. 동기화
	game_root._sync_dice_instances()

	# 3. 즉시 재배치 (애니메이션 없음)
	game_root.dice_manager.set_active_positions_immediate(GameState.active_dice.size())
#endregion


#region Roll
func _on_roll_pressed() -> void:
	if _is_animating or GameState.is_transitioning:
		return
	# 모든 주사위를 굴린다.
	game_root.dice_manager.roll_dice_radial_burst()

	transitioned.emit(self , "RollingState")
#endregion


func handle_input(_event: InputEvent) -> bool:
	return false
