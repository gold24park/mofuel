extends Control

const SwipeDetector = preload("res://scenes/game/components/swipe_detector.gd")

@onready var dice_manager = $SubViewportContainer/SubViewport/World3D/DiceManager
@onready var hud = $CanvasLayer/HUD
@onready var action_buttons = $CanvasLayer/ActionButtons
@onready var score_card = $CanvasLayer/ScoreCard
@onready var game_over_screen = $CanvasLayer/GameOver
@onready var upgrade_screen = $CanvasLayer/UpgradeScreen
@onready var reserve_display = $CanvasLayer/ReserveDisplay
@onready var quick_score = $CanvasLayer/QuickScore

var _swipe_detector: Node
var _replace_mode: bool = false
var _replace_active_index: int = -1


func _ready():
	# SwipeDetector 생성 및 연결
	_swipe_detector = SwipeDetector.new()
	add_child(_swipe_detector)
	_swipe_detector.swiped.connect(_on_swipe_detected)

	# 시그널 연결
	dice_manager.all_dice_finished.connect(_on_all_dice_finished)
	dice_manager.selection_changed.connect(_on_selection_changed)
	action_buttons.reroll_pressed.connect(_on_reroll_pressed)
	action_buttons.replace_pressed.connect(_on_replace_pressed)
	action_buttons.end_turn_pressed.connect(_on_end_turn_pressed)
	score_card.category_selected.connect(_on_category_selected)
	game_over_screen.restart_pressed.connect(_on_restart_pressed)
	game_over_screen.upgrade_pressed.connect(_on_upgrade_pressed)
	upgrade_screen.continue_pressed.connect(_on_upgrade_continue)
	reserve_display.dice_selected.connect(_on_reserve_dice_selected)
	quick_score.score_selected.connect(_on_quick_score_selected)
	quick_score.option_hovered.connect(_on_quick_score_hovered)
	quick_score.option_unhovered.connect(_on_quick_score_unhovered)

	# 게임 시작
	_start_game()


func _start_game():
	GameState.start_new_game()
	_sync_dice_instances()


func _sync_dice_instances():
	dice_manager.set_dice_instances(GameState.active_dice)


func _on_reroll_pressed():
	_reroll_unkept_dice(Vector2.ZERO, 0.0)


func _on_replace_pressed():
	# Replace 모드 진입: Reserve에서 주사위 선택 대기
	# Keep된 주사위 중 하나만 선택되어 있어야 함
	var kept = dice_manager.get_kept_indices()
	if kept.size() != 1 or GameState.get_reserve_count() == 0:
		return

	_replace_mode = true
	_replace_active_index = kept[0]
	_swipe_detector.set_enabled(false)
	reserve_display.enter_replace_mode()
	action_buttons.visible = false


func _on_reserve_dice_selected(reserve_index: int):
	if not _replace_mode:
		return

	# Replace 실행
	GameState.replace_dice(_replace_active_index, reserve_index)
	_sync_dice_instances()
	dice_manager.clear_kept()

	# Replace 모드 종료
	_exit_replace_mode()


func _exit_replace_mode():
	_replace_mode = false
	_replace_active_index = -1
	_swipe_detector.set_enabled(true)
	reserve_display.exit_replace_mode()
	action_buttons.visible = true


func _input(event):
	# ESC로 Replace 모드 취소
	if _replace_mode and event.is_action_pressed("ui_cancel"):
		_exit_replace_mode()
		get_viewport().set_input_as_handled()


#region Swipe Handling
func _on_swipe_detected(direction: Vector2, strength: float) -> void:
	var phase := GameState.current_phase

	if phase == GameState.Phase.ROUND_START:
		_roll_all_dice(direction, strength)
	elif phase == GameState.Phase.ACTION:
		_reroll_unkept_dice(direction, strength)


func _roll_all_dice(direction: Vector2, strength: float) -> void:
	GameState.roll_dice()
	dice_manager.roll_all_with_direction(direction, strength)


func _reroll_unkept_dice(direction: Vector2, strength: float) -> void:
	if dice_manager.get_unkept_count() == 0:
		return
	if not GameState.can_reroll():
		return

	var indices_to_roll: Array[int] = []
	for i in range(5):
		if i not in dice_manager.get_kept_indices():
			indices_to_roll.append(i)

	if GameState.reroll_dice(indices_to_roll):
		dice_manager.reroll_unkept_with_direction(direction, strength)
#endregion


func _on_end_turn_pressed():
	GameState.end_turn()


func _on_all_dice_finished(values: Array):
	GameState.on_dice_results(values)
	_check_auto_end_turn()


func _check_auto_end_turn() -> void:
	if GameState.current_phase != GameState.Phase.ACTION:
		return

	if GameState.can_reroll():
		# 리롤 가능 - 빠른 점수 선택 옵션 표시
		quick_score.show_options(GameState.active_dice)
	else:
		# 리롤 불가 - 자동으로 모든 주사위 Keep하고 스코어링
		_keep_all_dice()
		GameState.end_turn()


func _keep_all_dice() -> void:
	for i in range(5):
		if i not in dice_manager.get_kept_indices():
			dice_manager.keep_dice(i)


func _on_selection_changed(kept_indices: Array):
	action_buttons.set_kept_count(kept_indices.size())


func _on_category_selected(category_id: String, score: int):
	quick_score.hide_options()
	GameState.record_score(category_id, score)


func _on_quick_score_selected(category_id: String, score: int):
	dice_manager.stop_all_breathing()
	_keep_all_dice()
	GameState.record_score(category_id, score)


func _on_quick_score_hovered(dice_indices: Array) -> void:
	dice_manager.stop_all_breathing()
	dice_manager.start_breathing(dice_indices)


func _on_quick_score_unhovered() -> void:
	dice_manager.stop_all_breathing()


func _on_restart_pressed():
	_start_game()


func _on_upgrade_pressed():
	upgrade_screen.show_upgrades()


func _on_upgrade_continue():
	_start_game()
