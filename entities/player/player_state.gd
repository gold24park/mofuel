class_name PlayerState
extends Node

## 플레이어 상태 베이스 클래스 — GameStateBase 미러링 (게임 로직 의존성 없음)

signal transitioned(state: PlayerState, new_state_name: String)

var player: Player  ## PlayerStateMachine이 주입


## 상태 진입 시 1회 호출
func enter() -> void:
	pass


## 상태 종료 시 1회 호출
func exit() -> void:
	pass


## 매 물리 프레임마다 player.gd가 명시적 호출
func physics_update(_delta: float) -> void:
	pass


## 입력 이벤트 — true 반환 시 전파 중단
func handle_input(_event: InputEvent) -> bool:
	return false
