class_name DiceTypeResource
extends Resource

#region Face Value Sentinels
const FACE_WILDCARD := 0 ## 와일드카드 — 스코어링에서 최적값 자동 할당
const FACE_SKULL := 7    ## 해골 — 스코어링에 포함되지 않음
#endregion

const PS1_SHADER = preload("res://shaders/ps1.gdshader")

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
	mesh_instance.material_override = null
	# 베이스 색상 추출: 커스텀 머티리얼 > 메시 기본 머티리얼
	var base_mat: Material = material if material else mesh_instance.get_active_material(0)
	if base_mat == null:
		return
	var base_color := Color.WHITE
	if base_mat is StandardMaterial3D:
		base_color = (base_mat as StandardMaterial3D).albedo_color
	# PS1 ShaderMaterial 생성
	var ps1_mat := ShaderMaterial.new()
	ps1_mat.shader = PS1_SHADER
	ps1_mat.set_shader_parameter("albedo_color", base_color)
	if texture:
		ps1_mat.set_shader_parameter("detail_texture", texture)
		ps1_mat.set_shader_parameter("has_detail", true)
	mesh_instance.material_override = ps1_mat
#endregion
