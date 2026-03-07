extends Node

var hand_ranks: Dictionary[String, HandRankResource] = {}


func _ready() -> void:
	_load_all_hand_ranks()


func _load_all_hand_ranks() -> void:
	var path := "res://resources/hand_ranks/"
	var dir := DirAccess.open(path)

	if dir == null:
		push_warning("HandRankRegistry: Cannot open directory: %s" % path)
		return

	dir.list_dir_begin()
	var file_name := dir.get_next()

	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".tres"):
			var res := load(path + file_name) as HandRankResource
			if res != null:
				hand_ranks[res.id] = res
		file_name = dir.get_next()

	dir.list_dir_end()


func get_hand_rank(id: String) -> HandRankResource:
	if hand_ranks.has(id):
		return hand_ranks[id]
	push_warning("HandRankRegistry: Unknown hand rank: %s" % id)
	return null


func get_all_hand_ranks() -> Array[HandRankResource]:
	var result: Array[HandRankResource] = []
	result.assign(hand_ranks.values())
	return result
