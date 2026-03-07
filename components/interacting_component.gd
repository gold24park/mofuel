extends Node2D

var current_interactions: Array[Area2D] = []
var can_interact := true
var _needs_sort := false


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") and can_interact:
		if current_interactions:
			if _needs_sort:
				current_interactions.sort_custom(_sort_by_nearest)
				_needs_sort = false
			can_interact = false
			await current_interactions[0].interact.call()
			can_interact = true


func _sort_by_nearest(area1: Area2D, area2: Area2D) -> bool:
	return global_position.distance_to(area1.global_position) > \
		global_position.distance_to(area2.global_position)


func _on_interact_range_area_entered(area: Area2D) -> void:
	current_interactions.push_back(area)
	_needs_sort = true
	area.focused.emit()


func _on_interact_range_area_exited(area: Area2D) -> void:
	current_interactions.erase(area)
	_needs_sort = true
	area.unfocused.emit()

