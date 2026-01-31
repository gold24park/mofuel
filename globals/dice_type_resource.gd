class_name DiceTypeResource
extends Resource

@export var id: String = "normal"
@export var display_name: String = "일반 주사위"
@export var description: String = "1~6 균등 확률"

@export_group("Visual")
@export var texture: Texture2D  # UV 텍스처 (null이면 기본 텍스처 사용)
@export var material: Material  # 커스텀 머티리얼 (null이면 기본 + 텍스처)
@export var value_labels: Dictionary = {}  # {value: "표시 텍스트"} 예: {6: "?"}
@export var wildcard_label: String = "?"  # 와일드카드 기본 표시

@export var effects: Array[DiceEffectResource] = []


#region Effect Queries
func get_effect_of_type(effect_class: Variant) -> DiceEffectResource:
	for effect in effects:
		if is_instance_of(effect, effect_class):
			return effect
	return null


func has_effect_of_type(effect_class: Variant) -> bool:
	return get_effect_of_type(effect_class) != null
#endregion


#region Roll Logic
func apply_roll_effects(base_value: int) -> int:
	var result := base_value
	for effect in effects:
		result = effect.apply_to_roll(result)
	return result


func get_score_multiplier() -> float:
	var multiplier := 1.0
	for effect in effects:
		multiplier *= effect.get_score_multiplier()
	return multiplier
#endregion


#region Display Logic
func is_wildcard_value(value: int) -> bool:
	for effect in effects:
		if effect.is_wildcard_value(value):
			return true
	return false


func get_display_text(value: int) -> String:
	# 커스텀 라벨이 있으면 우선 사용
	if value_labels.has(value):
		return value_labels[value]
	# 와일드카드면 와일드카드 라벨
	if is_wildcard_value(value):
		return wildcard_label
	# 일반 값
	return str(value)
#endregion
