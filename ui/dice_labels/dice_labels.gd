extends Control

const DICE_COUNT := 5

var _labels: Array[Label] = []
var _camera: Camera3D = null
var _dice_nodes: Array = []
var _dice_instances: Array = []
var _visible_flags: Array[bool] = [false, false, false, false, false]


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	for i in range(DICE_COUNT):
		var label := Label.new()
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 32)
		label.add_theme_color_override("font_color", Color.WHITE)
		label.add_theme_color_override("font_outline_color", Color.BLACK)
		label.add_theme_constant_override("outline_size", 4)
		label.visible = false
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(label)
		_labels.append(label)


func setup(camera: Camera3D, dice_nodes: Array, dice_instances: Array) -> void:
	_camera = camera
	_dice_nodes = dice_nodes
	_dice_instances = dice_instances


func show_label(index: int) -> void:
	if index >= 0 and index < DICE_COUNT:
		_visible_flags[index] = true
		_update_label(index)


func hide_label(index: int) -> void:
	if index >= 0 and index < DICE_COUNT:
		_visible_flags[index] = false
		_labels[index].visible = false


func hide_all() -> void:
	for i in range(DICE_COUNT):
		_visible_flags[i] = false
		_labels[i].visible = false


func _process(_delta: float) -> void:
	if _camera == null:
		return

	for i in range(DICE_COUNT):
		if _visible_flags[i]:
			_update_label(i)


func _update_label(index: int) -> void:
	if index >= _dice_nodes.size() or index >= _dice_instances.size():
		return

	var dice_node = _dice_nodes[index]
	var dice_instance = _dice_instances[index]

	if dice_node == null or dice_instance == null:
		_labels[index].visible = false
		return

	# 3D 위치를 스크린 좌표로 변환 (주사위 바로 위에 표시)
	# 카메라가 위에서 아래로 보므로, 스크린 위쪽 = 월드 -Z
	var world_pos: Vector3 = dice_node.global_position + Vector3(0, 0, -1.5)
	var screen_pos: Vector2 = _camera.unproject_position(world_pos)

	# 라벨 위치 및 텍스트 설정
	_labels[index].text = dice_instance.get_display_text()
	_labels[index].position = screen_pos - _labels[index].size / 2
	_labels[index].visible = true
