class_name PreRollState
extends GameStateBase

## PRE_ROLL 상태 (타이머 진행 — 플레이어 선택 시간)
## - 기본: Hand에서 주사위 클릭 → Active로 이동
## - Hand == 5 & Active == 0 → 자동 활성화 (순차 애니메이션)
## - Draw 버튼: deck pool에서 hand로 드로우
## - Redraw 버튼: Hand 전체 교체 (게임당 2회)

var _is_animating: bool = false
var _prev_active: Array[DiceInstance] = [] ## 이전 활성 주사위 (자동 복원용)


func get_phase() -> GameState.Phase:
	return GameState.Phase.PRE_ROLL


func enter() -> void:
	super.enter()
	_connect_signals()

	# 타이머 정지 (PRE_ROLL은 준비 시간 — 주사위 선택 중에는 시간이 흐르지 않는다)
	GameState.set_timer_running(false)

	# Double Down 리셋 (매 롤마다)
	GameState.is_double_down = false

	# 기어 패시브 효과 적용 (게임 시작 후 첫 진입 시에만)
	# SetupState 직후에만 true (SetupState가 Phase.SETUP → PreRollState 전환)
	var is_new_game := GameState.active_dice.size() == 0 and _prev_active.is_empty()
	if is_new_game:
		_apply_gear_passives()

	GameState.rerolls_changed.emit(GameState.rerolls_remaining)
	GameState.draws_changed.emit(GameState.draws_remaining)

	_is_animating = false

	# 라운드 전환
	_play_round_transition()


func exit() -> void:
	_disconnect_signals()
	game_root.roll_button.visible = false


func _connect_signals() -> void:
	game_root.roll_button.roll_pressed.connect(_on_roll_pressed)
	game_root.hand_display.dice_clicked.connect(_on_hand_dice_clicked)
	game_root.dice_manager.active_dice_clicked.connect(_on_active_dice_clicked)
	game_root.hand_display.draw_pressed.connect(_on_draw_pressed)


func _disconnect_signals() -> void:
	game_root.roll_button.roll_pressed.disconnect(_on_roll_pressed)
	game_root.hand_display.dice_clicked.disconnect(_on_hand_dice_clicked)
	game_root.dice_manager.active_dice_clicked.disconnect(_on_active_dice_clicked)
	game_root.hand_display.draw_pressed.disconnect(_on_draw_pressed)


#region Round Transition Animation
func _play_round_transition() -> void:
	GameState.is_transitioning = true

	# 첫 진입 vs 이후 진입 판단: active가 비어있고 hand가 있으면 첫 진입
	if GameState.active_dice.size() == 0 and GameState.deck.hand.size() > 0:
		game_root.dice_manager.set_dice_to_hand_position()
	else:
		_prev_active = GameState.active_dice.duplicate()
		GameState.deck.return_active_to_hand()
		game_root.dice_manager.set_dice_to_hand_position()

	game_root.dice_manager.reset_state()
	GameState.is_transitioning = false

	game_root.roll_button.visible = true
	_update_draw_ui()
	_try_auto_activate()
#endregion


#region 자동 활성화 (공통 체크)
## Hand == 5 → 전부 활성화
## Hand > 5 & 이전 주사위 존재 → 이전 주사위 자동 활성화
func _try_auto_activate() -> void:
	if _is_animating:
		return
	if GameState.active_dice.size() != 0:
		return

	var hand := GameState.deck.hand
	var indices: Array[int] = []

	if hand.size() == GameState.DICE_COUNT:
		# 정확히 5개 — 전부 활성화
		indices.assign(range(GameState.DICE_COUNT))
	elif hand.size() > GameState.DICE_COUNT and not _prev_active.is_empty():
		# 6개 이상 — 이전 주사위 우선 활성화
		for prev_dice in _prev_active:
			var idx := hand.find(prev_dice)
			if idx >= 0 and idx not in indices:
				indices.append(idx)
		_prev_active.clear()
		if indices.size() != GameState.DICE_COUNT:
			return # 이전 주사위를 다 찾지 못하면 수동 선택
	else:
		return

	GameState.deck.move_hand_to_active(indices)

	game_root._sync_dice_instances()
	game_root.dice_manager.set_dice_to_hand_position()

	_is_animating = true
	for i in GameState.DICE_COUNT:
		# 코루틴 안전 가드: await 중 상태 전환되었으면 중단
		if GameState.current_phase != GameState.Phase.PRE_ROLL:
			_is_animating = false
			return
		game_root.dice_manager.animate_single_to_active(i, GameState.DICE_COUNT)
		await game_root.get_tree().create_timer(0.08).timeout
	_is_animating = false

	game_root.roll_button.visible = true
	_update_draw_ui()


func _update_draw_ui() -> void:
	game_root.hand_display.set_draw_enabled(GameState.can_draw())
#endregion


#region Hand → Active 클릭 처리
func _on_hand_dice_clicked(hand_index: int) -> void:
	if _is_animating or GameState.is_transitioning:
		return

	var active_index := GameState.move_single_to_active(hand_index)
	if active_index == -1:
		return

	_is_animating = true
	game_root._sync_dice_instances()
	await game_root.dice_manager.animate_single_to_active(active_index, GameState.active_dice.size())
	_is_animating = false
#endregion


#region Active → Hand 클릭 처리
func _on_active_dice_clicked(active_index: int) -> void:
	if _is_animating or GameState.is_transitioning:
		return
	if active_index < 0 or active_index >= GameState.active_dice.size():
		return

	GameState.move_single_to_hand(active_index)
	# animate_remove가 dice_nodes를 재정렬하므로 sync는 그 뒤에
	game_root.dice_manager.animate_remove_from_active(active_index, GameState.active_dice.size())
	game_root._sync_dice_instances()
#endregion


#region 수동 드로우
func _on_draw_pressed() -> void:
	if _is_animating or GameState.is_transitioning:
		return

	if not GameState.draw_one():
		return

	_is_animating = true
	var target_pos = game_root.hand_display.get_global_rect().get_center()
	await game_root.inventory_deck.animate_draw(target_pos)
	_is_animating = false

	_update_draw_ui()
	_try_auto_activate()
#endregion


#region Roll
func _on_roll_pressed() -> void:
	if _is_animating or GameState.is_transitioning:
		return
	if GameState.active_dice.size() != GameState.DICE_COUNT:
		return
	game_root.dice_manager.roll_dice_spin_all()
	transitioned.emit(self, "RollingState")
#endregion


#region Gear Passives
func _apply_gear_passives() -> void:
	for effect in MetaState.gear_grid.get_all_passive_effects():
		match effect["type"]:
			"reroll_bonus":
				GameState.rerolls_remaining += int(effect["delta"])
			"draw_bonus":
				GameState.draws_remaining += int(effect["delta"])

	# 패시브 보유 기어 하이라이트
	_highlight_gears(func(g: GearInstance) -> bool:
		return not g.type.passive_effects.is_empty())
#endregion
