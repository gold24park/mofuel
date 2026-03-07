class_name PlayerStateMachine
extends Node

## 플레이어 전용 상태 머신 — GameStateMachine 구조 미러링

@export var initial_state_name: String = "IdleState"

var current_state: PlayerState
var states: Dictionary[String, PlayerState] = {}


func init(player_node: Player) -> void:
	for child in get_children():
		if child is PlayerState:
			states[child.name.to_lower()] = child
			child.player = player_node
			child.transitioned.connect(_on_child_transitioned)

	var initial_state: PlayerState = states.get(initial_state_name.to_lower())
	if initial_state:
		current_state = initial_state
		initial_state.enter()
	else:
		push_error("PlayerStateMachine: Initial state not found - %s" % initial_state_name)


func _unhandled_input(event: InputEvent) -> void:
	if current_state:
		if current_state.handle_input(event):
			get_viewport().set_input_as_handled()


func _on_child_transitioned(state: PlayerState, new_state_name: String) -> void:
	if state != current_state:
		return

	var new_state: PlayerState = states.get(new_state_name.to_lower())
	if not new_state:
		push_warning("PlayerStateMachine: State not found - %s" % new_state_name)
		return

	if current_state:
		current_state.exit()

	current_state = new_state
	current_state.enter()
