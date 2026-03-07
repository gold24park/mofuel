class_name GearInstance
extends RefCounted
## 배치 상태를 가진 기어 인스턴스
## DiceInstance와 동일한 패턴 (RefCounted)

var type: GearResource
var grid_position: Vector2i = Vector2i(-1, -1) ## 미배치 시 (-1, -1)
var rotation: int = 0 ## 0~3 (×90°)
var is_placed: bool = false


func _init(gear_type: GearResource) -> void:
	assert(gear_type != null, "GearInstance requires a valid GearResource")
	type = gear_type


## 현재 회전 적용된 shape 반환 (배치 위치 미적용)
func get_rotated_shape() -> Array[Vector2i]:
	return GearResource.rotate_shape(type.shape, rotation)


## 현재 위치 + 회전 기준 차지하는 셀 좌표 반환
func get_occupied_cells() -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for offset in get_rotated_shape():
		cells.append(grid_position + offset)
	return cells


## 시계방향 90° 회전
func rotate_cw() -> void:
	rotation = (rotation + 1) % 4
