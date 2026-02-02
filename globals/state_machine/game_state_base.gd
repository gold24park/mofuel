class_name GameStateBase
extends Node

## 상태 머신에서 사용될 기본 상태 클래스

signal transitioned(state: GameStateBase, new_state_name: String)

var state_machine: GameStateMachine
var game_root: Control  # 메인 게임 씬 참조 (UI, DiceManager 접근용)


## 상태 진입 시 1회 호출
func enter() -> void:
	pass


## 상태 종료 시 1회 호출
func exit() -> void:
	pass


## 매 프레임 호출 (_process)
func update(_delta: float) -> void:
	pass


## 매 물리 프레임 호출 (_physics_process)
func physics_update(_delta: float) -> void:
	pass


## 입력 이벤트 발생 시 호출 (_input / _unhandled_input)
## 리턴값: 이벤트를 소비했는지 여부 (true면 전파 중단)
func handle_input(_event: InputEvent) -> bool:
	return false
