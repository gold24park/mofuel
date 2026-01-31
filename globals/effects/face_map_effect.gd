class_name FaceMapEffect
extends DiceEffectResource
## 물리적 면 값을 다른 값으로 매핑

## index = 물리적 면 (0은 미사용), value = 표시 값
## [0, 1, 2, 3, 4, 5, 6] → 변환 없음 (기본값)
## [0, 6, 6, 6, 6, 6, 6] → 항상 6 (고정값)
## [0, 2, 2, 4, 4, 6, 6] → 짝수만
## [0, 1, 1, 3, 3, 5, 5] → 홀수만
@export var face_map: Array[int] = [0, 1, 2, 3, 4, 5, 6]


func apply_to_roll(base_value: int) -> int:
	if base_value >= 1 and base_value < face_map.size():
		return face_map[base_value]
	return base_value
