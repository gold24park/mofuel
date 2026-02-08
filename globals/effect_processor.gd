class_name EffectProcessor
extends RefCounted
## 효과 처리 엔진 - 수집 → 적용 (ModifierEffect만 처리)


## 단일 효과 적용 정보 (추적용)
class PendingEffect:
	var effect: DiceEffectResource
	var context: EffectContext
	var target_indices: Array[int]

	func _init(eff: DiceEffectResource, ctx: EffectContext, targets: Array[int]) -> void:
		effect = eff
		context = ctx
		target_indices = targets


## 모든 효과 처리 (트리거 구분 없음)
## 반환: Dictionary - 타겟 인덱스별 효과 결과 배열
static func process_effects(all_dice: Array) -> Dictionary:
	# 1. 수집: 모든 효과 수집
	var pending: Array[PendingEffect] = []

	for i in all_dice.size():
		var dice: DiceInstance = all_dice[i]
		if dice == null:
			continue

		for effect: DiceEffectResource in dice.type.effects:
			# ActionEffect는 별도 처리 (점수 수정이 아닌 게임 상태 변경)
			if effect is ActionEffect:
				continue

			# 컨텍스트 생성
			var ctx := EffectContext.create(dice, i, all_dice)

			# 조건 확인
			if effect.condition and effect.condition.has_method("evaluate"):
				if not effect.condition.evaluate(dice, i):
					continue

			# 타겟 인덱스 계산
			var targets := effect.get_target_indices(ctx)
			if targets.is_empty():
				continue

			pending.append(PendingEffect.new(effect, ctx, targets))

	# 2. 적용: 타겟별로 결과 수집
	var results: Dictionary = {}

	for i in all_dice.size():
		results[i] = []

	for pe in pending:
		var result := pe.effect.evaluate(pe.context)
		if result == null or not result.has_effect():
			continue

		# 출처 정보 설정
		result.source_index = pe.context.source_index
		result.source_name = pe.context.source_dice.type.display_name if pe.context.source_dice else ""
		result.effect_name = pe.effect.effect_name

		# 각 타겟에 결과 추가
		for target_idx in pe.target_indices:
			assert(target_idx >= 0 and target_idx < all_dice.size(),
				"Invalid target_idx %d - bug in get_target_indices" % target_idx)
			var target_result: EffectResult = result.duplicate()
			target_result.target_index = target_idx
			results[target_idx].append(target_result)

	return results


## 결과 배열을 단일 병합 결과로 변환
static func merge_results(results: Array) -> EffectResult:
	var merged := EffectResult.new()
	for result in results:
		merged.merge(result)
	return merged
