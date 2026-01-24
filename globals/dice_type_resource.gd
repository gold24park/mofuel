class_name DiceTypeResource
extends Resource

@export var id: String = "normal"
@export var display_name: String = "일반 주사위"
@export var description: String = "1~6 균등 확률"
@export var icon: Texture2D
@export var color: Color = Color.WHITE
@export var rarity: int = 1  # 1~5

@export var effects: Array[DiceEffectResource] = []


func has_effect(effect_type: DiceEffectResource.EffectType) -> bool:
	for effect in effects:
		if effect.type == effect_type:
			return true
	return false


func get_effect(effect_type: DiceEffectResource.EffectType) -> DiceEffectResource:
	for effect in effects:
		if effect.type == effect_type:
			return effect
	return null


func get_all_effects_of_type(effect_type: DiceEffectResource.EffectType) -> Array[DiceEffectResource]:
	var result: Array[DiceEffectResource] = []
	for effect in effects:
		if effect.type == effect_type:
			result.append(effect)
	return result
