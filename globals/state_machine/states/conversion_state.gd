class_name ConversionState
extends GameStateBase

## 점수→거리/시간 치환 상태
## - Burst(0점): 선택 없이 즉시 PreRollState
## - 거리 환산: remaining_distance -= score × distance_factor (기본)
## - 시간 확보: remaining_time += score × time_factor

const TRANSITION_DELAY := 1.0  ## 차량 애니메이션 대기 (초)

var _final_score: int = 0
var _waiting_transition := false


func get_phase() -> GameState.Phase:
	return GameState.Phase.CONVERSION


func enter() -> void:
	super.enter()

	# 타이머 정지 (플레이어가 버튼을 누를 때까지 대기)
	GameState.set_timer_running(false)

	var pending := GameState.consume_pending_score()
	if not pending:
		_check_and_transition()
		return

	# Burst = 0점 → 선택 없이 즉시 다음으로
	if pending.hand_rank_id == "burst":
		_check_and_transition()
		return

	# 효과 데이터 적용
	game_root.dice_manager.apply_scoring_effects()

	# 점수 재계산 (효과 적용 후)
	var hand_rank = HandRankRegistry.get_hand_rank(pending.hand_rank_id)
	var score := Scoring.calculate_score(hand_rank, GameState.active_dice)

	# Hand Rank 배수 적용
	var upgrade := MetaState.get_upgrade(pending.hand_rank_id)
	if upgrade:
		score = int(score * upgrade.get_total_multiplier())

	# Double Down 배수 적용
	if GameState.is_double_down:
		score = int(score * GameState.DOUBLE_DOWN_MULTIPLIER)

	_final_score = score

	# ConversionUI 표시
	_connect_signals()
	game_root.conversion_ui.show_conversion(_final_score)


func exit() -> void:
	_waiting_transition = false
	_disconnect_signals()
	game_root.conversion_ui.hide_conversion()
	game_root.dice_manager.unhighlight_all()


func _connect_signals() -> void:
	game_root.conversion_ui.distance_selected.connect(_on_distance_selected)
	game_root.conversion_ui.time_selected.connect(_on_time_selected)


func _disconnect_signals() -> void:
	if game_root.conversion_ui.distance_selected.is_connected(_on_distance_selected):
		game_root.conversion_ui.distance_selected.disconnect(_on_distance_selected)
	if game_root.conversion_ui.time_selected.is_connected(_on_time_selected):
		game_root.conversion_ui.time_selected.disconnect(_on_time_selected)


func _on_distance_selected() -> void:
	if _waiting_transition:
		return
	GameState.convert_to_distance(_final_score)
	_delayed_transition()


func _on_time_selected() -> void:
	if _waiting_transition:
		return
	GameState.convert_to_time(_final_score)
	_delayed_transition()


func _delayed_transition() -> void:
	_waiting_transition = true
	_disconnect_signals()
	game_root.conversion_ui.hide_conversion()
	await game_root.get_tree().create_timer(TRANSITION_DELAY).timeout
	# 코루틴 안전 가드: await 중 상태가 바뀌었으면 중단
	if GameState.current_phase != GameState.Phase.CONVERSION:
		return
	_waiting_transition = false
	_check_and_transition()


func _check_and_transition() -> void:
	if GameState.is_game_won():
		transitioned.emit(self, "GameOverState")
	elif GameState.is_time_up():
		transitioned.emit(self, "GameOverState")
	else:
		transitioned.emit(self, "PreRollState")
