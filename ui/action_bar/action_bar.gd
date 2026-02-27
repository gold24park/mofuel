extends Control
## POST_ROLL 액션 버튼: Stand / Reroll / Double Down
## Reroll 모드: Reroll 버튼 → 주사위 선택 → Roll 확정 (낙장불입 — 취소 불가)

signal stand_pressed
signal reroll_pressed       ## 리롤 모드 진입 요청
signal reroll_confirmed     ## 리롤 모드에서 Roll 확정
signal double_down_pressed

@onready var stand_button: Button = $CenterContainer/HBoxContainer/StandButton
@onready var reroll_button: Button = $CenterContainer/HBoxContainer/RerollButton
@onready var double_down_button: Button = $CenterContainer/HBoxContainer/DoubleDownButton
@onready var roll_button: Button = $CenterContainer/HBoxContainer/RollConfirmButton

var _reroll_mode: bool = false


func _ready() -> void:
	stand_button.pressed.connect(func(): stand_pressed.emit())
	reroll_button.pressed.connect(func(): reroll_pressed.emit())
	double_down_button.pressed.connect(func(): double_down_pressed.emit())
	roll_button.pressed.connect(func(): reroll_confirmed.emit())
	visible = false


## 선택된 주사위 수와 리롤 잔여에 따라 버튼 상태 업데이트
func update_state(selected_count: int) -> void:
	if _reroll_mode:
		# 리롤 모드: Roll 버튼은 선택된 주사위가 있을 때만 활성
		roll_button.disabled = selected_count == 0
		roll_button.text = "ROLL %d" % selected_count if selected_count > 0 else "ROLL"
		return

	# Stand: 항상 활성
	stand_button.disabled = false

	# Reroll: 리롤 가능할 때만 활성 (선택 상태 불문)
	reroll_button.disabled = not GameState.can_reroll()
	reroll_button.text = "REROLL (%d)" % GameState.rerolls_remaining

	# Double Down: 리롤 2개 이상 남아있고 아직 미사용
	double_down_button.visible = GameState.can_double_down()


func show_bar() -> void:
	_reroll_mode = false
	_show_normal_buttons()
	visible = true
	update_state(0)


func hide_bar() -> void:
	_reroll_mode = false
	visible = false


## 리롤 모드 진입: Stand/Reroll/DD 숨기고 Roll만 표시 (낙장불입)
func enter_reroll_mode() -> void:
	_reroll_mode = true
	stand_button.visible = false
	reroll_button.visible = false
	double_down_button.visible = false
	roll_button.visible = true
	update_state(0)


func is_reroll_mode() -> bool:
	return _reroll_mode


func _show_normal_buttons() -> void:
	stand_button.visible = true
	reroll_button.visible = true
	double_down_button.visible = GameState.can_double_down()
	roll_button.visible = false
