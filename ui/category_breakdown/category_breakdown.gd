extends Control
## POST_ROLL 족보 현황 패널 — 모든 유효 족보와 점수 표시, 최고 족보 하이라이트

const MATCHED_COLOR := Color(1.0, 1.0, 1.0)
const BEST_COLOR := Color(1.0, 0.85, 0.2)  ## 금색 하이라이트
const UNMATCHED_COLOR := Color(0.4, 0.4, 0.4)
const FONT_SIZE: int = 16
const ROW_HEIGHT: int = 22

@onready var panel: PanelContainer = $PanelContainer
@onready var container: VBoxContainer = $PanelContainer/VBoxContainer

var _rows: Array[HBoxContainer] = []


func _ready() -> void:
	visible = false


## 모든 카테고리와 점수를 표시 (best_id 하이라이트)
func show_breakdown(all_scores: Dictionary, best_id: String) -> void:
	_clear()
	visible = true

	for cat in CategoryRegistry.get_all_categories():
		var score: int = all_scores.get(cat.id, 0)
		var is_best := cat.id == best_id
		var is_matched := score > 0
		_add_row(cat.display_name, score, is_best, is_matched)


func hide_breakdown() -> void:
	visible = false


func _add_row(cat_name: String, score: int, is_best: bool, is_matched: bool) -> void:
	var row := HBoxContainer.new()
	row.custom_minimum_size.y = ROW_HEIGHT

	# 카테고리 이름
	var name_label := Label.new()
	name_label.text = cat_name
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.add_theme_font_size_override("font_size", FONT_SIZE)
	row.add_child(name_label)

	# 점수
	var score_label := Label.new()
	score_label.text = str(score) if is_matched else "--"
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	score_label.custom_minimum_size.x = 50
	score_label.add_theme_font_size_override("font_size", FONT_SIZE)
	row.add_child(score_label)

	# 색상
	var color: Color
	if is_best:
		color = BEST_COLOR
	elif is_matched:
		color = MATCHED_COLOR
	else:
		color = UNMATCHED_COLOR

	name_label.add_theme_color_override("font_color", color)
	score_label.add_theme_color_override("font_color", color)

	container.add_child(row)
	_rows.append(row)


func _clear() -> void:
	for row in _rows:
		row.queue_free()
	_rows.clear()
