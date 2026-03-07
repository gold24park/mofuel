class_name Deck
extends RefCounted

## 스테이지 로컬 덱 — pool(draw pile) + hand + active_dice 관리
## Inventory에서 deep-copy하여 생성, 스테이지 종료 시 폐기

signal pool_changed
signal hand_changed
signal active_changed

const HAND_MAX: int = 10
const ACTIVE_MAX: int = 5  ## Active 슬롯 수 (ACTIVE_MAX와 동일, Autoload 미참조)

var pool: Array[DiceInstance] = []
var hand: Array[DiceInstance] = []
var active_dice: Array[DiceInstance] = []


## Inventory에서 deep-copy하여 덱 초기화
func init_from_inventory(inv: Inventory) -> void:
	pool.clear()
	hand.clear()
	active_dice.clear()

	pool = inv.create_stage_copies()
	pool.shuffle()
	pool_changed.emit()


## pool에서 hand로 드로우 (초기/일반 통합)
## check_capacity=true: HAND_MAX 체크 (일반 드로우)
## check_capacity=false: 초기 드로우 (HAND_MAX 무시)
func draw_to_hand(count: int = 1, check_capacity: bool = true) -> void:
	for i in range(count):
		if pool.is_empty():
			break
		if check_capacity and hand.size() >= HAND_MAX:
			break
		hand.append(pool.pop_front())
	hand_changed.emit()
	pool_changed.emit()


func can_draw() -> bool:
	return not pool.is_empty() and (hand.size() + active_dice.size()) < HAND_MAX


func return_active_to_hand() -> void:
	for dice in active_dice:
		hand.append(dice)
	active_dice.clear()
	active_changed.emit()
	hand_changed.emit()


## Hand에서 선택된 인덱스들의 주사위를 Active로 이동
## @param hand_indices 이동할 Hand 내 인덱스 배열 (0-based)
## @return 성공 여부
func move_hand_to_active(hand_indices: Array[int]) -> bool:
	# 검증: DICE_COUNT개여야 하며, 모든 인덱스가 유효해야 함
	if hand_indices.size() != ACTIVE_MAX:
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
	if active_dice.size() >= ACTIVE_MAX:
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


## Hand 전체를 pool로 되돌리고 count개 새로 드로우
func redraw_hand(count: int) -> void:
	for dice in hand:
		pool.append(dice)
	hand.clear()
	pool.shuffle()
	draw_to_hand(count)


func get_pool_count() -> int:
	return pool.size()


func get_hand_count() -> int:
	return hand.size()
