extends Control

signal dice_selected(index: int)

const DICE_PREVIEW = preload("res://ui/dice_preview/dice_preview.tscn")

@onready var container: HBoxContainer = $CenterContainer/HBoxContainer
@onready var background: ColorRect = $ColorRect

var dice_previews: Array = []
var replace_mode: bool = false


func _ready():
	GameState.reserve_changed.connect(_on_reserve_changed)
	_update_display()


func enter_replace_mode():
	replace_mode = true
	background.color = Color(0.2, 0.15, 0.1, 0.8)
	_update_slots_visual()


func exit_replace_mode():
	replace_mode = false
	background.color = Color(0.1, 0.1, 0.1, 0.6)
	_update_slots_visual()


func _update_slots_visual():
	for preview in dice_previews:
		if replace_mode:
			preview.modulate = Color(1.2, 1.2, 1.0)
		else:
			preview.modulate = Color.WHITE


func _update_display():
	# 기존 프리뷰 제거
	for preview in dice_previews:
		preview.queue_free()
	dice_previews.clear()

	# Reserve 주사위 표시
	for i in range(GameState.reserve.size()):
		var dice_instance: DiceInstance = GameState.reserve[i]
		var preview := _create_dice_preview(i)
		container.add_child(preview)
		preview.set_dice_instance(dice_instance)
		dice_previews.append(preview)


func _create_dice_preview(index: int) -> Control:
	var preview = DICE_PREVIEW.instantiate()
	preview.custom_minimum_size = Vector2(40, 40)

	if replace_mode:
		preview.modulate = Color(1.2, 1.2, 1.0)

	# 클릭 이벤트를 위한 컨테이너
	# TODO: 나중에 DicePreview Card로 만들어서 처리
	var click_area := Control.new()
	click_area.set_anchors_preset(Control.PRESET_FULL_RECT)
	click_area.mouse_filter = Control.MOUSE_FILTER_STOP
	click_area.gui_input.connect(func(event):
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			if replace_mode:
				dice_selected.emit(index)
	)
	preview.add_child(click_area)

	return preview


func _on_reserve_changed():
	_update_display()
