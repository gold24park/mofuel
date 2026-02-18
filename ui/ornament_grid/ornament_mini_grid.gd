extends Control
## 게임 플레이 중 우측 하단에 표시되는 오너먼트 미니 그리드
## 읽기 전용 — 배치 상태 시각화 + 효과 발동 하이라이트

const CELL_SIZE: int = 18
const GRID_SIZE: int = OrnamentGrid.GRID_SIZE

const COLOR_EMPTY := Color(0.2, 0.2, 0.2, 0.3)
const COLOR_BORDER := Color(0.4, 0.4, 0.4, 0.4)
const COLOR_HIGHLIGHT_BORDER := Color(1.0, 1.0, 0.6, 1.0)

var _grid_cells: Array[Panel] = []
var _active_tweens: Array[Tween] = []
@onready var _grid_container: GridContainer = $Panel/GridContainer


func _ready() -> void:
	_build_grid()
	MetaState.ornament_grid.grid_changed.connect(_refresh_colors)


func _build_grid() -> void:
	_grid_container.columns = GRID_SIZE

	for y in GRID_SIZE:
		for x in GRID_SIZE:
			var cell := Panel.new()
			cell.custom_minimum_size = Vector2(CELL_SIZE, CELL_SIZE)
			cell.mouse_filter = Control.MOUSE_FILTER_IGNORE
			cell.pivot_offset = Vector2(CELL_SIZE / 2.0, CELL_SIZE / 2.0)

			var style := StyleBoxFlat.new()
			style.bg_color = COLOR_EMPTY
			style.border_color = COLOR_BORDER
			style.border_width_left = 1
			style.border_width_right = 1
			style.border_width_top = 1
			style.border_width_bottom = 1
			style.corner_radius_top_left = 2
			style.corner_radius_top_right = 2
			style.corner_radius_bottom_left = 2
			style.corner_radius_bottom_right = 2
			cell.add_theme_stylebox_override("panel", style)

			_grid_container.add_child(cell)
			_grid_cells.append(cell)

	_refresh_colors()


func _refresh_colors() -> void:
	var grid := MetaState.ornament_grid

	for y in GRID_SIZE:
		for x in GRID_SIZE:
			var idx := y * GRID_SIZE + x
			var cell := _grid_cells[idx]
			var style := cell.get_theme_stylebox("panel") as StyleBoxFlat
			var occupant := grid.get_cell(Vector2i(x, y))
			if occupant != null:
				style.bg_color = occupant.type.color
				style.border_color = Color(1.0, 1.0, 1.0, 0.4)
			else:
				style.bg_color = COLOR_EMPTY
				style.border_color = COLOR_BORDER
			# 스케일 리셋 (이전 애니메이션 잔여)
			cell.scale = Vector2.ONE


#region Highlight Animation
## 효과가 발동한 오너먼트들의 셀에 펄스 애니메이션 재생
func highlight_ornaments(ornaments: Array[OrnamentInstance]) -> void:
	_kill_active_tweens()

	for ornament in ornaments:
		if not ornament.is_placed:
			continue
		for cell_pos in ornament.get_occupied_cells():
			if cell_pos.x < 0 or cell_pos.x >= GRID_SIZE or cell_pos.y < 0 or cell_pos.y >= GRID_SIZE:
				continue
			var idx := cell_pos.y * GRID_SIZE + cell_pos.x
			_animate_cell_pulse(_grid_cells[idx], ornament.type.color)


func _animate_cell_pulse(cell: Panel, base_color: Color) -> void:
	var style := cell.get_theme_stylebox("panel") as StyleBoxFlat
	var bright_color := base_color.lightened(0.4)

	var tween := create_tween()
	_active_tweens.append(tween)

	# 확대 + 밝은 테두리
	tween.set_parallel(true)
	tween.tween_property(cell, "scale", Vector2(1.25, 1.25), 0.15).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_method(func(c: Color): style.border_color = c, style.border_color, COLOR_HIGHLIGHT_BORDER, 0.15)
	tween.tween_method(func(c: Color): style.bg_color = c, base_color, bright_color, 0.15)
	tween.tween_property(style, "border_width_left", 3, 0.15)
	tween.tween_property(style, "border_width_right", 3, 0.15)
	tween.tween_property(style, "border_width_top", 3, 0.15)
	tween.tween_property(style, "border_width_bottom", 3, 0.15)

	# 복원
	tween.set_parallel(false)
	tween.tween_interval(0.3)
	tween.set_parallel(true)
	tween.tween_property(cell, "scale", Vector2.ONE, 0.25).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	tween.tween_method(func(c: Color): style.border_color = c, COLOR_HIGHLIGHT_BORDER, Color(1.0, 1.0, 1.0, 0.4), 0.25)
	tween.tween_method(func(c: Color): style.bg_color = c, bright_color, base_color, 0.25)
	tween.tween_property(style, "border_width_left", 1, 0.25)
	tween.tween_property(style, "border_width_right", 1, 0.25)
	tween.tween_property(style, "border_width_top", 1, 0.25)
	tween.tween_property(style, "border_width_bottom", 1, 0.25)


func _kill_active_tweens() -> void:
	for tween in _active_tweens:
		if tween and tween.is_running():
			tween.kill()
	_active_tweens.clear()
#endregion
