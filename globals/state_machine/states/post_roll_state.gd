class_name PostRollState
extends GameStateBase

## 굴린 후 상태: Keep/Reroll/Score 선택
## - Reroll: 선택한 주사위 다시 굴림 -> RollingState
## - Score: 점수 선택 -> ScoringState (또는 QuickScore로 바로 다음 라운드)

func enter() -> void:
	_connect_signals()
	GameState.current_phase = GameState.Phase.POST_ROLL
	GameState.phase_changed.emit(GameState.current_phase)

	# 리롤 불가 시 자동으로 스코어링 상태로 전환
	if not GameState.can_reroll():
		transitioned.emit(self , "ScoringState")
		return

	# 스탯 준비 (숨김) → 애니메이션 중 타겟별 reveal → 나머지 표시
	var stats: Array[Dictionary] = game_root.dice_manager.get_score_effect_stats()
	game_root.dice_stats.prepare_stats(stats)
	GameState.is_transitioning = true
	await game_root.dice_manager.play_effects_animation(
		game_root.dice_stats.reveal_stat)
	game_root.dice_stats.reveal_all()
	GameState.is_transitioning = false

	# UI 표시 (연출 후) — RollButton이 phase_changed로 자동 표시됨
	game_root.quick_score.show_options(GameState.active_dice)


func exit() -> void:
	_disconnect_signals()
	game_root.dice_manager.stop_all_breathing()
	# dice_stats 라벨은 SCORING까지 유지 (scoring_state.exit에서 숨김)


func _connect_signals() -> void:
	game_root.roll_button.reroll_pressed.connect(_on_reroll_pressed)
	game_root.dice_manager.selection_changed.connect(_on_selection_changed)
	game_root.quick_score.score_selected.connect(_on_quick_score_selected)
	game_root.quick_score.option_hovered.connect(_on_quick_score_hovered)
	game_root.quick_score.option_unhovered.connect(_on_quick_score_unhovered)


func _disconnect_signals() -> void:
	game_root.roll_button.reroll_pressed.disconnect(_on_reroll_pressed)
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

	GameState.rerolls_remaining -= 1
	GameState.rerolls_changed.emit(GameState.rerolls_remaining)

	game_root.dice_stats.hide_all()
	game_root.dice_manager.reroll_selected_radial_burst()
	transitioned.emit(self , "RollingState")
#endregion


#region Scoring
func _on_quick_score_selected(category_id: String, score: int) -> void:
	GameState.set_pending_score(category_id, score)
	transitioned.emit(self , "ScoringState")
#endregion


func _on_selection_changed(indices: Array) -> void:
	game_root.roll_button.set_selected_count(indices.size())


func _on_quick_score_hovered(dice_indices: Array) -> void:
	game_root.dice_manager.unhighlight_all()
	game_root.dice_manager.highlight_dice(dice_indices)


func _on_quick_score_unhovered() -> void:
	game_root.dice_manager.unhighlight_all()
