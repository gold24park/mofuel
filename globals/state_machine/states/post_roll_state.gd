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

	# 효과 애니메이션 + DiceStats reveal
	var stats: Array[Dictionary] = game_root.dice_manager.get_score_effect_stats()
	game_root.dice_stats.prepare_stats(stats)
	GameState.is_transitioning = true
	await game_root.dice_manager.play_effects_animation(
		game_root.dice_stats.reveal_stat)
	game_root.dice_stats.reveal_all()

	# ScoreDisplay 순차 카운팅 애니메이션
	var best := Scoring.get_best_category(GameState.active_dice)
	if best.is_empty():
		await game_root.score_display.show_no_score()
	else:
		var breakdown := Scoring.get_score_breakdown(
			best["category"], GameState.active_dice)
		await game_root.score_display.show_score(breakdown, GameState.is_double_down)

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
	game_root.action_bar.hide_bar()
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
		# 유효 족보 없으면 0점 (burst)
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
