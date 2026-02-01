class_name EffectProcessor
extends RefCounted
## 효과 처리 엔진 - 수집 → 정렬 → 적용 단계


## 단일 효과 적용 정보 (정렬 및 추적용)
class PendingEffect:
	var effect: DiceEffectResource
	var context: EffectContext  # EffectContext
	var target_indices: Array[int]
	var priority: int

	func _init(p_effect: DiceEffectResource, p_context: EffectContext, p_targets: Array[int]) -> void:
		effect = p_effect
		context = p_context
		target_indices = p_targets
		priority = p_effect.priority if p_effect else 100


## 주어진 트리거에 대해 모든 효과 처리
## 반환: Dictionary - 타겟 인덱스별 효과 결과 배열
static func process_trigger(
	trigger: int,
	all_dice: Array,
	triggering_index: int = -1
) -> Dictionary:
	# 1. 수집: 발동 가능한 모든 효과 수집
	var pending: Array = []

	for i in range(all_dice.size()):
		var dice = all_dice[i]
		if dice == null:
			continue

		for effect in dice.type.effects:
			# 트리거 타입 확인
			if not _should_trigger(effect, trigger, i, triggering_index):
				continue

			# 컨텍스트 생성
			var ctx := EffectContext.create(dice, i, all_dice, trigger)
			if triggering_index >= 0:
				ctx.with_triggering(all_dice[triggering_index], triggering_index)

			# 조건 확인
			if effect.condition and effect.condition.has_method("evaluate"):
				if not effect.condition.evaluate(dice, i):
					continue

			# 타겟 인덱스 계산
			var targets := _get_target_indices(effect, ctx)
			if targets.is_empty():
				continue

			pending.append(PendingEffect.new(effect, ctx, targets))

	# 2. 정렬: 우선순위 순 (낮은 값이 먼저)
	pending.sort_custom(func(a, b): return a.priority < b.priority)

	# 3. 적용: 타겟별로 결과 수집
	var results: Dictionary = {}

	for i in range(all_dice.size()):
		results[i] = []

	for pe in pending:
		var result = pe.effect.evaluate(pe.context)
		if result == null or not result.has_effect():
			continue

		# 출처 정보 설정
		result.source_index = pe.context.source_index
		result.source_name = pe.context.source_dice.type.display_name if pe.context.source_dice else ""
		result.effect_name = pe.effect.effect_name
		result.priority = pe.priority

		# 각 타겟에 결과 추가 (_get_target_indices가 유효한 인덱스만 반환)
		for target_idx in pe.target_indices:
			assert(target_idx >= 0 and target_idx < all_dice.size(),
				"Invalid target_idx %d - bug in _get_target_indices" % target_idx)
			var target_result := _copy_result(result)
			target_result.target_index = target_idx
			results[target_idx].append(target_result)

	return results


## 효과가 발동해야 하는지 확인
static func _should_trigger(
	effect: DiceEffectResource,
	trigger: int,
	source_index: int,
	triggering_index: int
) -> bool:
	if effect.trigger != trigger:
		return false

	# ON_ADJACENT_ROLL: 트리거 주사위가 인접해야 함
	if trigger == DiceEffectResource.Trigger.ON_ADJACENT_ROLL:
		if triggering_index < 0:
			return false
		if abs(triggering_index - source_index) != 1:
			return false

	return true


## 효과 타겟 인덱스 계산
static func _get_target_indices(effect: DiceEffectResource, ctx: EffectContext) -> Array[int]:
	match effect.target:
		DiceEffectResource.Target.SELF:
			return [ctx.source_index] as Array[int]

		DiceEffectResource.Target.ADJACENT:
			return ctx.get_adjacent_indices()

		DiceEffectResource.Target.ALL_DICE:
			var indices: Array[int] = []
			for i in range(ctx.all_dice.size()):
				indices.append(i)
			return indices

		DiceEffectResource.Target.MATCHING_VALUE:
			return ctx.get_matching_value_indices()

		DiceEffectResource.Target.MATCHING_GROUP:
			if effect.has_method("get_target_group"):
				var group: String = effect.get_target_group()
				return ctx.get_matching_group_indices(group)
			return [] as Array[int]

	return [] as Array[int]


## 결과 복사 (각 타겟에 별도 인스턴스 필요)
static func _copy_result(original) -> EffectResult:
	var copy := EffectResult.new()
	copy.value_bonus = original.value_bonus
	copy.value_multiplier = original.value_multiplier
	copy.permanent_bonus = original.permanent_bonus
	copy.permanent_multiplier = original.permanent_multiplier
	copy.is_wildcard = original.is_wildcard
	copy.modified_roll_value = original.modified_roll_value
	copy.priority = original.priority
	copy.source_index = original.source_index
	copy.source_name = original.source_name
	copy.effect_name = original.effect_name
	return copy


## 결과 배열을 단일 병합 결과로 변환
static func merge_results(results: Array) -> EffectResult:
	var merged := EffectResult.new()
	for result in results:
		merged.merge(result)
	return merged
