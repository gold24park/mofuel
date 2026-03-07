extends Control
## POST_ROLL 액션 버튼
## Normal 모드: Nitro (거리) / Smoke (시간) / Reroll
## Reroll 모드: Roll / Double Down (낙장불입 — 취소 불가)

signal nitro_pressed        ## 점수 → 거리 환산
signal smoke_pressed        ## 점수 → 시간 확보
signal reroll_pressed       ## 리롤 모드 진입 요청
signal reroll_confirmed     ## 리롤 모드에서 Roll 확정
signal double_down_pressed

@onready var nitro_button: Button = $CenterContainer/HBoxContainer/NitroButton
@onready var smoke_button: Button = $CenterContainer/HBoxContainer/SmokeButton
@onready var reroll_button: Button = $CenterContainer/HBoxContainer/RerollButton
@onready var roll_button: Button = $CenterContainer/HBoxContainer/RollConfirmButton
@onready var double_down_button: Button = $CenterContainer/HBoxContainer/DoubleDownButton

var _reroll_mode: bool = false


func _ready() -> void:
	nitro_button.pressed.connect(func(): nitro_pressed.emit())
	smoke_button.pressed.connect(func(): smoke_pressed.emit())
	reroll_button.pressed.connect(func(): reroll_pressed.emit())
	roll_button.pressed.connect(func(): reroll_confirmed.emit())
	double_down_button.pressed.connect(func(): double_down_pressed.emit())
	visible = false


## 선택된 주사위 수와 리롤 잔여에 따라 버튼 상태 업데이트
func update_state(selected_count: int) -> void:
	if _reroll_mode:
		# 리롤 모드: Roll 버튼은 선택된 주사위가 있을 때만 활성
		roll_button.disabled = selected_count == 0
		roll_button.text = "ROLL %d" % selected_count if selected_count > 0 else "ROLL"
		# Double Down: 리롤 2개 이상 남아있고 아직 미사용
		double_down_button.visible = GameState.can_double_down()
		return

	# Reroll: 리롤 가능할 때만 활성
	reroll_button.disabled = not GameState.can_reroll()
	reroll_button.text = "REROLL (%d)" % GameState.rerolls_remaining


## 점수 미리보기를 Nitro/Smoke 버튼에 표시
func set_score_preview(score: int) -> void:
	if score <= 0:
		nitro_button.text = "NITRO"
		smoke_button.text = "SMOKE"
		nitro_button.disabled = true
		smoke_button.disabled = true
		return
	var dist_preview := score * GameState.DISTANCE_FACTOR
	var time_preview := score * GameState.TIME_FACTOR
	nitro_button.text = "NITRO\n-%.0fm" % dist_preview
	smoke_button.text = "SMOKE\n+%.1fs" % time_preview
	nitro_button.disabled = false
	smoke_button.disabled = false


func show_bar() -> void:
	_reroll_mode = false
	_show_normal_buttons()
	visible = true
	update_state(0)


func hide_bar() -> void:
	_reroll_mode = false
	visible = false


## 리롤 모드 진입: Nitro/Smoke/Reroll 숨기고 Roll/DD 표시 (낙장불입)
func enter_reroll_mode() -> void:
	_reroll_mode = true
	nitro_button.visible = false
	smoke_button.visible = false
	reroll_button.visible = false
	roll_button.visible = true
	double_down_button.visible = GameState.can_double_down()
	update_state(0)


func is_reroll_mode() -> bool:
	return _reroll_mode


func _show_normal_buttons() -> void:
	nitro_button.visible = true
	smoke_button.visible = true
	reroll_button.visible = true
	roll_button.visible = false
	double_down_button.visible = false
