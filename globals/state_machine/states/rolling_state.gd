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


func _on_all_dice_finished(values: Array) -> void:
	# GameState에 결과 전달
	# GameState.on_dice_results(values)
	# 모든 주사위 라벨 표시
	for i in range(5):
		game_root.dice_labels.show_label(i)

	if GameState.can_reroll():
		# UI에 스코어링 옵션 표시 요청
		GameState.show_scoring_options.emit(GameState.active_dice)
		# PostRollState로 전환
		transitioned.emit(self , "PostRollState")
	else:
		# 게임 규칙: 리롤 불가 시 자동으로 스코어링 단계로 전환
		transitioned.emit(self , "ScoringState")


func handle_input(_event: InputEvent) -> bool:
	# 모든 입력 차단 (소비)
	return true
