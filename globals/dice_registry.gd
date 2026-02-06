extends Node

const JSON_PATH := "res://resources/dice_types/dice_types.json"

var dice_types: Dictionary = {} # id -> DiceTypeResource
var _error_type: DiceTypeResource = null


func _ready():
	_load_all_dice_types()
	_error_type = dice_types.get("_error")


func _load_all_dice_types():
	var file := FileAccess.open(JSON_PATH, FileAccess.READ)
	if file == null:
		push_error("DiceRegistry: Cannot open JSON: " + JSON_PATH)
		return

	var json_text := file.get_as_text()
	file.close()

	var entries: Variant = JSON.parse_string(json_text)
	if entries == null or not entries is Array:
		push_error("DiceRegistry: Invalid JSON format")
		return

	for entry: Dictionary in entries:
		var dice_type := _parse_dice_type(entry)
		if dice_type:
			dice_types[dice_type.id] = dice_type


func _parse_dice_type(data: Dictionary) -> DiceTypeResource:
	var dt := DiceTypeResource.new()
	dt.id = data.get("id", "")
	dt.display_name = data.get("display_name", "")
	dt.description = data.get("description", "")

	# Groups
	var groups_data: Array = data.get("groups", [])
	var groups: Array[String] = []
	for g in groups_data:
		groups.append(g)
	dt.groups = groups

	# Texture (경로 문자열 → load)
	var tex_path: String = data.get("texture", "")
	if tex_path != "":
		dt.texture = load(tex_path)

	# Material (경로 문자열 → load)
	var mat_path: String = data.get("material", "")
	if mat_path != "":
		dt.material = load(mat_path)

	# Effects
	var effects_data: Array = data.get("effects", [])
	var effects: Array[DiceEffectResource] = []
	for effect_data: Dictionary in effects_data:
		var effect := _create_effect(effect_data)
		if effect:
			effects.append(effect)
	dt.effects = effects

	return dt


func _create_effect(data: Dictionary) -> DiceEffectResource:
	var type_name: String = data.get("type", "")
	match type_name:
		#region Special Effects (주사위 값 결정 — 클래스 유지)
		"BiasEffect":
			var effect := BiasEffect.new()
			effect.bias_values = _require_array_int(data, "bias_values")
			effect.bias_weight = _require_float(data, "bias_weight")
			return effect
		"FaceMapEffect":
			var effect := FaceMapEffect.new()
			effect.face_map = _require_array_int(data, "face_map")
			return effect
		"WildcardEffect":
			var effect := WildcardEffect.new()
			effect.trigger_values = _require_array_int(data, "trigger_values")
			return effect
		#endregion
		#region ModifierEffect (범용 점수 수정)
		"ModifierEffect":
			return _create_modifier_effect(data)
		#endregion
		_:
			push_warning("DiceRegistry: Unknown effect type: " + type_name)
			return null


#region ModifierEffect Parsing
## JSON 문자열 → DiceEffectResource.Target enum
const _TARGET_MAP := {
	"self": DiceEffectResource.Target.SELF,
	"adjacent": DiceEffectResource.Target.ADJACENT,
	"all_dice": DiceEffectResource.Target.ALL_DICE,
	"matching_value": DiceEffectResource.Target.MATCHING_VALUE,
	"matching_group": DiceEffectResource.Target.MATCHING_GROUP,
}

## JSON 문자열 → DiceEffectResource.Trigger enum
const _TRIGGER_MAP := {
	"on_roll": DiceEffectResource.Trigger.ON_ROLL,
	"on_keep": DiceEffectResource.Trigger.ON_KEEP,
	"on_score": DiceEffectResource.Trigger.ON_SCORE,
	"on_adjacent_roll": DiceEffectResource.Trigger.ON_ADJACENT_ROLL,
}

## JSON 문자열 → ModifierEffect.CompareField enum
const _FIELD_MAP := {
	"type": ModifierEffect.CompareField.TYPE,
	"group": ModifierEffect.CompareField.GROUP,
	"value": ModifierEffect.CompareField.VALUE,
	"probability": ModifierEffect.CompareField.PROBABILITY,
	"index": ModifierEffect.CompareField.INDEX,
}

## JSON 문자열 → ModifierEffect.CompareOp enum
const _OP_MAP := {
	"eq": ModifierEffect.CompareOp.EQ,
	"not": ModifierEffect.CompareOp.NOT,
	"in": ModifierEffect.CompareOp.IN,
	"gte": ModifierEffect.CompareOp.GTE,
	"lt": ModifierEffect.CompareOp.LT,
	"mod": ModifierEffect.CompareOp.MOD,
}

## JSON 문자열 → ModifierEffect.ModifyTarget enum
const _MODIFY_MAP := {
	"value_bonus": ModifierEffect.ModifyTarget.VALUE_BONUS,
	"value_multiplier": ModifierEffect.ModifyTarget.VALUE_MULTIPLIER,
	"permanent_bonus": ModifierEffect.ModifyTarget.PERMANENT_BONUS,
	"permanent_multiplier": ModifierEffect.ModifyTarget.PERMANENT_MULTIPLIER,
}


func _create_modifier_effect(data: Dictionary) -> ModifierEffect:
	var effect := ModifierEffect.new()

	# target (필수)
	var target_str := _require_string(data, "target")
	assert(_TARGET_MAP.has(target_str),
		"DiceRegistry: Unknown target '%s' in %s" % [target_str, data])
	effect.target = _TARGET_MAP[target_str]

	# trigger (선택, 기본값: on_score)
	var trigger_str: String = data.get("trigger", "on_score")
	assert(_TRIGGER_MAP.has(trigger_str),
		"DiceRegistry: Unknown trigger '%s' in %s" % [trigger_str, data])
	effect.trigger = _TRIGGER_MAP[trigger_str]

	# priority (선택, 기본값: 200)
	effect.priority = int(data.get("priority", 200))

	# effect_name (선택)
	effect.effect_name = data.get("effect_name", "")

	# value_to_change (필수)
	var modify_str := _require_string(data, "value_to_change")
	assert(_MODIFY_MAP.has(modify_str),
		"DiceRegistry: Unknown value_to_change '%s' in %s" % [modify_str, data])
	effect.modify_target = _MODIFY_MAP[modify_str]

	# diff (필수)
	assert(data.has("diff"), "DiceRegistry: Missing 'diff' in %s" % [data])
	effect.diff = float(data["diff"])

	# comparisons (선택)
	var comps_data: Array = data.get("comparisons", [])
	var comparisons: Array[Dictionary] = []
	for comp_data: Dictionary in comps_data:
		comparisons.append(_parse_comparison(comp_data))
	effect.comparisons = comparisons

	# 피드백 (선택)
	effect.anim = data.get("anim", "")
	effect.sound = data.get("sound", "")

	return effect


func _parse_comparison(data: Dictionary) -> Dictionary:
	var field_str := _require_string(data, "a")
	assert(_FIELD_MAP.has(field_str),
		"DiceRegistry: Unknown comparison field '%s' in %s" % [field_str, data])

	var result := {
		"a": _FIELD_MAP[field_str],
		"b": data["b"],
	}

	if data.has("op"):
		var op_str: String = data["op"]
		assert(_OP_MAP.has(op_str),
			"DiceRegistry: Unknown comparison op '%s' in %s" % [op_str, data])
		result["op"] = _OP_MAP[op_str]

	return result
#endregion


#region JSON Validation Helpers
## 필수 키가 없으면 assert로 즉시 실패 (개발 중 빠른 발견)
func _require_string(data: Dictionary, key: String) -> String:
	assert(data.has(key), "DiceRegistry: Missing required key '%s' in %s" % [key, data])
	return data[key]


func _require_int(data: Dictionary, key: String) -> int:
	assert(data.has(key), "DiceRegistry: Missing required key '%s' in %s" % [key, data])
	return int(data[key])


func _require_float(data: Dictionary, key: String) -> float:
	assert(data.has(key), "DiceRegistry: Missing required key '%s' in %s" % [key, data])
	return float(data[key])


func _require_array_int(data: Dictionary, key: String) -> Array[int]:
	assert(data.has(key), "DiceRegistry: Missing required key '%s' in %s" % [key, data])
	var raw: Array = data[key]
	var result: Array[int] = []
	for v in raw:
		result.append(int(v))
	return result
#endregion


func get_dice_type(id: String) -> DiceTypeResource:
	if dice_types.has(id):
		return dice_types[id]
	push_error("DiceRegistry: Unknown dice type: " + id)
	return _error_type


func get_all_types() -> Array:
	var result = []
	for type in dice_types.values():
		result.append(type)
	return result


func get_all_by_rarity(target_rarity: int) -> Array:
	var result = []
	for type in dice_types.values():
		if type.rarity == target_rarity:
			result.append(type)
	return result


func create_instance(type_id: String) -> DiceInstance:
	var dice_type := get_dice_type(type_id)
	# get_dice_type은 실패 시 _error_type 반환
	# _error_type도 null이면 (error.tres 로드 실패) 치명적 오류
	assert(dice_type != null, "DiceRegistry: Both requested type and error type are null")
	return DiceInstance.new(dice_type)


## 에러 주사위인지 확인 (디버깅/UI용)
func is_error_dice(instance: DiceInstance) -> bool:
	return instance != null and instance.type == _error_type
