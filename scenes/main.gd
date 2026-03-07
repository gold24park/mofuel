extends Control

## 씬 매니저 — game/base_camp 등의 씬을 동적으로 전환

enum Scene { GAME, BASE_CAMP }

const SCENE_PATHS: Dictionary[Scene, String] = {
	Scene.GAME: "res://scenes/game/game.tscn",
	Scene.BASE_CAMP: "res://scenes/base_camp/base_camp.tscn",
}

@export var start_scene: Scene = Scene.GAME

var _current_scene: Node
var _current_scene_id: Scene


func _ready() -> void:
	go_to(start_scene)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("debug_swap_scene"):
		var next: Scene = Scene.BASE_CAMP if _current_scene_id == Scene.GAME else Scene.GAME
		go_to(next)


func go_to(scene_id: Scene) -> void:
	if _current_scene:
		_current_scene.queue_free()
		await _current_scene.tree_exited
	_current_scene_id = scene_id
	_current_scene = load(SCENE_PATHS[scene_id]).instantiate()
	add_child(_current_scene)
	if _current_scene is Control:
		_current_scene.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
