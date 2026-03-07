extends PlayerState

## 대기 상태 — friction으로 감속, 방향 입력 시 RunState로 전환


func enter() -> void:
	player.animated_sprite.play("idle")


func physics_update(delta: float) -> void:
	# Friction으로 수평 속도 감소
	player.velocity.x = move_toward(player.velocity.x, 0.0, player.friction * delta)

	# 방향 입력 감지 시 RunState로 전환
	var input_dir := Input.get_axis("ui_left", "ui_right")
	if not is_zero_approx(input_dir):
		transitioned.emit(self, "RunState")
