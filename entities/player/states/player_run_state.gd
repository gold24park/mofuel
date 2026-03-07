extends PlayerState

## 이동 상태 — acceleration으로 가속, 입력 없으면 IdleState로 전환


func enter() -> void:
	player.animated_sprite.play("run")


func physics_update(delta: float) -> void:
	var input_dir := Input.get_axis("ui_left", "ui_right")

	if is_zero_approx(input_dir):
		transitioned.emit(self, "IdleState")
		return

	# 목표 속도를 향해 가속
	var target_velocity := input_dir * player.speed
	player.velocity.x = move_toward(player.velocity.x, target_velocity, player.acceleration * delta)

	# 스프라이트 방향 전환
	player.animated_sprite.flip_h = input_dir < 0.0
