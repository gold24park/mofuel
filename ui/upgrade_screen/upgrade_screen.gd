extends Control

signal continue_pressed

@onready var hand_rank_container: VBoxContainer = $Panel/ScrollContainer/HandRankContainer
@onready var continue_button: Button = $Panel/ContinueButton


func _ready() -> void:
	continue_button.pressed.connect(_on_continue_pressed)
	visible = false


func show_upgrades() -> void:
	visible = true
	_populate_hand_ranks()


func _populate_hand_ranks() -> void:
	# 기존 항목 제거
	for child in hand_rank_container.get_children():
		child.queue_free()

	await get_tree().process_frame

	for hr in HandRankRegistry.get_all_hand_ranks():
		var upgrade = MetaState.get_upgrade(hr.id)
		if upgrade == null:
			continue

		var hbox = HBoxContainer.new()
		hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		# Hand Rank 이름
		var name_label = Label.new()
		name_label.text = hr.display_name
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		# 현재 상태
		var status_label = Label.new()
		status_label.text = "Mult: x%.1f" % upgrade.get_total_multiplier()
		status_label.custom_minimum_size = Vector2(40, 0)

		# 배수 강화 버튼
		var mult_button = Button.new()
		mult_button.text = "+Mult"
		mult_button.custom_minimum_size = Vector2(27, 13)
		mult_button.disabled = not upgrade.can_upgrade_multiplier()
		mult_button.pressed.connect(_on_upgrade_mult.bind(hr.id, hbox))

		hbox.add_child(name_label)
		hbox.add_child(status_label)
		hbox.add_child(mult_button)

		hand_rank_container.add_child(hbox)


func _on_upgrade_mult(hand_rank_id: String, hbox: HBoxContainer) -> void:
	MetaState.upgrade_multiplier(hand_rank_id)
	_update_row(hand_rank_id, hbox)


func _update_row(hand_rank_id: String, hbox: HBoxContainer) -> void:
	var hr = HandRankRegistry.get_hand_rank(hand_rank_id)
	var upgrade = MetaState.get_upgrade(hand_rank_id)
	if hr == null or upgrade == null:
		return

	# 상태 라벨 업데이트
	var status_label = hbox.get_child(1) as Label
	status_label.text = "Mult: x%.1f" % upgrade.get_total_multiplier()

	# 버튼 상태 업데이트
	var mult_button = hbox.get_child(2) as Button
	mult_button.disabled = not upgrade.can_upgrade_multiplier()


func _on_continue_pressed() -> void:
	visible = false
	continue_pressed.emit()
