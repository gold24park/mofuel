extends Control
## 기어 그리드 UI — 테트리스 스타일 배치 화면
## Click-to-place 방식 (모바일 친화적)

signal continue_pressed

const CELL_SIZE: int = 10
const GRID_SIZE: int = GearGrid.GRID_SIZE

## 셀 색상 상수
const COLOR_EMPTY := Color(0.15, 0.15, 0.15, 0.5)
const COLOR_BORDER_EMPTY := Color(0.4, 0.4, 0.4, 0.3)
const COLOR_PREVIEW_VALID := Color(0.2, 0.8, 0.2, 0.4)
const COLOR_PREVIEW_INVALID := Color(0.8, 0.2, 0.2, 0.4)
const COLOR_BORDER_OCCUPIED := Color(1.0, 1.0, 1.0, 0.6)

@onready var _grid_container: GridContainer = $Panel/HBoxContainer/VBoxContainer/GridContainer
@onready var _rotate_button: Button = $Panel/HBoxContainer/VBoxContainer/BottomBar/RotateButton
@onready var _status_label: Label = $Panel/HBoxContainer/VBoxContainer/BottomBar/StatusLabel
@onready var _inventory_container: VBoxContainer = $Panel/HBoxContainer/ScrollContainer/InventoryList
@onready var _continue_button: Button = $Panel/ContinueButton

var _grid_cells: Array[Panel] = [] ## 36 셀 패널
var _selected_gear: GearInstance = null
var _preview_cells: Array[Vector2i] = [] ## 현재 미리보기 셀
var _last_hovered_pos: Vector2i = Vector2i(-1, -1) ## 마지막 호버 셀 위치


func _ready() -> void:
	_continue_button.pressed.connect(_on_continue_pressed)
	_rotate_button.pressed.connect(_on_rotate_pressed)
	visible = false


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		if _selected_gear != null:
			_selected_gear.rotate_cw()
			_clear_preview()
			if _last_hovered_pos != Vector2i(-1, -1):
				_show_preview(_last_hovered_pos)
			_update_status()
			get_viewport().set_input_as_handled()


func show_screen() -> void:
	visible = true
	_selected_gear = null
	_build_grid()
	_build_inventory_list()
	_update_status()


#region Grid Build
func _build_grid() -> void:
	# 기존 셀 제거
	for child in _grid_container.get_children():
		child.queue_free()
	_grid_cells.clear()

	_grid_container.columns = GRID_SIZE

	for y in GRID_SIZE:
		for x in GRID_SIZE:
			var cell := _create_cell(Vector2i(x, y))
			_grid_container.add_child(cell)
			_grid_cells.append(cell)

	# 초기 셀 색상 반영
	_refresh_grid_colors()


func _create_cell(pos: Vector2i) -> Panel:
	var cell := Panel.new()
	cell.custom_minimum_size = Vector2(CELL_SIZE, CELL_SIZE)
	cell.mouse_filter = Control.MOUSE_FILTER_STOP

	var style := StyleBoxFlat.new()
	style.bg_color = COLOR_EMPTY
	style.border_color = COLOR_BORDER_EMPTY
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_width_top = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 1
	style.corner_radius_top_right = 1
	style.corner_radius_bottom_left = 1
	style.corner_radius_bottom_right = 1
	cell.add_theme_stylebox_override("panel", style)

	cell.gui_input.connect(_on_cell_input.bind(pos))
	cell.mouse_entered.connect(_on_cell_mouse_entered.bind(pos))
	cell.mouse_exited.connect(_on_cell_mouse_exited.bind(pos))
	return cell
#endregion


#region Inventory List Build
func _build_inventory_list() -> void:
	for child in _inventory_container.get_children():
		child.queue_free()

	var unplaced := MetaState.get_unplaced_gears()

	# 미배치 기어 표시
	for gear in unplaced:
		var row := _create_inventory_row(gear)
		_inventory_container.add_child(row)

	# 비어있으면 안내 메시지
	if unplaced.is_empty():
		var label := Label.new()
		label.text = "No gears"
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		_inventory_container.add_child(label)


func _create_inventory_row(gear: GearInstance) -> Button:
	var btn := Button.new()
	btn.text = gear.type.display_name
	btn.custom_minimum_size = Vector2(53, 15)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	# 색상 힌트 — 버튼 텍스트 색
	btn.add_theme_color_override("font_color", gear.type.color)

	btn.pressed.connect(_on_inventory_item_pressed.bind(gear))
	return btn
#endregion


#region Cell Interaction
func _on_cell_input(event: InputEvent, pos: Vector2i) -> void:
	if not (event is InputEventMouseButton and event.pressed):
		return
	if event.button_index == MOUSE_BUTTON_LEFT:
		_handle_cell_click(pos)


func _handle_cell_click(pos: Vector2i) -> void:
	var grid := MetaState.gear_grid

	# 이미 배치된 기어 클릭 → 제거
	var existing := grid.get_cell(pos)
	if existing != null:
		grid.remove(existing)
		_selected_gear = null
		_clear_preview()
		_refresh_grid_colors()
		_build_inventory_list()
		_update_status()
		return

	# 선택된 기어 배치
	if _selected_gear == null:
		return

	if grid.can_place(_selected_gear, pos):
		grid.place(_selected_gear, pos)
		_selected_gear = null
		_clear_preview()
		_refresh_grid_colors()
		_build_inventory_list()
		_update_status()
#endregion


#region Inventory Selection
func _on_inventory_item_pressed(gear: GearInstance) -> void:
	_selected_gear = gear
	_clear_preview()
	_update_status()
#endregion


#region Rotation
func _on_rotate_pressed() -> void:
	if _selected_gear == null:
		return
	_selected_gear.rotate_cw()
	_clear_preview()
	_update_status()
#endregion


#region Grid Colors
func _refresh_grid_colors() -> void:
	var grid := MetaState.gear_grid

	for y in GRID_SIZE:
		for x in GRID_SIZE:
			var pos := Vector2i(x, y)
			var idx := y * GRID_SIZE + x
			var cell := _grid_cells[idx]
			var style := cell.get_theme_stylebox("panel") as StyleBoxFlat

			var occupant := grid.get_cell(pos)
			if occupant != null:
				style.bg_color = occupant.type.color
				style.border_color = COLOR_BORDER_OCCUPIED
			else:
				style.bg_color = COLOR_EMPTY
				style.border_color = COLOR_BORDER_EMPTY


func _show_preview(pos: Vector2i) -> void:
	_clear_preview()
	if _selected_gear == null:
		return

	var grid := MetaState.gear_grid
	var valid := grid.can_place(_selected_gear, pos)
	var color := COLOR_PREVIEW_VALID if valid else COLOR_PREVIEW_INVALID

	for offset in _selected_gear.get_rotated_shape():
		var cell_pos := pos + offset
		if cell_pos.x >= 0 and cell_pos.x < GRID_SIZE and cell_pos.y >= 0 and cell_pos.y < GRID_SIZE:
			var idx := cell_pos.y * GRID_SIZE + cell_pos.x
			var style := _grid_cells[idx].get_theme_stylebox("panel") as StyleBoxFlat
			if grid.get_cell(cell_pos) == null:
				style.bg_color = color
				_preview_cells.append(cell_pos)


func _clear_preview() -> void:
	var grid := MetaState.gear_grid
	for cell_pos in _preview_cells:
		var idx := cell_pos.y * GRID_SIZE + cell_pos.x
		if idx >= 0 and idx < _grid_cells.size():
			var style := _grid_cells[idx].get_theme_stylebox("panel") as StyleBoxFlat
			var occupant := grid.get_cell(cell_pos)
			if occupant != null:
				style.bg_color = occupant.type.color
			else:
				style.bg_color = COLOR_EMPTY
	_preview_cells.clear()
#endregion


#region Mouse Hover Preview
func _on_cell_mouse_entered(pos: Vector2i) -> void:
	_last_hovered_pos = pos
	if _selected_gear != null:
		_show_preview(pos)


func _on_cell_mouse_exited(_pos: Vector2i) -> void:
	_last_hovered_pos = Vector2i(-1, -1)
	_clear_preview()
#endregion


#region Status
func _update_status() -> void:
	if _selected_gear:
		_status_label.text = _selected_gear.type.display_name
		_rotate_button.disabled = false
	else:
		_status_label.text = "Select a gear"
		_rotate_button.disabled = true
#endregion


func _on_continue_pressed() -> void:
	visible = false
	continue_pressed.emit()
