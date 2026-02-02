class_name ScoringState
extends GameStateBase

## 스코어링 상태: ScoreCard에서 카테고리 선택
## - 점수 선택 후 다음 라운드(PreRollState) 또는 게임 종료(GameOverState)로 전환


func enter() -> void:
	GameState.current_phase = GameState.Phase.SCORING
	GameState.phase_changed.emit(GameState.current_phase)

	game_root.quick_score.show_options(GameState.active_dice)

	_connect_signals()


func exit() -> void:
	game_root.quick_score.hide_options()
	game_root.dice_manager.stop_all_breathing()
	_disconnect_signals()


func _connect_signals() -> void:
	game_root.score_card.category_selected.connect(_on_category_selected)
	game_root.quick_score.score_selected.connect(_on_quick_score_selected)
	game_root.quick_score.option_hovered.connect(_on_quick_score_hovered)
	game_root.quick_score.option_unhovered.connect(_on_quick_score_unhovered)


func _disconnect_signals() -> void:
	game_root.score_card.category_selected.disconnect(_on_category_selected)
	game_root.quick_score.score_selected.disconnect(_on_quick_score_selected)
	game_root.quick_score.option_hovered.disconnect(_on_quick_score_hovered)
	game_root.quick_score.option_unhovered.disconnect(_on_quick_score_unhovered)


func _on_category_selected(category_id: String, score: int) -> void:
	_process_scoring(category_id, score)


func _on_quick_score_selected(category_id: String, score: int) -> void:
	_process_scoring(category_id, score)


func _process_scoring(category_id: String, score: int) -> void:
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


func _on_quick_score_hovered(dice_indices: Array) -> void:
	game_root.dice_manager.stop_all_breathing()
	game_root.dice_manager.start_breathing(dice_indices)


func _on_quick_score_unhovered() -> void:
	game_root.dice_manager.stop_all_breathing()
