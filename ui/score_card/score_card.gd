extends Control

signal category_selected(category_id: String, score: int)

@onready var category_container: VBoxContainer = $Panel/ScrollContainer/CategoryContainer

var category_buttons: Dictionary = {}
var current_scores: Dictionary = {}


func _ready():
	GameState.phase_changed.connect(_on_phase_changed)
	GameState.active_changed.connect(_on_active_changed)
	_create_category_buttons()
	visible = false


func _create_category_buttons():
	# 기존 버튼 제거
	for child in category_container.get_children():
		child.queue_free()
	category_buttons.clear()

	await get_tree().process_frame

	# 숫자 족보
	_add_section_label("Numbers")
	for cat_id in ["ones", "twos", "threes", "fours", "fives", "sixes"]:
		_add_category_button(cat_id)

	_add_section_label("Combinations")
	for cat_id in ["three_of_a_kind", "four_of_a_kind", "full_house",
					"small_straight", "large_straight", "yacht", "chance"]:
		_add_category_button(cat_id)


func _add_section_label(text: String):
	var label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 18)
	category_container.add_child(label)


func _add_category_button(category_id: String):
	var cat = CategoryRegistry.get_category(category_id)
	if cat == null:
		return

	var hbox = HBoxContainer.new()
	hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var button = Button.new()
	button.text = cat.display_name
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.custom_minimum_size = Vector2(0, 50)
	button.pressed.connect(_on_category_pressed.bind(category_id))

	var score_label = Label.new()
	score_label.name = "ScoreLabel"
	score_label.text = "0"
	score_label.custom_minimum_size = Vector2(60, 0)
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

	var upgrade_label = Label.new()
	upgrade_label.name = "UpgradeLabel"
	upgrade_label.text = ""
	upgrade_label.custom_minimum_size = Vector2(80, 0)

	hbox.add_child(button)
	hbox.add_child(score_label)
	hbox.add_child(upgrade_label)

	category_container.add_child(hbox)
	category_buttons[category_id] = {
		"container": hbox,
		"button": button,
		"score_label": score_label,
		"upgrade_label": upgrade_label
	}


func _on_phase_changed(phase):
	visible = phase == GameState.Phase.SCORING
	if visible:
		_update_scores()


func _on_active_changed():
	if visible:
		_update_scores()


func _update_scores():
	current_scores = Scoring.calculate_all_scores(GameState.active_dice)

	for cat_id in category_buttons:
		var btn_data = category_buttons[cat_id]
		var score = current_scores.get(cat_id, 0)
		var upgrade = MetaState.get_upgrade(cat_id)

		if score < 0:
			btn_data["button"].disabled = true
			btn_data["score_label"].text = "-"
		else:
			btn_data["button"].disabled = false
			btn_data["score_label"].text = str(score)

		# 강화 정보 표시
		if upgrade:
			var mult_text = "x%.1f" % upgrade.get_total_multiplier() if upgrade.get_total_multiplier() > 1.0 else ""
			var uses_text = "(%d/%d)" % [upgrade.get_remaining_uses(), upgrade.get_total_uses()]
			btn_data["upgrade_label"].text = mult_text + " " + uses_text


func _on_category_pressed(category_id: String):
	var score = current_scores.get(category_id, 0)
	if score >= 0:
		category_selected.emit(category_id, score)
