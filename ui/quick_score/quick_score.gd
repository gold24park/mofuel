extends Control
## 빠른 점수 선택 패널
## 주사위가 굴려진 후 우측에 적용 가능한 족보를 표시

signal score_selected(category_id: String, score: int)
signal option_hovered(dice_indices: Array[int])
signal option_unhovered()

const MAX_VISIBLE_OPTIONS: int = 5

@onready var options_container: VBoxContainer = $PanelContainer/VBoxContainer

var _option_buttons: Array[Button] = []
var _current_options: Array[Dictionary] = []  # [{id, name, score, dice_indices}]
var _current_dice: Array = []


func _ready() -> void:
	GameState.phase_changed.connect(_on_phase_changed)
	visible = false
	_create_option_buttons()


func _create_option_buttons() -> void:
	for i in range(MAX_VISIBLE_OPTIONS):
		var button := Button.new()
		button.custom_minimum_size = Vector2(180, 50)
		button.size_flags_horizontal = Control.SIZE_SHRINK_END
		button.pressed.connect(_on_option_pressed.bind(i))
		button.mouse_entered.connect(_on_option_hovered.bind(i))
		button.mouse_exited.connect(_on_option_unhovered)
		options_container.add_child(button)
		_option_buttons.append(button)


func show_options(dice: Array) -> void:
	_current_options.clear()
	_current_dice = dice

	# 모든 카테고리 점수 계산
	var all_scores := Scoring.calculate_all_scores(dice)

	# 사용 가능하고 점수가 있는 카테고리만 필터링
	var valid_options: Array[Dictionary] = []
	for cat_id in all_scores:
		var score: int = all_scores[cat_id]
		if score > 0:  # 점수가 양수인 것만
			var cat = CategoryRegistry.get_category(cat_id)
			if cat:
				var relevant_indices := _get_relevant_dice_indices(cat, dice)
				valid_options.append({
					"id": cat_id,
					"name": cat.display_name,
					"score": score,
					"dice_indices": relevant_indices
				})

	# 점수 높은 순 정렬
	valid_options.sort_custom(func(a, b): return a["score"] > b["score"])

	# 상위 N개만 표시
	_current_options = valid_options.slice(0, MAX_VISIBLE_OPTIONS)

	# 버튼 업데이트
	for i in range(MAX_VISIBLE_OPTIONS):
		var button := _option_buttons[i]
		if i < _current_options.size():
			var option := _current_options[i]
			button.text = "%s  +%d" % [option["name"], option["score"]]
			button.visible = true
			button.disabled = false
		else:
			button.visible = false

	visible = _current_options.size() > 0


func _get_relevant_dice_indices(category, dice: Array) -> Array[int]:
	var indices: Array[int] = []
	var values: Array[int] = []

	for d in dice:
		values.append(d.current_value)

	match category.category_type:
		0, 1, 2, 3, 4, 5:  # ONES through SIXES
			var target: int = category.target_number
			for i in range(values.size()):
				if values[i] == target or _is_wildcard(dice[i]):
					indices.append(i)

		6, 7, 11:  # THREE_OF_A_KIND, FOUR_OF_A_KIND, YACHT
			var target_value: int = _get_most_common_value(values)
			for i in range(values.size()):
				if values[i] == target_value or _is_wildcard(dice[i]):
					indices.append(i)

		8:  # FULL_HOUSE
			for i in range(values.size()):
				indices.append(i)

		9, 10:  # SMALL_STRAIGHT, LARGE_STRAIGHT
			var straight_values := _get_straight_values(values, category.category_type == 10)
			for i in range(values.size()):
				if values[i] in straight_values or _is_wildcard(dice[i]):
					indices.append(i)

		12:  # CHANCE
			for i in range(values.size()):
				indices.append(i)

	return indices


func _is_wildcard(d: DiceInstance) -> bool:
	return d.is_wildcard()


func _get_most_common_value(values: Array[int]) -> int:
	var counts := {}
	for v in values:
		counts[v] = counts.get(v, 0) + 1

	var best_value := 0
	var best_count := 0
	for value in counts:
		if counts[value] > best_count:
			best_count = counts[value]
			best_value = value

	return best_value


func _get_straight_values(values: Array[int], is_large: bool) -> Array[int]:
	var unique: Array[int] = []
	for v in values:
		if v not in unique:
			unique.append(v)
	unique.sort()

	var patterns: Array
	if is_large:
		patterns = [[1, 2, 3, 4, 5], [2, 3, 4, 5, 6]]
	else:
		patterns = [[1, 2, 3, 4], [2, 3, 4, 5], [3, 4, 5, 6]]

	for pattern in patterns:
		var found := true
		for p in pattern:
			if p not in unique:
				found = false
				break
		if found:
			var result: Array[int] = []
			for p in pattern:
				result.append(p)
			return result

	return []


func hide_options() -> void:
	visible = false
	_current_options.clear()
	option_unhovered.emit()


func _on_option_pressed(index: int) -> void:
	if index < _current_options.size():
		var option := _current_options[index]
		option_unhovered.emit()
		score_selected.emit(option["id"], option["score"])
		hide_options()


func _on_option_hovered(index: int) -> void:
	if index < _current_options.size():
		var option := _current_options[index]
		option_hovered.emit(option["dice_indices"])


func _on_option_unhovered() -> void:
	option_unhovered.emit()


func _on_phase_changed(phase: int) -> void:
	# POST_ROLL이 아니면 숨김 (SCORING, ROLLING 등)
	if phase != GameState.Phase.POST_ROLL:
		hide_options()
