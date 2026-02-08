extends Node

var categories: Dictionary[String, CategoryResource] = {}


func _ready() -> void:
	_load_all_categories()


func _load_all_categories() -> void:
	var path := "res://resources/categories/"
	var dir := DirAccess.open(path)

	if dir == null:
		push_warning("CategoryRegistry: Cannot open directory: " + path)
		return

	dir.list_dir_begin()
	var file_name := dir.get_next()

	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".tres"):
			var res := load(path + file_name) as CategoryResource
			if res != null:
				categories[res.id] = res
		file_name = dir.get_next()

	dir.list_dir_end()


func get_category(id: String) -> CategoryResource:
	if categories.has(id):
		return categories[id]
	push_warning("CategoryRegistry: Unknown category: " + id)
	return null


func get_all_categories() -> Array[CategoryResource]:
	var result: Array[CategoryResource] = []
	result.assign(categories.values())
	return result


## 카테고리를 enum 순서로 정렬하여 반환
func get_sorted_categories() -> Array[CategoryResource]:
	var result: Array[CategoryResource] = []
	result.assign(categories.values())
	result.sort_custom(func(a, b): return a.category_type < b.category_type)
	return result
