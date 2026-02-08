extends Control
## 발라트로 스타일 점수 표시
## 족보 이름 → Chips (base + bonus) × Mult → 최종 점수

signal score_display_finished

@onready var panel: PanelContainer = $PanelContainer
@onready var category_label: Label = $PanelContainer/VBoxContainer/CategoryLabel
@onready var chips_label: Label = $PanelContainer/VBoxContainer/HBoxContainer/ChipsLabel
@onready var mult_sign: Label = $PanelContainer/VBoxContainer/HBoxContainer/MultSign
@onready var mult_label: Label = $PanelContainer/VBoxContainer/HBoxContainer/MultLabel
@onready var final_score_label: Label = $PanelContainer/VBoxContainer/FinalScoreLabel

const COUNT_DURATION: float = 0.3 ## 각 단계 카운팅 시간
const PUNCH_SCALE: float = 1.3 ## punch 효과 최대 스케일


func _ready() -> void:
	visible = false


## 점수 분해 데이터로 순차 카운팅 애니메이션 표시
func show_score(breakdown: Dictionary, dd: bool) -> void:
	visible = true
	final_score_label.visible = false

	# 1. 카테고리 이름
	category_label.text = breakdown["category_name"]

	# 2. Chips = base + bonus
	var chips: int = breakdown["base"] + breakdown["bonus_pool"]
	chips_label.text = str(chips)
	_punch(chips_label)

	# 3. Mult
	var mult: float = breakdown["mult_pool"]
	mult_label.text = "x%.1f" % mult if mult != float(int(mult)) else "x%d" % int(mult)
	_punch(mult_label)

	await get_tree().create_timer(COUNT_DURATION).timeout

	# 4. 최종 점수
	var final_val: int = breakdown["final"]
	if dd:
		final_score_label.text = "= %d (x2!)" % final_val
	else:
		final_score_label.text = "= %d" % final_val
	final_score_label.visible = true
	_punch(final_score_label)

	await get_tree().create_timer(COUNT_DURATION).timeout
	score_display_finished.emit()


## 점수 없음 표시 (유효 족보 없을 때)
func show_no_score() -> void:
	visible = true
	category_label.text = "Burst"
	chips_label.text = "0"
	mult_label.text = "x1"
	final_score_label.text = "= 0"
	final_score_label.visible = true

	await get_tree().create_timer(COUNT_DURATION * 2).timeout
	score_display_finished.emit()


func hide_display() -> void:
	visible = false


func _punch(label: Control) -> void:
	var tween := create_tween()
	tween.tween_property(label, "scale", Vector2.ONE * PUNCH_SCALE, 0.05)
	tween.tween_property(label, "scale", Vector2.ONE, 0.15)
