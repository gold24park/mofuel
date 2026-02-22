class_name HandDisplay
extends Control
## Hand 주사위 표시 — 고정 8슬롯 + DiscardZone + DrawButton
##
## - 슬롯 클릭 (release): dice_clicked → PreRollState가 Hand→Active 처리
## - 슬롯 드래그 → DiscardZone 드롭: DiscardZone.dice_discarded
## - Draw 버튼: draw_pressed

signal dice_clicked(index: int) ## Hand 주사위 클릭 시 (Active로 이동 요청)
signal draw_pressed ## Draw 버튼 클릭

const SLOT_SIZE := Vector2(16, 16)
const HAND_MAX := Deck.HAND_MAX

@onready var grid_container: GridContainer = $GridContainer
@onready var discard_zone: DiscardZone = $DiscardZone
@onready var draw_button: DrawButton = $DrawButton

@onready var _slots: Array[Slot] = [
	$GridContainer/Slot,
	$GridContainer/Slot2,
	$GridContainer/Slot3,
	$GridContainer/Slot4,
	$GridContainer/Slot5,
	$GridContainer/Slot6,
	$GridContainer/Slot7,
	$GridContainer/Slot8
]


func _ready():
	GameState.hand_changed.connect(_on_hand_changed)
	draw_button.draw_pressed.connect(func(): draw_pressed.emit())
	_build_ui()
	_update_display()


#region UI 구축
func _build_ui() -> void:
	# Slots — 클릭 + 드래그 설정
	for i in range(_slots.size()):
		var slot = _slots[i]
		slot.gui_input.connect(_on_slot_gui_input.bind(i))
		slot.set_drag_forwarding(
			_slot_get_drag_data.bind(i),
			Callable(),
			Callable()
		)
#endregion


#region 슬롯 업데이트
func _update_display() -> void:
	var hand := GameState.deck.hand
	for i in range(_slots.size()):
		_update_slot(i, hand[i] if i < hand.size() else null)


func _update_slot(index: int, dice_instance: DiceInstance) -> void:
	var slot := _slots[index]
	slot.set_dice_instance(dice_instance)
#endregion


#region 클릭 처리 (mouse release — 드래그와 충돌 방지)
func _on_slot_gui_input(event: InputEvent, index: int) -> void:
	if event is InputEventMouseButton and not event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_on_slot_clicked(index)


func _on_slot_clicked(index: int) -> void:
	if GameState.current_phase != GameState.Phase.PRE_ROLL:
		return
	if GameState.is_transitioning:
		return
	if index >= GameState.deck.hand.size():
		return
	if GameState.active_dice.size() >= GameState.DICE_COUNT:
		return
	dice_clicked.emit(index)
#endregion


#region 드래그 (슬롯에서 시작)
func _slot_get_drag_data(_at_position: Vector2, index: int) -> Variant:
	if GameState.current_phase != GameState.Phase.PRE_ROLL:
		return null
	if GameState.is_transitioning:
		return null
	if index >= GameState.deck.hand.size():
		return null
	if not discard_zone._can_discard():
		return null

	var preview_label := Label.new()
	preview_label.text = GameState.deck.hand[index].type.display_name
	preview_label.add_theme_color_override("font_color", Color.WHITE)
	set_drag_preview(preview_label)

	return {"type": "hand_dice", "index": index}
#endregion


#region Draw 버튼 제어
func set_draw_enabled(enabled: bool) -> void:
	draw_button.set_enabled(enabled)
#endregion


#region Hand 변경
func _on_hand_changed() -> void:
	_update_display()
#endregion
