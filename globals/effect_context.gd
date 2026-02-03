class_name EffectContext
extends RefCounted
## 효과 실행 시 전달되는 컨텍스트 정보


## 효과를 소유한 주사위 (DiceInstance)
var source_dice = null

## 소유 주사위의 인덱스 (0-4)
var source_index: int = -1

## 모든 활성 주사위 배열
var all_dice: Array = []

## 현재 트리거 타입 (DiceEffectResource.Trigger)
var trigger: int = 0

## ON_ADJACENT_ROLL용 - 굴림을 발생시킨 인접 주사위
var triggering_dice = null
var triggering_index: int = -1


static func create(
	p_source_dice,
	p_source_index: int,
	p_all_dice: Array,
	p_trigger: int
) -> EffectContext:
	# Validate at creation time
	assert(p_source_dice != null, "source_dice cannot be null")
	assert(p_source_index >= 0 and p_source_index < p_all_dice.size(),
		"source_index %d out of bounds for all_dice size %d" % [p_source_index, p_all_dice.size()])

	var ctx := EffectContext.new()
	ctx.source_dice = p_source_dice
	ctx.source_index = p_source_index
	ctx.all_dice = p_all_dice
	ctx.trigger = p_trigger
	return ctx


func with_triggering(p_triggering_dice, p_triggering_index: int) -> EffectContext:
	triggering_dice = p_triggering_dice
	triggering_index = p_triggering_index
	return self


## 인접 주사위 인덱스 반환 (좌/우)
func get_adjacent_indices() -> Array[int]:
	var indices: Array[int] = []
	if source_index > 0:
		indices.append(source_index - 1)
	if source_index < all_dice.size() - 1:
		indices.append(source_index + 1)
	return indices


## 같은 값의 주사위 인덱스 반환
func get_matching_value_indices() -> Array[int]:
	var indices: Array[int] = []
	if source_dice == null:
		return indices
	var my_value: int = source_dice.current_value
	for i in range(all_dice.size()):
		if i != source_index and all_dice[i].current_value == my_value:
			indices.append(i)
	return indices


## 같은 그룹의 주사위 인덱스 반환
func get_matching_group_indices(group: String) -> Array[int]:
	var indices: Array[int] = []
	for i in range(all_dice.size()):
		if i != source_index and all_dice[i].type.has_group(group):
			indices.append(i)
	return indices
	
## 같은 타입의 주사위 인덱스 반환
func get_matching_type_indices(type_id: String) -> Array[int]:
	var indices: Array[int] = []
	for i in range(all_dice.size()):
		if i != source_index and all_dice[i].type.id == type_id:
			indices.append(i)
	return indices
