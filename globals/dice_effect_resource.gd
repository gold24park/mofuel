class_name DiceEffectResource
extends Resource
## Base class for dice effects. Subclass this for specific effect types.


#region Enums
enum Trigger {
	ON_ROLL,          ## 주사위 굴림 완료 후
	ON_KEEP,          ## 주사위 킵(잠금) 시
	ON_SCORE,         ## 점수 계산 시
	ON_ADJACENT_ROLL, ## 인접 주사위가 굴려졌을 때
}

enum Target {
	SELF,           ## 자신에게만 적용
	ADJACENT,       ## 좌/우 인접 주사위에 적용
	ALL_DICE,       ## 모든 활성 주사위에 적용
	MATCHING_VALUE, ## 같은 눈의 주사위에 적용
	MATCHING_GROUP, ## 같은 그룹 태그의 주사위에 적용
}
#endregion


#region Configuration
@export_group("Effect Trigger")
@export var trigger: Trigger = Trigger.ON_ROLL
@export var target: Target = Target.SELF
@export var condition: Resource = null  ## EffectCondition 타입

@export_group("Effect Metadata")
@export var priority: int = 100  ## 낮을수록 먼저 실행 (0-999)
@export var effect_name: String = ""  ## UI 표시용 (예: "인접 보너스")
#endregion


#region Core Methods
## 효과 평가 - 서브클래스에서 오버라이드
func evaluate(context) -> EffectResult:
	var result := EffectResult.new()

	# 조건 확인
	if condition and condition.has_method("evaluate"):
		if not condition.evaluate(context.source_dice, context.source_index):
			return result

	return result


## 타겟 인덱스 반환 (EffectProcessor에서 호출)
func get_target_indices(context) -> Array[int]:
	match target:
		Target.SELF:
			return [context.source_index] as Array[int]

		Target.ADJACENT:
			return context.get_adjacent_indices()

		Target.ALL_DICE:
			var indices: Array[int] = []
			for i in range(context.all_dice.size()):
				indices.append(i)
			return indices

		Target.MATCHING_VALUE:
			return context.get_matching_value_indices()

		Target.MATCHING_GROUP:
			var group := get_target_group()
			if group.is_empty():
				return [] as Array[int]
			return context.get_matching_group_indices(group)

	return [] as Array[int]


## MATCHING_GROUP용 - 서브클래스에서 오버라이드
func get_target_group() -> String:
	return ""
#endregion
