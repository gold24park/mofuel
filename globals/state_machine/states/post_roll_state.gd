class_name PostRollState
extends GameStateBase

## POST_ROLL 상태: ScoreDisplay 연출 후 Stand/Reroll/DoubleDown 선택
## - Stand: 최고 족보로 자동 점수 기록
## - Reroll: 선택한 주사위 리롤 → RollingState
## - Double Down: 리롤 2개 소모, 전체 리롤, ×2 배수


func enter() -> void:
	_connect_signals()
	GameState.current_phase = GameState.Phase.POST_ROLL
	GameState.phase_changed.emit(GameState.current_phase)

	# 최고 족보 확인 + ScoreDisplay 초기 표시 (base 점수 + 카테고리 배수)
	var best := Scoring.get_best_category(GameState.active_dice)
	if not best.is_empty():
		var category = best["category"]
		var base := Scoring.get_score_breakdown(category, GameState.active_dice)["base"] as int
		var upgrade := MetaState.get_upgrade(category.id)
		var cat_mult := upgrade.get_total_multiplier() if upgrade else 1.0
		game_root.score_display.show_initial(category.display_name, base, cat_mult)

		# 패턴을 이루는 주사위 하이라이트 (윤곽선)
		var pattern_indices := Scoring.get_pattern_indices(category, GameState.active_dice)
		game_root.dice_manager.highlight_dice(pattern_indices)

	# 족보 현황 패널 표시 (모든 유효 족보 + 최고 하이라이트)
	var all_scores := Scoring.calculate_all_scores(GameState.active_dice)
	var best_id: String = best["category_id"] if not best.is_empty() else ""
	game_root.category_breakdown.show_breakdown(all_scores, best_id)

	# DiceStats 준비 (숨김) → 효과 애니메이션
	var stats: Array[Dictionary] = game_root.dice_manager.get_score_effect_stats()
	game_root.dice_stats.prepare_stats(stats)
	GameState.is_transitioning = true

	# 효과 애니메이션 — 각 효과 발동 시 DiceStats reveal + ScoreDisplay 증분 업데이트
	await game_root.dice_manager.play_effects_animation(
		func(target_idx: int, bonus: int, mult: float):
			game_root.dice_stats.reveal_stat(target_idx, bonus, mult)
			if not best.is_empty():
				game_root.score_display.add_contribution(bonus, mult)
	)
	game_root.dice_stats.reveal_all()

	# 최종 점수 라인 표시 (또는 Burst)
	if best.is_empty():
		await game_root.score_display.show_no_score()
	else:
		await game_root.score_display.show_final(GameState.is_double_down)

	GameState.is_transitioning = false

	# 리롤 불가 시 자동 Stand (점수 연출만 보여주고 종료)
	if not GameState.can_reroll():
		_do_stand()
		return

	# ActionBar 표시
	game_root.action_bar.show_bar()


func exit() -> void:
	_disconnect_signals()
	game_root.dice_manager.stop_all_breathing()
	game_root.dice_manager.unhighlight_all()
	game_root.action_bar.hide_bar()
	game_root.category_breakdown.hide_breakdown()
	# dice_stats 라벨은 SCORING까지 유지 (scoring_state.exit에서 숨김)


func _connect_signals() -> void:
	game_root.action_bar.stand_pressed.connect(_on_stand_pressed)
	game_root.action_bar.reroll_pressed.connect(_on_reroll_pressed)
	game_root.action_bar.double_down_pressed.connect(_on_double_down_pressed)
	game_root.dice_manager.selection_changed.connect(_on_selection_changed)


func _disconnect_signals() -> void:
	game_root.action_bar.stand_pressed.disconnect(_on_stand_pressed)
	game_root.action_bar.reroll_pressed.disconnect(_on_reroll_pressed)
	game_root.action_bar.double_down_pressed.disconnect(_on_double_down_pressed)
	game_root.dice_manager.selection_changed.disconnect(_on_selection_changed)


#region Stand
func _on_stand_pressed() -> void:
	_do_stand()


func _do_stand() -> void:
	var best := Scoring.get_best_category(GameState.active_dice)
	if best.is_empty():
		GameState.set_pending_score("burst", 0)
	else:
		GameState.set_pending_score(best["category_id"], best["score"])
	game_root.score_display.hide_display()
	transitioned.emit(self, "ScoringState")
#endregion


#region Reroll
func _on_reroll_pressed() -> void:
	if game_root.dice_manager.get_selected_count() == 0:
		return
	if not GameState.can_reroll():
		return

	GameState.rerolls_remaining -= 1
	GameState.rerolls_changed.emit(GameState.rerolls_remaining)

	game_root.dice_stats.hide_all()
	game_root.score_display.hide_display()
	game_root.dice_manager.reroll_selected_radial_burst()
	transitioned.emit(self, "RollingState")
#endregion


#region Double Down
func _on_double_down_pressed() -> void:
	if not GameState.can_double_down():
		return

	GameState.rerolls_remaining -= GameState.DOUBLE_DOWN_COST
	GameState.rerolls_changed.emit(GameState.rerolls_remaining)
	GameState.is_double_down = true

	game_root.dice_stats.hide_all()
	game_root.score_display.hide_display()
	game_root.dice_manager.roll_dice_radial_burst()
	transitioned.emit(self, "RollingState")
#endregion


func _on_selection_changed(indices: Array) -> void:
	game_root.action_bar.update_state(indices.size())
