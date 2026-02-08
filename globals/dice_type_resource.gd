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
	# 베이스 결정: 커스텀 머티리얼 > 메시 기본 머티리얼
	var base_mat: StandardMaterial3D
	if material:
		base_mat = material.duplicate() as StandardMaterial3D
	elif mesh_instance.get_active_material(0):
		base_mat = mesh_instance.get_active_material(0).duplicate() as StandardMaterial3D
	else:
		return
	# 텍스처를 Detail Layer로 적용 (알파 기반 블렌딩)
	# mix(머티리얼색, 텍스처RGB, 텍스처Alpha) → 투명=머티리얼, 불투명=텍스처색
	if texture:
		base_mat.detail_enabled = true
		base_mat.detail_blend_mode = BaseMaterial3D.BLEND_MODE_MIX
		base_mat.detail_albedo = texture
		base_mat.detail_uv_layer = BaseMaterial3D.DETAIL_UV_1
	mesh_instance.material_override = base_mat
#endregion
