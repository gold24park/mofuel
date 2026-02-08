class_name ScoringState
extends GameStateBase

## 스코어링 상태: PostRollState에서 전달받은 점수를 기록
## QuickScore 제거 — PendingScore를 소비하여 자동 처리


func enter() -> void:
	GameState.current_phase = GameState.Phase.SCORING
	GameState.phase_changed.emit(GameState.current_phase)

	var pending := GameState.consume_pending_score()
	if pending:
		_process_scoring(pending.category_id, pending.score)


func exit() -> void:
	game_root.dice_manager.unhighlight_all()
	game_root.dice_stats.hide_all()


func _process_scoring(category_id: String, _estimated_score: int) -> void:
	GameState.is_transitioning = true

	# Burst = 0점 스킵 (효과 계산 불필요)
	if category_id == "burst":
		GameState.record_score("burst", 0)
		_check_game_state_after_score()
		GameState.is_transitioning = false
		return

	# 효과 데이터 적용
	game_root.dice_manager.apply_scoring_effects()

	# 점수 재계산 (효과 적용 후)
	var category = CategoryRegistry.get_category(category_id)
	var final_score = Scoring.calculate_score(category, GameState.active_dice)

	if GameState.record_score(category_id, final_score):
		_check_game_state_after_score()

	GameState.is_transitioning = false


func _check_game_state_after_score() -> void:
	if GameState.is_game_over():
		transitioned.emit(self, "GameOverState")
	else:
		transitioned.emit(self, "PreRollState")
