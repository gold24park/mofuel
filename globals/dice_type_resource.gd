class_name DiceTypeResource
extends Resource

@export var id: String = "normal"
@export var display_name: String = "일반 주사위"
@export var description: String = "1~6 균등 확률"

@export_group("Groups")
@export var groups: Array[String] = []  ## 태그 (예: ["gem", "valuable"])

@export_group("Visual")
@export var texture: Texture2D  # UV 텍스처 (null이면 기본 텍스처 사용)
@export var material: Material  # 커스텀 머티리얼 (null이면 기본 + 텍스처)
@export var value_labels: Dictionary = {}  # {value: "표시 텍스트"} 예: {6: "?"}
@export var wildcard_label: String = "?"  # 와일드카드 기본 표시

@export var effects: Array[DiceEffectResource] = []


#region Group Queries
func has_group(group: String) -> bool:
	return group in groups


func has_any_group(check_groups: Array[String]) -> bool:
	for g in check_groups:
		if g in groups:
			return true
	return false
#endregion


#region Effect Queries
func get_effect_of_type(effect_class: Variant) -> DiceEffectResource:
	for effect in effects:
		if is_instance_of(effect, effect_class):
			return effect
	return null


func has_effect_of_type(effect_class: Variant) -> bool:
	return get_effect_of_type(effect_class) != null


func get_effects_by_trigger(trigger: DiceEffectResource.Trigger) -> Array[DiceEffectResource]:
	var result: Array[DiceEffectResource] = []
	for effect in effects:
		if effect.trigger == trigger:
			result.append(effect)
	return result
#endregion


#region Wildcard Query
## 특정 값이 와일드카드인지 확인 (WildcardEffect 기반)
func is_wildcard_value(value: int) -> bool:
	for effect in effects:
		if effect is WildcardEffect:
			if value in effect.trigger_values:
				return true
	return false
#endregion


#region Display Logic
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


#region Visual
func apply_visual(mesh_instance: MeshInstance3D) -> void:
	if mesh_instance == null:
		return
	# 커스텀 머티리얼이 있으면 그대로 사용
	if material:
		mesh_instance.material_override = material
		return
	# 텍스처만 있으면 기존 머티리얼 복제 후 텍스처 교체
	if texture:
		var base_mat := mesh_instance.get_active_material(0)
		if base_mat:
			var new_mat := base_mat.duplicate() as StandardMaterial3D
			new_mat.albedo_texture = texture
			mesh_instance.material_override = new_mat
#endregion
