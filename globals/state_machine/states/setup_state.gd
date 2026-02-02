class_name SetupState
extends GameStateBase

## 게임 초기화 상태 (1회성)
## PreRollState로 전환하면서 첫 라운드 시작


func enter() -> void:
	GameState.current_phase = GameState.Phase.SETUP
	GameState.phase_changed.emit(GameState.current_phase)

	# current_round를 0으로 설정하여 PreRollState가 첫 라운드임을 알 수 있게 함
	GameState.current_round = 0

	transitioned.emit(self, "PreRollState")
