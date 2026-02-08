class_name RollingState
extends GameStateBase

## 물리 시뮬레이션 중 상태: 모든 입력 차단
## all_dice_finished 시그널 수신 시 PostRollState로 전환


func enter() -> void:
	GameState.current_phase = GameState.Phase.ROLLING
	GameState.phase_changed.emit(GameState.current_phase)

	# 시그널 연결
	game_root.dice_manager.all_dice_finished.connect(_on_all_dice_finished)


func exit() -> void:
	game_root.dice_manager.all_dice_finished.disconnect(_on_all_dice_finished)


func _on_all_dice_finished(_values: Array) -> void:
	# 항상 PostRollState로 전환 (점수 연출 표시)
	transitioned.emit(self, "PostRollState")


func handle_input(_event: InputEvent) -> bool:
	# 모든 입력 차단 (소비)
	return true
