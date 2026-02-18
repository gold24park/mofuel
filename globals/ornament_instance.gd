class_name OrnamentInstance
extends RefCounted
## 배치 상태를 가진 오너먼트 인스턴스
## DiceInstance와 동일한 패턴 (RefCounted)

var type: OrnamentResource
var grid_position: Vector2i = Vector2i(-1, -1) ## 미배치 시 (-1, -1)
var rotation: int = 0 ## 0~3 (×90°)
var is_placed: bool = false


func _init(ornament_type: OrnamentResource) -> void:
	assert(ornament_type != null, "OrnamentInstance requires a valid OrnamentResource")
	type = ornament_type


## 현재 회전 적용된 shape 반환 (배치 위치 미적용)
func get_rotated_shape() -> Array[Vector2i]:
	return OrnamentResource.rotate_shape(type.shape, rotation)


## 현재 위치 + 회전 기준 차지하는 셀 좌표 반환
func get_occupied_cells() -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for offset in get_rotated_shape():
		cells.append(grid_position + offset)
	return cells


## 시계방향 90° 회전
func rotate_cw() -> void:
	rotation = (rotation + 1) % 4
