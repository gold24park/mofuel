class_name ActionEffect
extends DiceEffectResource
## 게임 상태 변경 효과 - 드로우 추가, 자신 파괴, 변환 등
## ModifierEffect(점수 수정)와 달리 게임 상태를 직접 변경


enum Action {
	ADD_DRAWS,    ## 드로우 횟수 추가
	DESTROY_SELF, ## 자신 파괴
	TRANSFORM,    ## 다른 주사위 타입으로 변환
}


var action: Action
var delta: int = 0
var params: Dictionary = {}


## config keys:
##   target: Target (필수)
##   action: Action (필수)
##   delta: int (선택, ADD_DRAWS 등에서 사용)
##   params: Dictionary (선택, TRANSFORM의 {to: "type_id"} 등)
##   effect_name: String (선택)
##   comparisons: Array[Dictionary] (선택)
##   anim: String (선택)
##   sound: String (선택)
func _init(config: Dictionary = {}) -> void:
	if config.is_empty():
		return
	assert(config.has("target"), "ActionEffect: missing 'target'")
	assert(config.has("action"), "ActionEffect: missing 'action'")

	target = config["target"]
	self.action = config["action"]
	self.delta = config.get("delta", 0)
	self.params = config.get("params", {})
	effect_name = config.get("effect_name", "")
	var raw_comps: Array = config.get("comparisons", [])
	comparisons = []
	for c in raw_comps:
		comparisons.append(c)
	anim = config.get("anim", "")
	sound = config.get("sound", "")
