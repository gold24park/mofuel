class_name ModifierEffect
extends DiceEffectResource
## 범용 수정 효과 - JSON에서 target/comparisons/value_to_change/delta 조합으로 정의


#region Enums
## 수정 대상 (value_to_change 필드)
enum ModifyTarget {
	VALUE_BONUS,            ## 임시 가산 (EffectResult.value_bonus)
	VALUE_MULTIPLIER,       ## 임시 배수 (EffectResult.value_multiplier)
	PERMANENT_BONUS,        ## 영구 가산 (EffectResult.permanent_bonus)
	PERMANENT_MULTIPLIER,   ## 영구 배수 (EffectResult.permanent_multiplier)
}
#endregion


var modify_target: ModifyTarget = ModifyTarget.VALUE_BONUS
var delta: float = 0.0


## config keys:
##   target: Target (필수)
##   modify_target: ModifyTarget (필수)
##   delta: float (필수)
##   effect_name: String (선택)
##   comparisons: Array[Dictionary] (선택)
##   anim: String (선택)
##   sound: String (선택)
func _init(config: Dictionary = {}) -> void:
	if config.is_empty():
		return
	assert(config.has("target"), "ModifierEffect: missing 'target'")
	assert(config.has("modify_target"), "ModifierEffect: missing 'modify_target'")
	assert(config.has("delta"), "ModifierEffect: missing 'delta'")

	target = config["target"]
	self.modify_target = config["modify_target"]
	self.delta = config["delta"]
	effect_name = config.get("effect_name", "")
	comparisons = config.get("comparisons", [])
	anim = config.get("anim", "")
	sound = config.get("sound", "")


## 효과 평가 — modify_target에 따라 EffectResult 필드 설정
func evaluate(context) -> EffectResult:
	var result := EffectResult.new()

	match modify_target:
		ModifyTarget.VALUE_BONUS:
			result.value_bonus = int(delta)
		ModifyTarget.VALUE_MULTIPLIER:
			result.value_multiplier = delta
		ModifyTarget.PERMANENT_BONUS:
			result.permanent_bonus = int(delta)
		ModifyTarget.PERMANENT_MULTIPLIER:
			result.permanent_multiplier = delta

	result.anim = anim
	result.sound = sound

	return result
