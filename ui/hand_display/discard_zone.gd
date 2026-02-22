class_name DiscardZone
extends Control

## 주사위 버리기 드롭 영역
## Hand 슬롯에서 드래그한 주사위를 여기에 드롭하면 삭제

signal dice_discarded(index: int)


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_drag_forwarding(
		Callable(),
		_can_drop_data,
		_drop_data
	)


func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	if data is not Dictionary or data.get("type") != "hand_dice":
		return false
	return _can_discard()


func _drop_data(_at_position: Vector2, data: Variant) -> void:
	dice_discarded.emit(data["index"])


func _can_discard() -> bool:
	return GameState.deck.hand.size() + GameState.active_dice.size() > GameState.DICE_COUNT
