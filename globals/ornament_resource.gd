class_name OrnamentResource
extends Resource
## 오너먼트 타입 정의 — 테트리스 스타일 배치 아이템
## DiceTypeResource와 동일한 패턴 (정적 타입 데이터)

var id: String
var display_name: String
var description: String
var color: Color = Color.WHITE ## 그리드 셀 색상

## Shape: Vector2i 오프셋 배열 (앵커 = (0,0))
## L-shape 예: [Vector2i(0,0), Vector2i(1,0), Vector2i(2,0), Vector2i(2,1)]
var shape: Array[Vector2i] = [Vector2i.ZERO]

## 글로벌 패시브 효과 (GameState 직접 수정)
## {"type": "reroll_bonus"/"draw_bonus", "delta": 1}
var passive_effects: Array[Dictionary] = []

## 주사위 효과 (EffectProcessor에 주입)
var dice_effects: Array[DiceEffectResource] = []


#region Rotation
## 90° 시계방향 회전을 rotations번 적용한 shape 반환
## 변환: (x, y) → (y, -x) 반복 + normalize (모든 좌표 ≥ 0)
static func rotate_shape(base_shape: Array[Vector2i], rotations: int) -> Array[Vector2i]:
	var result := base_shape.duplicate()
	for _r in (rotations % 4):
		var rotated: Array[Vector2i] = []
		for offset in result:
			rotated.append(Vector2i(offset.y, -offset.x))
		# normalize: 모든 좌표를 0 이상으로
		var min_pos := Vector2i(999, 999)
		for r in rotated:
			min_pos = Vector2i(mini(min_pos.x, r.x), mini(min_pos.y, r.y))
		for i in rotated.size():
			rotated[i] -= min_pos
		result = rotated
	return result
#endregion
