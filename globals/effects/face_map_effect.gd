class_name FaceMapEffect
extends DiceEffectResource
## 물리적 면 값을 다른 값으로 매핑

## face_map must have exactly 7 elements (index 0 unused, 1-6 for dice faces)
## [0, 1, 2, 3, 4, 5, 6] → 변환 없음 (기본값)
## [0, 6, 6, 6, 6, 6, 6] → 항상 6 (고정값)
## [0, 2, 2, 4, 4, 6, 6] → 짝수만
## [0, 1, 1, 3, 3, 5, 5] → 홀수만
@export var face_map: Array[int] = [0, 1, 2, 3, 4, 5, 6]:
	set(value):
		face_map = value
		assert(face_map.size() == 7, "face_map must have exactly 7 elements")
		for i in range(1, 7):
			assert(face_map[i] >= 1 and face_map[i] <= 6,
				"face_map[%d] must be 1-6, got %d" % [i, face_map[i]])


func _init() -> void:
	trigger = Trigger.ON_ROLL
	target = Target.SELF
	priority = 60  # BiasEffect 후에 적용
	effect_name = "면 매핑"


func evaluate(context: EffectContext) -> EffectResult:
	var result := EffectResult.new()
	var base_value: int = context.source_dice.current_value
	var mapped := face_map[base_value]
	if mapped != base_value:
		result.modified_roll_value = mapped
	return result
