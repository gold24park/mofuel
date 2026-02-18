class_name GameOverState
extends GameStateBase

## 게임 종료 상태: 승/패 결과 화면
## - Restart: SetupState로 전환
## - Upgrade: 업그레이드 화면 표시


func enter() -> void:
	GameState.current_phase = GameState.Phase.GAME_OVER
	GameState.phase_changed.emit(GameState.current_phase)

	# 승/패 판정
	var won := GameState.total_score >= GameState.target_score
	GameState.game_over.emit(won)

	_connect_signals()


func exit() -> void:
	_disconnect_signals()
	game_root.game_over_screen.visible = false


func _connect_signals() -> void:
	game_root.game_over_screen.restart_pressed.connect(_on_restart_pressed)
	game_root.game_over_screen.upgrade_pressed.connect(_on_upgrade_pressed)
	game_root.upgrade_screen.continue_pressed.connect(_on_upgrade_continue)
	game_root.game_over_screen.ornament_pressed.connect(_on_ornament_pressed)
	game_root.ornament_grid_ui.continue_pressed.connect(_on_ornament_continue)


func _disconnect_signals() -> void:
	game_root.game_over_screen.restart_pressed.disconnect(_on_restart_pressed)
	game_root.game_over_screen.upgrade_pressed.disconnect(_on_upgrade_pressed)
	game_root.upgrade_screen.continue_pressed.disconnect(_on_upgrade_continue)
	game_root.game_over_screen.ornament_pressed.disconnect(_on_ornament_pressed)
	game_root.ornament_grid_ui.continue_pressed.disconnect(_on_ornament_continue)


func _on_restart_pressed() -> void:
	transitioned.emit(self, "SetupState")


func _on_upgrade_pressed() -> void:
	game_root.upgrade_screen.show_upgrades()


func _on_upgrade_continue() -> void:
	transitioned.emit(self, "SetupState")


func _on_ornament_pressed() -> void:
	game_root.ornament_grid_ui.show_screen()


func _on_ornament_continue() -> void:
	game_root.game_over_screen.visible = true
