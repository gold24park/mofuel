class_name PostRollState
extends GameStateBase

## POST_ROLL 상태: ScoreDisplay 연출 후 Nitro/Smoke/Reroll 선택
## - Nitro: 점수 → 거리 환산 (즉시)
## - Smoke: 점수 → 시간 확보 (즉시)
## - Reroll: 리롤 모드 진입 (낙장불입) → 주사위 선택 → Roll/Double Down

const TRANSITION_DELAY := 1.0  ## 치환 후 차량 애니메이션 대기 (초)

var _pattern_indices: Array[int] = [] ## 패턴 하이라이트 복원용
var _reroll_mode: bool = false
var _final_score: int = 0 ## 계산된 최종 점수 (Nitro/Smoke용)
var _final_hand_rank_id: String = "" ## 최고 족보 ID


func get_phase() -> GameState.Phase:
	return GameState.Phase.POST_ROLL


func enter() -> void:
	super.enter()
	_reroll_mode = false
	_final_score = 0
	_final_hand_rank_id = ""
	_connect_signals()

	# 주사위 선택 비활성화 (리롤 모드 진입 전까지)
	game_root.dice_manager.set_selection_enabled(false)

	# 타이머 정지 (점수 애니메이션 중에는 시간이 흐르지 않는다 — ActionBar 표시 후 시작)
	GameState.set_timer_running(false)

	# 이전 라운드 하이라이트 잔존 방지 (방어적 클리어)
	game_root.dice_manager.unhighlight_all()

	# 최고 족보 확인 + ScoreDisplay 초기 표시 (base 점수 + Hand Rank 배수)
	_pattern_indices = []
	var best := Scoring.get_best_hand_rank(GameState.active_dice)
	if not best.is_empty():
		var hand_rank = best["hand_rank"]
		var base := Scoring.get_score_breakdown(hand_rank, GameState.active_dice)["base"] as int
		var upgrade := MetaState.get_upgrade(hand_rank.id)
		var hr_mult := upgrade.get_total_multiplier() if upgrade else 1.0
		game_root.score_display.show_initial(hand_rank.display_name, base, hr_mult)

		# 패턴을 이루는 주사위 하이라이트 (윤곽선)
		_pattern_indices = Scoring.get_pattern_indices(hand_rank, GameState.active_dice)
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

	# 코루틴 안전 가드: await 동안 상태가 바뀌었으면 중단
	if GameState.current_phase != GameState.Phase.POST_ROLL:
		return

	# 기어 dice_effects 발동 하이라이트
	_highlight_gear_effects()

	# 최종 점수 라인 표시 (또는 Burst)
	if best.is_empty():
		await game_root.score_display.show_no_score()
	else:
		await game_root.score_display.show_final(GameState.is_double_down)

	# 코루틴 안전 가드: 두 번째 await 후에도 체크
	if GameState.current_phase != GameState.Phase.POST_ROLL:
		return

	GameState.is_transitioning = false

	# 최종 점수 계산 (Nitro/Smoke 미리보기 + 즉시 치환용)
	_compute_final_score(best)

	# 더블다운 후에는 무조건 거리 환산 (올인 결정 — 추가 선택 없음)
	if GameState.is_double_down:
		_do_conversion(true)
		return

	# 점수 연출 완료 → 타이머 시작 전 시간 초과 체크 (BUG-2 방지)
	if GameState.is_time_up():
		_do_time_expired()
		return

	# 타이머 시작 (플레이어 선택 시간)
	GameState.set_timer_running(true)

	# ActionBar 표시 (미리보기 수치 포함)
	game_root.action_bar.set_score_preview(_final_score)
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
	game_root.action_bar.nitro_pressed.connect(_on_nitro_pressed)
	game_root.action_bar.smoke_pressed.connect(_on_smoke_pressed)
	game_root.action_bar.reroll_pressed.connect(_on_reroll_pressed)
	game_root.action_bar.reroll_confirmed.connect(_on_reroll_confirmed)
	game_root.action_bar.double_down_pressed.connect(_on_double_down_pressed)
	game_root.dice_manager.selection_changed.connect(_on_selection_changed)
	GameState.time_changed.connect(_on_time_changed)


func _disconnect_signals() -> void:
	game_root.action_bar.nitro_pressed.disconnect(_on_nitro_pressed)
	game_root.action_bar.smoke_pressed.disconnect(_on_smoke_pressed)
	game_root.action_bar.reroll_pressed.disconnect(_on_reroll_pressed)
	game_root.action_bar.reroll_confirmed.disconnect(_on_reroll_confirmed)
	game_root.action_bar.double_down_pressed.disconnect(_on_double_down_pressed)
	game_root.dice_manager.selection_changed.disconnect(_on_selection_changed)
	GameState.time_changed.disconnect(_on_time_changed)


#region Score Calculation
## 최종 점수 계산 — 효과 적용 + Hand Rank 배수 + Double Down 배수
func _compute_final_score(best: Dictionary) -> void:
	if best.is_empty():
		_final_score = 0
		_final_hand_rank_id = Scoring.BURST_ID
		return

	_final_hand_rank_id = best["hand_rank_id"] as String
	var hand_rank = best["hand_rank"]

	# 효과 데이터 적용
	game_root.dice_manager.apply_scoring_effects()

	# 점수 재계산 (효과 적용 후)
	var score := Scoring.calculate_score(hand_rank, GameState.active_dice)

	# Hand Rank 배수 적용
	var upgrade := MetaState.get_upgrade(_final_hand_rank_id)
	if upgrade:
		score = int(score * upgrade.get_total_multiplier())

	# Double Down 배수 적용
	if GameState.is_double_down:
		score = int(score * GameState.DOUBLE_DOWN_MULTIPLIER)

	_final_score = score
#endregion


#region Timer Expiry
func _on_time_changed(time: float) -> void:
	if time <= 0 and not _reroll_mode:
		_do_time_expired()


func _do_time_expired() -> void:
	game_root.score_display.hide_display()
	game_root.dice_manager.exit_spotlight_mode()
	transitioned.emit(self, "GameOverState")
#endregion


#region Nitro / Smoke (점수 치환)
func _on_nitro_pressed() -> void:
	_do_conversion(true)


func _on_smoke_pressed() -> void:
	_do_conversion(false)


func _do_conversion(is_distance: bool) -> void:
	GameState.set_timer_running(false)
	game_root.dice_manager.exit_spotlight_mode()
	game_root.score_display.hide_display()
	game_root.action_bar.hide_bar()

	if _final_score > 0:
		if is_distance:
			GameState.convert_to_distance(_final_score)
		else:
			GameState.convert_to_time(_final_score)

	await _delayed_check_and_transition()
#endregion


#region Transition Helper
func _delayed_check_and_transition() -> void:
	await game_root.get_tree().create_timer(TRANSITION_DELAY).timeout
	# 코루틴 안전 가드
	if GameState.current_phase != GameState.Phase.POST_ROLL:
		return
	_check_and_transition()


func _check_and_transition() -> void:
	if GameState.is_game_won():
		transitioned.emit(self, "GameOverState")
	elif GameState.is_time_up():
		transitioned.emit(self, "GameOverState")
	else:
		transitioned.emit(self, "PreRollState")
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


#region Gear Highlight
func _highlight_gear_effects() -> void:
	_highlight_gears(func(g: GearInstance) -> bool:
		return not g.type.dice_effects.is_empty())
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
