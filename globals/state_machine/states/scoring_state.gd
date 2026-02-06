class_name ScoringState
extends GameStateBase

## 스코어링 상태: ScoreCard에서 카테고리 선택
## - 점수 선택 후 다음 라운드(PreRollState) 또는 게임 종료(GameOverState)로 전환


func enter() -> void:
	_connect_signals()
	GameState.current_phase = GameState.Phase.SCORING
	GameState.phase_changed.emit(GameState.current_phase)

	# PostRollState에서 Quick Score로 전환된 경우 자동 처리
	var pending := GameState.consume_pending_score()
	if pending:
		game_root._prev_active_dice = GameState.active_dice.duplicate()
		_process_scoring(pending.category_id, pending.score)
		return

	# 일반 ScoringState 진입 (End Turn 버튼으로 진입)
	game_root.quick_score.show_options(GameState.active_dice)


func exit() -> void:
	_disconnect_signals()
	game_root.quick_score.hide_options()
	game_root.dice_manager.unhighlight_all()
	game_root.dice_stats.hide_all()
	

func _connect_signals() -> void:
	game_root.quick_score.score_selected.connect(_on_quick_score_selected)
	game_root.quick_score.option_hovered.connect(_on_quick_score_hovered)
	game_root.quick_score.option_unhovered.connect(_on_quick_score_unhovered)


func _disconnect_signals() -> void:
	game_root.quick_score.score_selected.disconnect(_on_quick_score_selected)
	game_root.quick_score.option_hovered.disconnect(_on_quick_score_hovered)
	game_root.quick_score.option_unhovered.disconnect(_on_quick_score_unhovered)


func _on_quick_score_selected(category_id: String, score: int) -> void:
	_process_scoring(category_id, score)


func _process_scoring(category_id: String, _estimated_score: int) -> void:
	# 1. UI 잠금 (중복 클릭 방지)
	GameState.is_transitioning = true
	game_root.quick_score.hide_options()

	game_root._prev_active_dice = GameState.active_dice.duplicate()

	# Burst = 0점 스킵 (효과 계산 불필요)
	if category_id == "burst":
		GameState.record_score("burst", 0)
		_check_game_state_after_score()
		GameState.is_transitioning = false
		return

	# 2. 효과 데이터 적용 (애니메이션은 POST_ROLL에서 완료)
	game_root.dice_manager.apply_scoring_effects()

	# 3. 점수 재계산 (효과 적용 후)
	var category = CategoryRegistry.get_category(category_id)
	var final_score = Scoring.calculate_score(category, GameState.active_dice)

	if GameState.record_score(category_id, final_score):
		_check_game_state_after_score()

	GameState.is_transitioning = false


func _check_game_state_after_score() -> void:
	if GameState.is_game_over():
		transitioned.emit(self , "GameOverState")
	else:
		transitioned.emit(self , "PreRollState")


func _on_quick_score_hovered(dice_indices: Array) -> void:
	game_root.dice_manager.unhighlight_all()
	game_root.dice_manager.highlight_dice(dice_indices)


func _on_quick_score_unhovered() -> void:
	game_root.dice_manager.unhighlight_all()
