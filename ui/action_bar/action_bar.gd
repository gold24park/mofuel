extends Control
## POST_ROLL 액션 버튼: Stand / Reroll / Double Down

signal stand_pressed
signal reroll_pressed
signal double_down_pressed

@onready var stand_button: Button = $CenterContainer/HBoxContainer/StandButton
@onready var reroll_button: Button = $CenterContainer/HBoxContainer/RerollButton
@onready var double_down_button: Button = $CenterContainer/HBoxContainer/DoubleDownButton


func _ready() -> void:
	stand_button.pressed.connect(func(): stand_pressed.emit())
	reroll_button.pressed.connect(func(): reroll_pressed.emit())
	double_down_button.pressed.connect(func(): double_down_pressed.emit())
	visible = false


## 선택된 주사위 수와 리롤 잔여에 따라 버튼 상태 업데이트
func update_state(selected_count: int) -> void:
	# Stand: 항상 활성
	stand_button.disabled = false

	# Reroll: 선택된 주사위가 있고 리롤 가능할 때
	var can_reroll := selected_count > 0 and GameState.can_reroll()
	reroll_button.disabled = not can_reroll
	reroll_button.text = "REROLL %d (%d)" % [selected_count, GameState.rerolls_remaining] \
		if selected_count > 0 else "REROLL (%d)" % GameState.rerolls_remaining

	# Double Down: 리롤 2개 이상 남아있고 아직 미사용
	double_down_button.visible = GameState.can_double_down()


func show_bar() -> void:
	visible = true
	update_state(0)


func hide_bar() -> void:
	visible = false
