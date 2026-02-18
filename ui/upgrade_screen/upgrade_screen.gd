extends Control

signal continue_pressed

@onready var category_container: VBoxContainer = $Panel/ScrollContainer/CategoryContainer
@onready var continue_button: Button = $Panel/ContinueButton


func _ready():
	continue_button.pressed.connect(_on_continue_pressed)
	visible = false


func show_upgrades():
	visible = true
	_populate_categories()


func _populate_categories():
	# 기존 항목 제거
	for child in category_container.get_children():
		child.queue_free()

	await get_tree().process_frame

	for cat in CategoryRegistry.get_all_categories():
		var upgrade = MetaState.get_upgrade(cat.id)
		if upgrade == null:
			continue

		var hbox = HBoxContainer.new()
		hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		# 카테고리 이름
		var name_label = Label.new()
		name_label.text = cat.display_name
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		# 현재 상태
		var status_label = Label.new()
		status_label.text = "Mult: x%.1f" % upgrade.get_total_multiplier()
		status_label.custom_minimum_size = Vector2(120, 0)

		# 배수 강화 버튼
		var mult_button = Button.new()
		mult_button.text = "+Mult"
		mult_button.custom_minimum_size = Vector2(80, 40)
		mult_button.disabled = not upgrade.can_upgrade_multiplier()
		mult_button.pressed.connect(_on_upgrade_mult.bind(cat.id, hbox))

		hbox.add_child(name_label)
		hbox.add_child(status_label)
		hbox.add_child(mult_button)

		category_container.add_child(hbox)


func _on_upgrade_mult(category_id: String, hbox: HBoxContainer):
	MetaState.upgrade_multiplier(category_id)
	_update_row(category_id, hbox)


func _update_row(category_id: String, hbox: HBoxContainer):
	var cat = CategoryRegistry.get_category(category_id)
	var upgrade = MetaState.get_upgrade(category_id)
	if cat == null or upgrade == null:
		return

	# 상태 라벨 업데이트
	var status_label = hbox.get_child(1) as Label
	status_label.text = "Mult: x%.1f" % upgrade.get_total_multiplier()

	# 버튼 상태 업데이트
	var mult_button = hbox.get_child(2) as Button
	mult_button.disabled = not upgrade.can_upgrade_multiplier()


func _on_continue_pressed():
	visible = false
	continue_pressed.emit()
