class_name PostRollState
extends GameStateBase

## POST_ROLL 상태: ScoreDisplay 연출 후 Stand/Reroll/DoubleDown 선택
## - Stand: 최고 족보로 자동 점수 기록
## - Reroll: 선택한 주사위 리롤 → RollingState
## - Double Down: 리롤 2개 소모, 전체 리롤, ×2 배수

var _pattern_indices: Array[int] = [] ## 패턴 하이라이트 복원용


func enter() -> void:
	_connect_signals()
	GameState.current_phase = GameState.Phase.POST_ROLL
	GameState.phase_changed.emit(GameState.current_phase)

	# 최고 족보 확인 + ScoreDisplay 초기 표시 (base 점수 + 카테고리 배수)
	_pattern_indices = []
	var best := Scoring.get_best_category(GameState.active_dice)
	if not best.is_empty():
		var category = best["category"]
		var base := Scoring.get_score_breakdown(category, GameState.active_dice)["base"] as int
		var upgrade := MetaState.get_upgrade(category.id)
		var cat_mult := upgrade.get_total_multiplier() if upgrade else 1.0
		game_root.score_display.show_initial(category.display_name, base, cat_mult)

		# 패턴을 이루는 주사위 하이라이트 (윤곽선)
		_pattern_indices = Scoring.get_pattern_indices(category, GameState.active_dice)
		game_root.dice_manager.highlight_dice(_pattern_indices)

	# 족보 현황 패널 표시 (모든 유효 족보 + 최고 하이라이트)
	var all_scores := Scoring.calculate_all_scores(GameState.active_dice)
	var best_id: String = best["category_id"] if not best.is_empty() else ""
	game_root.category_breakdown.show_breakdown(all_scores, best_id)

	# 효과 1회 계산 + DiceStats 준비 (숨김) → 효과 애니메이션
	game_root.dice_manager.compute_effects()
	var stats: Array[Dictionary] = game_root.dice_manager.get_score_effect_stats()
	game_root.dice_stats.prepare_stats(stats)
	GameState.is_transitioning = true

	# 효과 애니메이션 — 각 효과 발동 시 DiceStats reveal + ScoreDisplay 증분 업데이트 + 쥬스
	await game_root.dice_manager.play_effects_animation(
		func(target_idx: int, bonus: int, mult: float):
			game_root.dice_stats.reveal_stat(target_idx, bonus, mult)
			if not best.is_empty():
				game_root.score_display.add_contribution(bonus, mult)
			# Juice: 플로팅 텍스트 + 히트 프리즈
			var die_pos: Vector3 = game_root.dice_manager.dice_nodes[target_idx].global_position
			if bonus != 0:
				var txt = "+%d" % bonus if bonus > 0 else str(bonus)
				game_root.juice_fx.floating_text(die_pos, txt,
					Color.GREEN if bonus > 0 else Color.RED)
			if mult > 1.0:
				game_root.juice_fx.floating_text(
					die_pos + Vector3(1.5, 0, 0), "x%.1f" % mult,
					Color(1.0, 0.85, 0.2))
			game_root.juice_fx.freeze(0.03, 0.1)
	)
	game_root.dice_stats.reveal_all()

	# 오너먼트 dice_effects 발동 하이라이트
	_highlight_ornament_effects()

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
	game_root.dice_manager.exit_spotlight_mode()
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
	game_root.dice_manager.exit_spotlight_mode()
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

	game_root.dice_manager.exit_spotlight_mode()
	GameState.rerolls_remaining -= 1
	GameState.rerolls_changed.emit(GameState.rerolls_remaining)

	game_root.dice_stats.hide_all()
	game_root.score_display.hide_display()
	game_root.dice_manager.reroll_spin_in_place()
	transitioned.emit(self, "RollingState")
#endregion


#region Double Down
func _on_double_down_pressed() -> void:
	if not GameState.can_double_down():
		return

	game_root.dice_manager.exit_spotlight_mode()
	GameState.rerolls_remaining -= GameState.DOUBLE_DOWN_COST
	GameState.rerolls_changed.emit(GameState.rerolls_remaining)
	GameState.is_double_down = true

	# Juice: 더블다운 강조
	game_root.juice_fx.shake(0.8)
	game_root.juice_fx.flash(Color(1.0, 0.3, 0.3), 0.5, 0.2)

	game_root.dice_stats.hide_all()
	game_root.score_display.hide_display()
	game_root.dice_manager.roll_dice_radial_burst()
	transitioned.emit(self, "RollingState")
#endregion


#region Ornament Highlight
func _highlight_ornament_effects() -> void:
	var active: Array[OrnamentInstance] = []
	for ornament in MetaState.ornament_grid.placed_ornaments:
		if not ornament.type.dice_effects.is_empty():
			active.append(ornament)
	if not active.is_empty():
		game_root.ornament_mini_grid.highlight_ornaments(active)
#endregion


func _on_selection_changed(indices: Array) -> void:
	game_root.action_bar.update_state(indices.size())

	if indices.size() > 0:
		if not game_root.dice_manager.is_spotlight_active():
			game_root.dice_manager.enter_spotlight_mode()
		else:
			game_root.dice_manager.update_spotlights()
	else:
		game_root.dice_manager.exit_spotlight_mode()
		# 패턴 하이라이트 복원
		if not _pattern_indices.is_empty():
			game_root.dice_manager.highlight_dice(_pattern_indices)
