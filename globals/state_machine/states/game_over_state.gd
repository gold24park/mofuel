class_name GameOverState
extends GameStateBase

## 게임 종료 상태: 도주 성공(Escaped) / 체포(Busted)
## - Restart: SetupState로 전환
## - Upgrade: 업그레이드 화면 표시


func get_phase() -> GameState.Phase:
	return GameState.Phase.GAME_OVER


func enter() -> void:
	super.enter()

	# 타이머 정지
	GameState.set_timer_running(false)

	# 승/패 판정
	var won := GameState.is_game_won()
	GameState.game_over.emit(won)

	_connect_signals()


func exit() -> void:
	_disconnect_signals()
	game_root.game_over_screen.visible = false


func _connect_signals() -> void:
	game_root.game_over_screen.restart_pressed.connect(_on_restart_pressed)
	game_root.game_over_screen.upgrade_pressed.connect(_on_upgrade_pressed)
	game_root.upgrade_screen.continue_pressed.connect(_on_upgrade_continue)
	game_root.game_over_screen.gear_pressed.connect(_on_gear_pressed)
	game_root.gear_grid_ui.continue_pressed.connect(_on_gear_continue)


func _disconnect_signals() -> void:
	game_root.game_over_screen.restart_pressed.disconnect(_on_restart_pressed)
	game_root.game_over_screen.upgrade_pressed.disconnect(_on_upgrade_pressed)
	game_root.upgrade_screen.continue_pressed.disconnect(_on_upgrade_continue)
	game_root.game_over_screen.gear_pressed.disconnect(_on_gear_pressed)
	game_root.gear_grid_ui.continue_pressed.disconnect(_on_gear_continue)


func _on_restart_pressed() -> void:
	transitioned.emit(self, "SetupState")


func _on_upgrade_pressed() -> void:
	game_root.upgrade_screen.show_upgrades()


func _on_upgrade_continue() -> void:
	transitioned.emit(self, "SetupState")


func _on_gear_pressed() -> void:
	game_root.gear_grid_ui.show_screen()


func _on_gear_continue() -> void:
	game_root.game_over_screen.visible = true
