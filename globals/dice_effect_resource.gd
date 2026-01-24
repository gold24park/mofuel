class_name DiceEffectResource
extends Resource

enum EffectType {
	NONE,
	BIAS,              # 확률 조작
	FIXED_VALUE,       # 고정 값
	SCORE_MULTIPLIER,  # 점수 배수
	WILDCARD,          # 와일드카드
	REROLL,            # 자동 리롤
	COMBO_BONUS,       # 연속 사용 보너스
}

@export var type: EffectType = EffectType.NONE
@export var params: Dictionary = {}

# 파라미터 예시:
# BIAS: { "bias_values": [5, 6], "bias_weight": 0.5 }
# FIXED_VALUE: { "fixed_value": 6 }
# SCORE_MULTIPLIER: { "multiplier": 2.0 }
# WILDCARD: {} (파라미터 없음)
# COMBO_BONUS: { "bonus_per_combo": 5 }


func get_param(key: String, default_value = null):
	return params.get(key, default_value)
