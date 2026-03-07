class_name GameStateBase
extends Node

## 상태 머신에서 사용될 기본 상태 클래스

signal transitioned(state: GameStateBase, new_state_name: String)

var state_machine: GameStateMachine
var game_root: Control # 메인 게임 씬 참조 (UI, DiceManager 접근용)


## 서브클래스에서 override하여 자신의 Phase를 반환
func get_phase() -> GameState.Phase:
	return GameState.Phase.SETUP


## 상태 진입 시 1회 호출 — phase 설정 자동 처리
func enter() -> void:
	GameState.current_phase = get_phase()
	GameState.phase_changed.emit(GameState.current_phase)


## 상태 종료 시 1회 호출
func exit() -> void:
	pass


## 입력 이벤트 발생 시 호출 (_input / _unhandled_input)
## 리턴값: 이벤트를 소비했는지 여부 (true면 전파 중단)
func handle_input(_event: InputEvent) -> bool:
	return false


## 조건에 맞는 기어를 필터링하여 mini_grid에 하이라이트
func _highlight_gears(predicate: Callable) -> void:
	var active: Array[GearInstance] = []
	for gear in MetaState.gear_grid.placed_gears:
		if predicate.call(gear):
			active.append(gear)
	if not active.is_empty():
		game_root.gear_mini_grid.highlight_gears(active)
