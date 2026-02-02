class_name InventoryManager
extends RefCounted

## 주사위 데이터 및 위치 이동 관리 클래스

signal inventory_changed
signal hand_changed
signal active_changed

var inventory: Array[DiceInstance] = []
var hand: Array[DiceInstance] = []
var active_dice: Array[DiceInstance] = []


func init_starting_deck():
	inventory.clear()
	hand.clear()
	active_dice.clear()
	
	for entry in DiceTypes.STARTING_INVENTORY:
		var type_id: String = entry[0]
		var count: int = entry[1]
		for i in range(count):
			var dice = DiceRegistry.create_instance(type_id)
			if dice:
				inventory.append(dice)
	
	inventory.shuffle()
	inventory_changed.emit()


func draw_initial_hand(count: int = 7):
	for i in range(count):
		if not inventory.is_empty():
			hand.append(inventory.pop_front())
	hand_changed.emit()
	inventory_changed.emit()


func draw_to_hand(count: int = 1):
	for i in range(count):
		if not inventory.is_empty():
			hand.append(inventory.pop_front())
	hand_changed.emit()
	inventory_changed.emit()


func select_random_active(count: int = 5):
	hand.shuffle()
	for i in range(count):
		if not hand.is_empty():
			active_dice.append(hand.pop_front())
	active_changed.emit()
	hand_changed.emit()


func return_active_to_hand():
	for dice in active_dice:
		hand.append(dice)
	active_dice.clear()
	active_changed.emit()
	hand_changed.emit()


func swap_dice(active_index: int, hand_index: int) -> bool:
	if active_index < 0 or active_index >= active_dice.size():
		return false
	if hand_index < 0 or hand_index >= hand.size():
		return false

	var temp = active_dice[active_index]
	active_dice[active_index] = hand[hand_index]
	hand[hand_index] = temp

	active_changed.emit()
	hand_changed.emit()
	return true


func get_inventory_count() -> int:
	return inventory.size()


func get_hand_count() -> int:
	return hand.size()
