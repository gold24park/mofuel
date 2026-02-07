class_name DiceTypeResource
extends Resource

#region Face Value Sentinels
const FACE_WILDCARD := 0 ## 와일드카드 — 스코어링에서 최적값 자동 할당
const FACE_SKULL := 7    ## 해골 — 스코어링에 포함되지 않음
#endregion

var id: String
var display_name: String
var description: String

var groups: Array[String] = [] ## 태그 (예: ["gem", "valuable"])

## 각 물리적 면의 논리적 값 (index 0 미사용, 1-6이 주사위 면)
## 1-6: 일반값, FACE_WILDCARD(0): 와일드카드, FACE_SKULL(7)+: 특수값
## 기본값: identity (변환 없음)
var face_values: Array[int] = [0, 1, 2, 3, 4, 5, 6]

var texture: Texture2D ## UV 텍스처 (null이면 기본 텍스처 사용)
var material: Material ## 커스텀 머티리얼 (null이면 기본 + 텍스처)

var effects: Array[DiceEffectResource] = []


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
#endregion


#region Face Values
## 물리적 면 값을 논리적 값으로 매핑
func map_face(physical_value: int) -> int:
	return face_values[physical_value]


## 특정 값이 와일드카드인지 확인
func is_wildcard_value(value: int) -> bool:
	if value < 1 or value > 6:
		return false
	return face_values[value] == FACE_WILDCARD
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
