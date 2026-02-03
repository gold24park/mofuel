class_name SetupState
extends GameStateBase

## 게임 초기화 상태 (1회성)
## PreRollState로 전환하면서 첫 라운드 시작


func enter() -> void:
	GameState.current_phase = GameState.Phase.SETUP
	GameState.phase_changed.emit(GameState.current_phase)

	# 게임 상태 초기화
	GameState.current_round = 0
	GameState.total_score = 0
	GameState.inventory_manager.init_starting_deck()
	
	MetaState.reset_all_uses()
	GameState.inventory_manager.draw_initial_hand(6)

	# 시그널 발생
	GameState.round_changed.emit(GameState.current_round)
	GameState.rerolls_changed.emit(GameState.rerolls_remaining)
	

	transitioned.emit(self , "PreRollState")
