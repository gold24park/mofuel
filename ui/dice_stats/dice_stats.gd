extends Control
## 주사위 코너 스탯 표시 (2D 프로젝션)
## dice_labels와 동일한 패턴: camera.unproject_position()으로 3D→2D 변환

const DICE_COUNT := 5

## 3D 오프셋 (주사위 중심 기준, 카메라가 위에서 아래로 봄)
const BONUS_OFFSET := Vector3(1.0, 0, -1.0)      ## 오른쪽 위
const MULTIPLIER_OFFSET := Vector3(1.0, 0, 1.0)   ## 오른쪽 아래
const DURABILITY_OFFSET := Vector3(-1.0, 0, -1.0)  ## 왼쪽 위

## 스탯 라벨 색상
@export_group("Colors")
@export var bonus_positive_color: Color = Color.GREEN
@export var bonus_negative_color: Color = Color.RED
@export var multiplier_color: Color = Color(1.0, 0.85, 0.0) ## 금색
@export var durability_color: Color = Color.WHITE

## 라벨 스타일
@export_group("Style")
@export var font_size: int = 20
@export var outline_size: int = 4

var _camera: Camera3D = null
var _dice_manager: Node3D = null  ## 항상 현재 dice_nodes를 읽기 위해 참조 저장
var _is_showing: bool = false

## 라벨 배열 (주사위별 1개씩)
var _bonus_labels: Array[Label] = []
var _multiplier_labels: Array[Label] = []
var _durability_labels: Array[Label] = []

## 값 배열 (주사위별 1개씩)
var _bonus_values: Array[int] = [0, 0, 0, 0, 0]
var _multiplier_values: Array[int] = [1, 1, 1, 1, 1]
var _durability_values: Array[int] = [-1, -1, -1, -1, -1]


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	for i in range(DICE_COUNT):
		var bonus_label := _make_label()
		var mult_label := _make_label()
		var dur_label := _make_label()
		add_child(bonus_label)
		add_child(mult_label)
		add_child(dur_label)
		_bonus_labels.append(bonus_label)
		_multiplier_labels.append(mult_label)
		_durability_labels.append(dur_label)


func setup(camera: Camera3D, dice_manager: Node3D) -> void:
	_camera = camera
	_dice_manager = dice_manager


## 라벨 텍스트/색상만 설정, 전부 숨김 (애니메이션 중 개별 reveal용)
func prepare_stats(stats_data: Array[Dictionary]) -> void:
	_is_showing = true
	for i in range(mini(stats_data.size(), DICE_COUNT)):
		var data := stats_data[i]
		_bonus_values[i] = data.get("bonus", 0)
		_multiplier_values[i] = data.get("multiplier", 1)
		_durability_values[i] = data.get("durability", -1)
		_configure_stat(i)


## 단일 주사위 스탯 라벨 표시 (값이 기본값이면 숨김 유지)
func reveal_stat(index: int) -> void:
	if _bonus_values[index] != 0:
		_bonus_labels[index].visible = true
	if _multiplier_values[index] > 1:
		_multiplier_labels[index].visible = true
	if _durability_values[index] >= 0:
		_durability_labels[index].visible = true


## 모든 주사위 스탯 라벨 표시
func reveal_all() -> void:
	for i in range(DICE_COUNT):
		reveal_stat(i)


## 준비 + 즉시 전체 표시 (애니메이션 없이 쓸 때)
func show_stats(stats_data: Array[Dictionary]) -> void:
	prepare_stats(stats_data)
	reveal_all()


func hide_all() -> void:
	_is_showing = false
	for i in range(DICE_COUNT):
		_bonus_labels[i].visible = false
		_multiplier_labels[i].visible = false
		_durability_labels[i].visible = false


func _process(_delta: float) -> void:
	if not _is_showing or _camera == null or _dice_manager == null:
		return
	var dice_nodes: Array = _dice_manager.dice_nodes
	for i in range(mini(dice_nodes.size(), DICE_COUNT)):
		_update_positions(i, dice_nodes[i])


func _update_positions(index: int, dice_node: RigidBody3D) -> void:
	if dice_node == null:
		return
	var dice_pos: Vector3 = dice_node.global_position
	_project_label(_bonus_labels[index], dice_pos + BONUS_OFFSET)
	_project_label(_multiplier_labels[index], dice_pos + MULTIPLIER_OFFSET)
	_project_label(_durability_labels[index], dice_pos + DURABILITY_OFFSET)


func _project_label(label: Label, world_pos: Vector3) -> void:
	if not label.visible:
		return
	var screen_pos := _camera.unproject_position(world_pos)
	label.position = screen_pos - label.size / 2


## 라벨 텍스트/색상 설정 (visible은 건드리지 않음)
func _configure_stat(index: int) -> void:
	var bonus := _bonus_values[index]
	var multiplier := _multiplier_values[index]
	var durability := _durability_values[index]

	# Bonus
	_bonus_labels[index].visible = false
	if bonus != 0:
		_bonus_labels[index].text = "+%d" % bonus if bonus > 0 else str(bonus)
		var color := bonus_positive_color if bonus > 0 else bonus_negative_color
		_bonus_labels[index].add_theme_color_override("font_color", color)

	# Multiplier
	_multiplier_labels[index].visible = false
	if multiplier > 1:
		_multiplier_labels[index].text = "x%d" % multiplier
		_multiplier_labels[index].add_theme_color_override("font_color", multiplier_color)

	# Durability
	_durability_labels[index].visible = false
	if durability >= 0:
		_durability_labels[index].text = str(durability)
		_durability_labels[index].add_theme_color_override("font_color", durability_color)


func _make_label() -> Label:
	var label := Label.new()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", outline_size)
	label.visible = false
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label
