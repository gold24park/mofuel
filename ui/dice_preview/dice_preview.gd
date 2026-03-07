extends SubViewportContainer

const DICE_MODEL = preload("res://assets/dice/dice.glb")

@onready var viewport: SubViewport = $SubViewport
@onready var dice_holder: Node3D = $SubViewport/DiceHolder

var dice_model: Node3D = null
var rotation_speed: float = 1.0
var dice_instance: DiceInstance = null
var _cached_mesh: MeshInstance3D = null


func _ready() -> void:
	_setup_dice()
	set_process(false)
	viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED


func _process(delta: float) -> void:
	if dice_model:
		dice_model.rotate_y(rotation_speed * delta)


func _notification(what: int) -> void:
	if what == NOTIFICATION_VISIBILITY_CHANGED:
		_update_rendering()


func _update_rendering() -> void:
	if not is_inside_tree() or viewport == null:
		return
	if is_visible_in_tree() and dice_instance:
		set_process(true)
		viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	else:
		set_process(false)
		viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED


func _setup_dice() -> void:
	dice_model = DICE_MODEL.instantiate()
	dice_holder.add_child(dice_model)
	dice_model.position = Vector3.ZERO
	dice_model.rotation = Vector3.ZERO
	# MeshInstance3D 캐싱 — 재귀 탐색 제거
	_cached_mesh = _find_first_mesh(dice_model)


func set_dice_instance(instance: DiceInstance) -> void:
	dice_instance = instance
	if dice_instance and dice_instance.type and _cached_mesh:
		dice_instance.type.apply_visual(_cached_mesh)
	_update_rendering()


## 노드 트리에서 첫 MeshInstance3D를 재귀 탐색 (초기화 시 1회만)
static func _find_first_mesh(node: Node) -> MeshInstance3D:
	if node == null:
		return null
	for child in node.get_children():
		if child is MeshInstance3D:
			return child
		var found := _find_first_mesh(child)
		if found:
			return found
	return null
