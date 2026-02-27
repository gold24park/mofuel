class_name PostRollState
extends GameStateBase

## POST_ROLL 상태: ScoreDisplay 연출 후 Stand/Reroll/DoubleDown 선택
## - Stand: 최고 족보로 점수 확정 → ConversionState
## - Reroll: 리롤 모드 진입 (낙장불입) → 주사위 선택 → Roll 확정 → RollingState
## - Double Down: 리롤 2개 소모, 전체 리롤, ×2 배수

var _pattern_indices: Array[int] = [] ## 패턴 하이라이트 복원용
var _reroll_mode: bool = false


func enter() -> void:
	_reroll_mode = false
	_connect_signals()
	GameState.current_phase = GameState.Phase.POST_ROLL
	GameState.phase_changed.emit(GameState.current_phase)

	# 주사위 선택 비활성화 (리롤 모드 진입 전까지)
	game_root.dice_manager.set_selection_enabled(false)

	# 타이머 정지 (점수 애니메이션 중에는 시간이 흐르지 않는다 — ActionBar 표시 후 시작)
	GameState.set_timer_running(false)

	# 이전 라운드 하이라이트 잔존 방지 (방어적 클리어)
	game_root.dice_manager.unhighlight_all()

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

	# 효과 1회 계산 → 효과 애니메이션
	game_root.dice_manager.compute_effects()
	GameState.is_transitioning = true

	# 효과 애니메이션 — ScoreDisplay 증분 업데이트 + 쥬스
	await game_root.dice_manager.play_effects_animation(
		func(target_idx: int, bonus: int, mult: float):
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

	# 오너먼트 dice_effects 발동 하이라이트
	_highlight_ornament_effects()

	# 최종 점수 라인 표시 (또는 Burst)
	if best.is_empty():
		await game_root.score_display.show_no_score()
	else:
		await game_root.score_display.show_final(GameState.is_double_down)

	GameState.is_transitioning = false

	# 더블다운 후에는 무조건 Stand (올인 결정 — 추가 선택 없음)
	if GameState.is_double_down:
		_do_stand()
		return

	# 점수 연출 완료 → 타이머 시작 전 시간 초과 체크 (BUG-2 방지)
	# remaining_time ≈ 0 상태에서 POST_ROLL 진입 시, await 후 이미 만료될 수 있음
	if GameState.is_time_up():
		_do_time_expired()
		return

	# 타이머 시작 (플레이어 선택 시간)
	# 리롤 불가 시에도 Stand 버튼을 눌러야 넘어감 (타이머 긴장감 유지)
	GameState.set_timer_running(true)

	# ActionBar 표시 (리롤 불가 시 Reroll/DD 비활성, Stand만 활성)
	game_root.action_bar.show_bar()


func exit() -> void:
	_reroll_mode = false
	_disconnect_signals()
	game_root.dice_manager.set_selection_enabled(false)
	game_root.dice_manager.exit_spotlight_mode()
	game_root.dice_manager.stop_all_breathing()
	game_root.dice_manager.unhighlight_all()
	game_root.action_bar.hide_bar()


func _connect_signals() -> void:
	game_root.action_bar.stand_pressed.connect(_on_stand_pressed)
	game_root.action_bar.reroll_pressed.connect(_on_reroll_pressed)
	game_root.action_bar.reroll_confirmed.connect(_on_reroll_confirmed)
	game_root.action_bar.double_down_pressed.connect(_on_double_down_pressed)
	game_root.dice_manager.selection_changed.connect(_on_selection_changed)
	GameState.time_changed.connect(_on_time_changed)


func _disconnect_signals() -> void:
	game_root.action_bar.stand_pressed.disconnect(_on_stand_pressed)
	game_root.action_bar.reroll_pressed.disconnect(_on_reroll_pressed)
	game_root.action_bar.reroll_confirmed.disconnect(_on_reroll_confirmed)
	game_root.action_bar.double_down_pressed.disconnect(_on_double_down_pressed)
	game_root.dice_manager.selection_changed.disconnect(_on_selection_changed)
	GameState.time_changed.disconnect(_on_time_changed)


#region Timer Expiry
func _on_time_changed(time: float) -> void:
	if time <= 0 and not _reroll_mode:
		_do_time_expired()


func _do_time_expired() -> void:
	game_root.score_display.hide_display()
	game_root.dice_manager.exit_spotlight_mode()
	# 시간 초과 → 점수 없이 직접 GameOverState로 (ConversionState 우회)
	GameState.set_pending_score("burst", 0)
	transitioned.emit(self, "GameOverState")
#endregion


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
	transitioned.emit(self, "ConversionState")
#endregion


#region Reroll (낙장불입 — 취소 불가)
func _on_reroll_pressed() -> void:
	if not GameState.can_reroll():
		return

	# 리롤 모드 진입: 타이머 정지, 주사위 선택 활성화
	_reroll_mode = true
	GameState.set_timer_running(false)
	game_root.dice_manager.set_selection_enabled(true)
	game_root.action_bar.enter_reroll_mode()


func _on_reroll_confirmed() -> void:
	if not _reroll_mode:
		return
	if game_root.dice_manager.get_selected_count() == 0:
		return
	if not GameState.can_reroll():
		return

	_reroll_mode = false
	# NOTE: set_selection_enabled(false) / exit_spotlight_mode()를 여기서 호출하면
	# _selected_indices가 비워져 reroll_spin_in_place()가 빈 배열을 읽는 버그 발생.
	# 둘 다 reroll_spin_in_place() 내부의 _reset_state()에서 처리됨.
	GameState.rerolls_remaining -= 1
	GameState.rerolls_changed.emit(GameState.rerolls_remaining)

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

	game_root.score_display.hide_display()
	game_root.dice_manager.roll_dice_spin_all()
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
