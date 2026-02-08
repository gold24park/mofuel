class_name Inventory
extends RefCounted

## 플레이어의 영구 주사위 컬렉션
## 스테이지를 넘어 유지되며, 상점에서 매매 가능

signal changed

var dice: Array[DiceInstance] = []


func add(instance: DiceInstance) -> void:
	dice.append(instance)
	changed.emit()


func remove(instance: DiceInstance) -> bool:
	var idx := dice.find(instance)
	if idx == -1:
		return false
	dice.remove_at(idx)
	changed.emit()
	return true


func clear() -> void:
	dice.clear()
	changed.emit()


func size() -> int:
	return dice.size()


## 스테이지 시작 시 — 모든 주사위를 deep-copy하여 반환
func create_stage_copies() -> Array[DiceInstance]:
	var copies: Array[DiceInstance] = []
	for d in dice:
		copies.append(d.clone_for_stage())
	return copies


## 초기 인벤토리 구성 (게임 시작 시 1회)
func init_starting_inventory() -> void:
	dice.clear()
	for entry in DiceTypes.STARTING_INVENTORY:
		var type_id: String = entry[0]
		var count: int = entry[1]
		for i in range(count):
			var instance := DiceRegistry.create_instance(type_id)
			if instance:
				dice.append(instance)
	changed.emit()
