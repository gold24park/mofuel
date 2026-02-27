extends Control

## 점수 치환 선택 UI
## - 거리 환산: 점수를 소모해 남은 거리를 줄인다
## - 시간 확보: 점수를 소모해 타이머에 시간을 추가한다

signal distance_selected
signal time_selected

@onready var score_label: Label = $Panel/VBoxContainer/ScoreLabel
@onready var distance_button: Button = $Panel/VBoxContainer/HBoxContainer/DistanceButton
@onready var time_button: Button = $Panel/VBoxContainer/HBoxContainer/TimeButton

var _active: bool = false


func _ready() -> void:
	distance_button.pressed.connect(_on_distance_pressed)
	time_button.pressed.connect(_on_time_pressed)
	visible = false


func show_conversion(score: int) -> void:
	score_label.text = "Score: %d" % score

	# 거리/시간 환산 미리보기
	var dist_preview := score * GameState.DISTANCE_FACTOR
	var time_preview := score * GameState.TIME_FACTOR
	distance_button.text = "Distance\n-%.0f" % dist_preview
	time_button.text = "Time\n+%.1fs" % time_preview

	_active = true
	visible = true


func hide_conversion() -> void:
	_active = false
	visible = false


func _on_distance_pressed() -> void:
	if not _active:
		return
	_active = false
	distance_selected.emit()


func _on_time_pressed() -> void:
	if not _active:
		return
	_active = false
	time_selected.emit()
