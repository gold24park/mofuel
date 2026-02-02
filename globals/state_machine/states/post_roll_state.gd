class_name PostRollState
extends GameStateBase

## 굴린 후 상태: Keep/Reroll/Score 선택
## - Reroll: 선택한 주사위 다시 굴림 -> RollingState
## - Score: 점수 선택 -> ScoringState (또는 QuickScore로 바로 다음 라운드)


func enter() -> void:
	GameState.current_phase = GameState.Phase.POST_ROLL
	GameState.phase_changed.emit(GameState.current_phase)

	# UI 표시
	game_root.action_buttons.visible = true
	game_root.roll_button.visible = false

	# 리롤 불가 시 자동으로 스코어링 상태로 전환
	if not GameState.can_reroll():
		transitioned.emit(self, "ScoringState")
		return

	# Quick Score 패널 표시
	game_root.quick_score.show_options(GameState.active_dice)

	_connect_signals()


func exit() -> void:
	_disconnect_signals()
	game_root.action_buttons.visible = false
	game_root.quick_score.hide_options()
	game_root.dice_manager.stop_all_breathing()


func _connect_signals() -> void:
	game_root.action_buttons.reroll_pressed.connect(_on_reroll_pressed)
	game_root.action_buttons.end_turn_pressed.connect(_on_end_turn_pressed)
	game_root.dice_manager.selection_changed.connect(_on_selection_changed)
	game_root.quick_score.score_selected.connect(_on_quick_score_selected)
	game_root.quick_score.option_hovered.connect(_on_quick_score_hovered)
	game_root.quick_score.option_unhovered.connect(_on_quick_score_unhovered)


func _disconnect_signals() -> void:
	game_root.action_buttons.reroll_pressed.disconnect(_on_reroll_pressed)
	game_root.action_buttons.end_turn_pressed.disconnect(_on_end_turn_pressed)
	game_root.dice_manager.selection_changed.disconnect(_on_selection_changed)
	game_root.quick_score.score_selected.disconnect(_on_quick_score_selected)
	game_root.quick_score.option_hovered.disconnect(_on_quick_score_hovered)
	game_root.quick_score.option_unhovered.disconnect(_on_quick_score_unhovered)


#region Reroll
func _on_reroll_pressed() -> void:
	if game_root.dice_manager.get_selected_count() == 0:
		return
	if not GameState.can_reroll():
		return

	var indices: Array[int] = game_root.dice_manager.get_selected_indices()

	if GameState.reroll_dice(indices):
		for i in indices:
			game_root.dice_labels.hide_label(i)
		game_root.dice_manager.reroll_selected_radial_burst()
		transitioned.emit(self, "RollingState")
#endregion


#region Scoring
func _on_end_turn_pressed() -> void:
	transitioned.emit(self, "ScoringState")


func _on_quick_score_selected(category_id: String, score: int) -> void:
	game_root.dice_manager.stop_all_breathing()
	game_root._prev_active_dice = GameState.active_dice.duplicate()

	if GameState.record_score(category_id, score):
		_check_game_state_after_score()


func _check_game_state_after_score() -> void:
	if GameState.total_score >= GameState.target_score:
		transitioned.emit(self, "GameOverState")
	elif GameState.current_round >= GameState.max_rounds:
		transitioned.emit(self, "GameOverState")
	else:
		transitioned.emit(self, "PreRollState")
#endregion


#region Quick Score Hover
func _on_quick_score_hovered(dice_indices: Array) -> void:
	game_root.dice_manager.stop_all_breathing()
	game_root.dice_manager.start_breathing(dice_indices)


func _on_quick_score_unhovered() -> void:
	game_root.dice_manager.stop_all_breathing()
#endregion


func _on_selection_changed(indices: Array) -> void:
	game_root.action_buttons.set_selected_count(indices.size())
