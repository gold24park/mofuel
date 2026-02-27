class_name SetupState
extends GameStateBase

## 게임 초기화 상태 (1회성)
## 타이머/거리/리소스 초기화 후 PreRollState로 전환


func enter() -> void:
	GameState.current_phase = GameState.Phase.SETUP
	GameState.phase_changed.emit(GameState.current_phase)

	# 게임 상태 초기화
	GameState.remaining_time = GameState.BASE_TIME
	GameState.remaining_distance = GameState.target_distance
	GameState.timer_running = false
	GameState.rerolls_remaining = GameState.MAX_REROLLS
	GameState.redraws_remaining = GameState.MAX_REDRAWS
	GameState.is_double_down = false
	GameState.draws_remaining = 1

	GameState.inventory.init_starting_inventory()
	GameState.deck.init_from_inventory(GameState.inventory)

	GameState.deck.draw_initial_hand(GameState.HAND_DRAW_COUNT)

	# 시그널 발생
	GameState.time_changed.emit(GameState.remaining_time)
	GameState.distance_changed.emit(GameState.remaining_distance)
	GameState.rerolls_changed.emit(GameState.rerolls_remaining)
	GameState.redraws_changed.emit(GameState.redraws_remaining)

	transitioned.emit(self, "PreRollState")
