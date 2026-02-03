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


## Hand에서 선택된 인덱스들의 주사위를 Active로 이동
## @param hand_indices 이동할 Hand 내 인덱스 배열 (0-based)
## @return 성공 여부
func move_hand_to_active(hand_indices: Array[int]) -> bool:
	# 검증: 5개여야 하며, 모든 인덱스가 유효해야 함
	if hand_indices.size() != 5:
		return false
	for idx in hand_indices:
		if idx < 0 or idx >= hand.size():
			return false

	# 내림차순 정렬하여 뒤에서부터 제거 (인덱스 밀림 방지)
	var sorted_indices := hand_indices.duplicate()
	sorted_indices.sort()
	sorted_indices.reverse()

	# 선택된 주사위들을 임시 배열에 저장
	var selected_dice: Array[DiceInstance] = []
	for idx in hand_indices:
		selected_dice.append(hand[idx])

	# 뒤에서부터 제거
	for idx in sorted_indices:
		hand.remove_at(idx)

	# Active에 추가 (선택 순서 유지)
	active_dice.clear()
	for dice in selected_dice:
		active_dice.append(dice)

	active_changed.emit()
	hand_changed.emit()
	return true


## Hand에서 단일 주사위를 Active로 이동
## @param hand_index Hand 내 인덱스
## @return 성공 시 Active 내 인덱스, 실패 시 -1
func move_single_to_active(hand_index: int) -> int:
	if hand_index < 0 or hand_index >= hand.size():
		return -1
	if active_dice.size() >= 5:
		return -1

	var dice := hand[hand_index]
	hand.remove_at(hand_index)
	active_dice.append(dice)

	var active_index := active_dice.size() - 1
	active_changed.emit()
	hand_changed.emit()
	return active_index


## Active에서 단일 주사위를 Hand로 이동
## @param active_index Active 내 인덱스
## @return 성공 시 Hand 내 인덱스, 실패 시 -1
func move_single_to_hand(active_index: int) -> int:
	if active_index < 0 or active_index >= active_dice.size():
		return -1

	var dice := active_dice[active_index]
	active_dice.remove_at(active_index)
	hand.append(dice)

	var hand_index := hand.size() - 1
	active_changed.emit()
	hand_changed.emit()
	return hand_index


## Active 주사위들을 주어진 인덱스 순서대로 재정렬
## @param new_order_indices 현재 active_dice의 인덱스들로 구성된 새 순서 배열
func reorder_active_dice(new_order_indices: Array[int]) -> void:
	if new_order_indices.size() != active_dice.size():
		return
		
	var new_active: Array[DiceInstance] = []
	for idx in new_order_indices:
		new_active.append(active_dice[idx])
		
	active_dice = new_active
	active_changed.emit()


func get_inventory_count() -> int:
	return inventory.size()


func get_hand_count() -> int:
	return hand.size()
