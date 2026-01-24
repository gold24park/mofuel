extends Node

const CategoryResourceScript = preload("res://globals/category_resource.gd")

var categories: Dictionary = {}  # id -> CategoryResource


func _ready():
	_load_all_categories()


func _load_all_categories():
	var path = "res://resources/categories/"
	var dir = DirAccess.open(path)

	if dir == null:
		push_warning("CategoryRegistry: Cannot open directory: " + path)
		return

	dir.list_dir_begin()
	var file_name = dir.get_next()

	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".tres"):
			var res = load(path + file_name)
			if res != null and res.get_script() == CategoryResourceScript:
				categories[res.id] = res
				print("CategoryRegistry: Loaded category: ", res.id)
		file_name = dir.get_next()

	dir.list_dir_end()
	print("CategoryRegistry: Loaded ", categories.size(), " categories")


func get_category(id: String) -> Resource:
	if categories.has(id):
		return categories[id]
	push_warning("CategoryRegistry: Unknown category: " + id)
	return null


func get_all_categories() -> Array:
	var result = []
	for cat in categories.values():
		result.append(cat)
	return result


func get_number_categories() -> Array:
	var result = []
	for cat in categories.values():
		if cat.category_type <= 5:  # SIXES
			result.append(cat)
	return result


func get_combination_categories() -> Array:
	var result = []
	for cat in categories.values():
		if cat.category_type > 5:  # > SIXES
			result.append(cat)
	return result
