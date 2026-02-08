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
	GameState.inventory.init_starting_inventory()
	GameState.deck.init_from_inventory(GameState.inventory)

	MetaState.reset_all_uses()
	GameState.deck.draw_initial_hand(GameState.DICE_COUNT)

	# 시그널 발생
	GameState.round_changed.emit(GameState.current_round)
	GameState.rerolls_changed.emit(GameState.rerolls_remaining)
	

	transitioned.emit(self , "PreRollState")
