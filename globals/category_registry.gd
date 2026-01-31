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
				print("CategoryRegistry: Loaded category: ", res.id)
		file_name = dir.get_next()

	dir.list_dir_end()
	print("CategoryRegistry: Loaded ", categories.size(), " categories")


func get_category(id: String) -> CategoryResource:
	if categories.has(id):
		return categories[id]
	push_warning("CategoryRegistry: Unknown category: " + id)
	return null


func get_all_categories() -> Array[CategoryResource]:
	var result: Array[CategoryResource] = []
	result.assign(categories.values())
	return result


func get_number_categories() -> Array[CategoryResource]:
	return _filter_categories(func(cat: CategoryResource) -> bool: return cat.is_number_category())


func get_combination_categories() -> Array[CategoryResource]:
	return _filter_categories(func(cat: CategoryResource) -> bool: return not cat.is_number_category())


func _filter_categories(predicate: Callable) -> Array[CategoryResource]:
	var result: Array[CategoryResource] = []
	for cat in categories.values():
		if predicate.call(cat):
			result.append(cat)
	return result
