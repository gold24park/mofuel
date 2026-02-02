extends Control

@onready var dice_manager = $SubViewportContainer/SubViewport/World3D/DiceManager
@onready var camera_3d = $SubViewportContainer/SubViewport/World3D/Camera3D
@onready var hud = $CanvasLayer/HUD
@onready var action_buttons = $CanvasLayer/ActionButtons
@onready var score_card = $CanvasLayer/ScoreCard
@onready var game_over_screen = $CanvasLayer/GameOver
@onready var upgrade_screen = $CanvasLayer/UpgradeScreen
@onready var hand_display = $CanvasLayer/HandDisplay
@onready var quick_score = $CanvasLayer/QuickScore
@onready var dice_labels = $CanvasLayer/DiceLabels
@onready var roll_button = $CanvasLayer/RollButton
@onready var inventory_deck = $CanvasLayer/InventoryDeck

enum InputState {
	NORMAL,
	SWAP_SELECT
}

var _input_state: InputState = InputState.NORMAL
var _swap_active_index: int = -1
var _prev_active_dice: Array = []  ## 이전 라운드의 active dice (애니메이션용)


func _ready():
	# 시그널 연결
	dice_manager.all_dice_finished.connect(_on_all_dice_finished)
	dice_manager.selection_changed.connect(_on_selection_changed)
	action_buttons.reroll_pressed.connect(_on_reroll_pressed)
	action_buttons.swap_pressed.connect(_on_swap_pressed)
	action_buttons.end_turn_pressed.connect(_on_end_turn_pressed)
	score_card.category_selected.connect(_on_category_selected)
	game_over_screen.restart_pressed.connect(_on_restart_pressed)
	game_over_screen.upgrade_pressed.connect(_on_upgrade_pressed)
	upgrade_screen.continue_pressed.connect(_on_upgrade_continue)
	hand_display.dice_selected.connect(_on_hand_dice_selected)
	quick_score.score_selected.connect(_on_quick_score_selected)
	quick_score.option_hovered.connect(_on_quick_score_hovered)
	quick_score.option_unhovered.connect(_on_quick_score_unhovered)
	roll_button.roll_pressed.connect(_on_roll_button_pressed)

	# GameState 시그널 연결
	GameState.show_scoring_options.connect(_on_show_scoring_options)
	GameState.round_changed.connect(_on_round_changed)

	# 게임 시작
	_start_game()


func _start_game():
	GameState.start_new_game()
	_change_input_state(InputState.NORMAL)
	# 첫 라운드는 _on_round_changed에서 애니메이션과 함께 처리


func _sync_dice_instances():
	dice_manager.set_dice_instances(GameState.active_dice)
	dice_labels.setup(camera_3d, dice_manager.dice_nodes, GameState.active_dice)


func _on_reroll_pressed():
	_reroll_selected_dice_radial()


#region Swap (첫 굴림 전 1회)
func _on_swap_pressed():
	# Swap 모드 진입: Hand에서 주사위 선택 대기
	var selected: Array[int] = dice_manager.get_selected_indices()
	if selected.size() != 1 or not GameState.can_swap():
		return

	_swap_active_index = selected[0]
	_change_input_state(InputState.SWAP_SELECT)


func _on_hand_dice_selected(hand_index: int):
	match _input_state:
		InputState.NORMAL:
			pass
		InputState.SWAP_SELECT:
			_handle_swap_selection(hand_index)


func _handle_swap_selection(hand_index: int):
	# Swap 실행
	if GameState.swap_dice(_swap_active_index, hand_index):
		_sync_dice_instances()
		dice_manager.clear_selection()
	
	# 성공하든 실패하든 시도 후엔 모드 종료
	_change_input_state(InputState.NORMAL)


func _change_input_state(new_state: InputState):
	_input_state = new_state
	
	match _input_state:
		InputState.NORMAL:
			_swap_active_index = -1
			hand_display.exit_swap_mode()
			action_buttons.visible = true
		
		InputState.SWAP_SELECT:
			hand_display.enter_swap_mode()
			action_buttons.visible = false



#region Roll Handling
func _on_roll_button_pressed() -> void:
	if GameState.current_phase == GameState.Phase.ROUND_START:
		dice_labels.hide_all()
		dice_manager.clear_selection()
		GameState.roll_dice()
		dice_manager.roll_all_radial_burst()


func _reroll_selected_dice_radial() -> void:
	if dice_manager.get_selected_count() == 0:
		return
	if not GameState.can_reroll():
		return

	var indices_to_roll: Array[int] = dice_manager.get_selected_indices()

	if GameState.reroll_dice(indices_to_roll):
		for i in indices_to_roll:
			dice_labels.hide_label(i)
		dice_manager.reroll_selected_radial_burst()
#endregion


func _on_end_turn_pressed():
	GameState.end_turn()


func _on_all_dice_finished(values: Array):
	GameState.on_dice_results(values)
	# 모든 주사위 라벨 표시
	for i in range(5):
		dice_labels.show_label(i)


func _on_show_scoring_options(dice: Array) -> void:
	quick_score.show_options(dice)


func _on_selection_changed(selected_indices: Array):
	action_buttons.set_selected_count(selected_indices.size())


func _on_category_selected(category_id: String, score: int):
	quick_score.hide_options()
	_prev_active_dice = GameState.active_dice.duplicate()  ## 애니메이션용 저장
	GameState.record_score(category_id, score)


func _on_quick_score_selected(category_id: String, score: int):
	dice_manager.stop_all_breathing()
	_prev_active_dice = GameState.active_dice.duplicate()  ## 애니메이션용 저장
	GameState.record_score(category_id, score)


func _on_quick_score_hovered(dice_indices: Array) -> void:
	dice_manager.stop_all_breathing()
	dice_manager.start_breathing(dice_indices)


func _on_quick_score_unhovered() -> void:
	dice_manager.stop_all_breathing()


func _on_round_changed(_round_num: int):
	# 애니메이션 시퀀스 실행
	_play_round_transition()


func _on_restart_pressed():
	_start_game()


func _on_upgrade_pressed():
	upgrade_screen.show_upgrades()


func _on_upgrade_continue():
	_start_game()


#region 라운드 전환 애니메이션
func _play_round_transition() -> void:
	GameState.is_transitioning = true
	dice_labels.hide_all()  # 새 라운드 시작 시 라벨 숨김 (굴리기 전)
	hand_display.enter_manual_mode()

	# 1. Round End: Active -> Hand (Return)
	if GameState.current_round > 1:
		await _animate_return_to_hand()

	# 2. Draw Phase: Inventory -> Hand
	if GameState.get_inventory_count() > 0:
		await _animate_inventory_draw()

	# 3. Preparation: Sync Data for New Round
	_sync_dice_instances()
	dice_manager.set_dice_to_hand_position()
	
	# Hand UI 새로고침 (데이터 동기화 후 실제 Hand 상태 반영)
	hand_display.exit_manual_mode()
	hand_display.enter_manual_mode()

	# 4. New Round: Hand -> Active (Rise)
	await _animate_rise_to_active()

	# 5. Cleanup
	hand_display.exit_manual_mode()
	GameState.is_transitioning = false
	dice_manager.clear_selection()


func _animate_return_to_hand() -> void:
	# 5개의 임시 슬롯 추가 (이전 active dice)
	hand_display.prepare_incoming_slots(5, _prev_active_dice)

	# 3D 주사위가 Hand로 내려가면서 임시 슬롯이 하나씩 나타남
	await dice_manager.animate_dice_to_hand_with_callback(
		func(index: int):
			hand_display.animate_temp_slot_appear(index)
	)


func _animate_inventory_draw() -> void:
	var hand_target: Vector2 = hand_display.get_global_rect().get_center()
	await inventory_deck.animate_draw(hand_target)


func _animate_rise_to_active() -> void:
	# 5개의 outgoing 슬롯 추가 (새 active dice)
	hand_display.prepare_outgoing_slots(5, GameState.active_dice)

	# Active 위치로 상승 애니메이션 (임시 슬롯이 하나씩 사라짐)
	var slot_index := [4]  # 마지막 슬롯부터 사라지게
	await dice_manager.animate_dice_to_active_with_callback(
		func(_index: int):
			hand_display.animate_temp_slot_disappear(slot_index[0])
			slot_index[0] -= 1
	)
#endregion
