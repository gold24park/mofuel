class_name OrnamentGrid
extends RefCounted
## 6x6 그리드 순수 로직 — UI 없음
## 테트리스 스타일 오너먼트 배치 관리

const GRID_SIZE: int = 6

signal grid_changed

## 36 flat 배열 (y * GRID_SIZE + x), null = 빈칸, OrnamentInstance = 점유
var _cells: Array = []

## 배치된 오너먼트 목록
var placed_ornaments: Array[OrnamentInstance] = []


func _init() -> void:
	_cells.resize(GRID_SIZE * GRID_SIZE)
	_cells.fill(null)


#region Cell Access
func _cell_index(pos: Vector2i) -> int:
	return pos.y * GRID_SIZE + pos.x


func _is_in_bounds(pos: Vector2i) -> bool:
	return pos.x >= 0 and pos.x < GRID_SIZE and pos.y >= 0 and pos.y < GRID_SIZE


## 셀 조회 — 범위 밖이면 null
func get_cell(pos: Vector2i) -> OrnamentInstance:
	if not _is_in_bounds(pos):
		return null
	return _cells[_cell_index(pos)]
#endregion


#region Placement
## 배치 가능 여부 확인 (범위 + 충돌)
func can_place(ornament: OrnamentInstance, position: Vector2i) -> bool:
	var rotated := ornament.get_rotated_shape()
	for offset in rotated:
		var cell_pos := position + offset
		if not _is_in_bounds(cell_pos):
			return false
		if _cells[_cell_index(cell_pos)] != null:
			return false
	return true


## 배치 실행
func place(ornament: OrnamentInstance, position: Vector2i) -> bool:
	if not can_place(ornament, position):
		return false

	ornament.grid_position = position
	ornament.is_placed = true

	for offset in ornament.get_rotated_shape():
		var cell_pos := position + offset
		_cells[_cell_index(cell_pos)] = ornament

	placed_ornaments.append(ornament)
	grid_changed.emit()
	return true


## 제거
func remove(ornament: OrnamentInstance) -> bool:
	if not ornament.is_placed:
		return false

	for offset in ornament.get_rotated_shape():
		var cell_pos := ornament.grid_position + offset
		if _is_in_bounds(cell_pos):
			_cells[_cell_index(cell_pos)] = null

	ornament.grid_position = Vector2i(-1, -1)
	ornament.is_placed = false
	placed_ornaments.erase(ornament)
	grid_changed.emit()
	return true
#endregion


#region Effect Queries
## 배치된 전체 패시브 효과 수집
func get_all_passive_effects() -> Array[Dictionary]:
	var effects: Array[Dictionary] = []
	for ornament in placed_ornaments:
		for effect in ornament.type.passive_effects:
			effects.append(effect)
	return effects


## 배치된 전체 주사위 효과 수집
func get_all_dice_effects() -> Array[DiceEffectResource]:
	var effects: Array[DiceEffectResource] = []
	for ornament in placed_ornaments:
		for effect in ornament.type.dice_effects:
			effects.append(effect)
	return effects
#endregion
