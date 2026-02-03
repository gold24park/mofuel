extends PanelContainer
## 주사위 정보 툴팁 - 선택된 주사위의 상세 정보 표시


@onready var _id_label: Label = %IDLabel
@onready var _name_label: Label = %NameLabel
@onready var _groups_label: Label = %GroupsLabel
@onready var _description_label: Label = %DescriptionLabel

var _current_index: int = -1


func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE


## 주사위 정보 표시
func show_dice_info(dice_index: int) -> void:
	if dice_index < 0 or dice_index >= GameState.active_dice.size():
		hide_tooltip()
		return

	var dice_instance: DiceInstance = GameState.active_dice[dice_index]
	if dice_instance == null or dice_instance.type == null:
		hide_tooltip()
		return

	_current_index = dice_index
	var dice_type: DiceTypeResource = dice_instance.type

	_id_label.text = dice_type.id
	_name_label.text = dice_type.display_name
	_groups_label.text = _format_groups(dice_type.groups)
	_description_label.text = dice_type.description

	visible = true


## 툴팁 숨기기
func hide_tooltip() -> void:
	visible = false
	_current_index = -1


## 그룹 배열을 문자열로 포맷
func _format_groups(groups: Array[String]) -> String:
	if groups.is_empty():
		return "(없음)"
	return ", ".join(groups)
