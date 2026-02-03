class_name GameStateMachine
extends Node

## 게임의 전체 흐름을 관리하는 상태 머신

@export var initial_state_name: String = "SetupState"

var current_state: GameStateBase
var states: Dictionary[String, GameStateBase] = {}
var game_root: Control  # 의존성 주입용


func init(root_node: Control) -> void:
	game_root = root_node

	# 자식 노드들을 순회하며 상태로 등록
	for child in get_children():
		if child is GameStateBase:
			states[child.name.to_lower()] = child
			child.state_machine = self
			child.game_root = game_root
			child.transitioned.connect(on_child_transitioned)

	# 초기 상태로 전환
	var initial_state: GameStateBase = states.get(initial_state_name.to_lower())
	if initial_state:
		current_state = initial_state
		initial_state.enter()
	else:
		push_error("GameStateMachine: Initial state not found - " + initial_state_name)


func _process(delta: float) -> void:
	if current_state:
		current_state.update(delta)


func _physics_process(delta: float) -> void:
	if current_state:
		current_state.physics_update(delta)


func _unhandled_input(event: InputEvent) -> void:
	if current_state:
		current_state.handle_input(event)


func on_child_transitioned(state: GameStateBase, new_state_name: String) -> void:
	if state != current_state:
		return

	var new_state: GameStateBase = states.get(new_state_name.to_lower())
	if not new_state:
		push_warning("GameStateMachine: State not found - " + new_state_name)
		return

	if current_state:
		current_state.exit()

	current_state = new_state
	print("[StateMachine] %s -> %s" % [state.name, new_state_name])
	current_state.enter()


## 외부에서 강제 전환이 필요할 때 사용 (가급적 지양)
func change_state(new_state_name: String) -> void:
	on_child_transitioned(current_state, new_state_name)
