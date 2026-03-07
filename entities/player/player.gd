class_name Player
extends CharacterBody2D

## 베이스 캠프 플레이어 캐릭터 — 중력 + FSM + move_and_slide

@export var speed: float = 80.0          ## 최대 수평 속도 (px/s)
@export var acceleration: float = 600.0  ## 수평 가속 (px/s^2)
@export var friction: float = 800.0      ## 감속 (px/s^2)
@export var gravity: float = 600.0       ## 중력 (px/s^2)

@onready var animated_sprite: AnimatedSprite2D = %AnimatedSprite2D
@onready var state_machine: PlayerStateMachine = %StateMachine


func _ready() -> void:
	state_machine.init(self)


func _physics_process(delta: float) -> void:
	# 1. 중력 적용
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.y = 0.0

	# 2. 현재 상태의 물리 업데이트 (수평 이동 제어)
	if state_machine.current_state:
		state_machine.current_state.physics_update(delta)

	# 3. 이동 + 충돌 해결
	move_and_slide()
