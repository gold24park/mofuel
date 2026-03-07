extends Control

signal restart_pressed
signal upgrade_pressed
signal gear_pressed

@onready var title_label: Label = $Panel/VBoxContainer/TitleLabel
@onready var score_label: Label = $Panel/VBoxContainer/ScoreLabel
@onready var restart_button: Button = $Panel/VBoxContainer/RestartButton
@onready var upgrade_button: Button = $Panel/VBoxContainer/UpgradeButton
@onready var gear_button: Button = $Panel/VBoxContainer/GearButton


func _ready() -> void:
	GameState.game_over.connect(_on_game_over)
	restart_button.pressed.connect(_on_restart_pressed)
	upgrade_button.pressed.connect(_on_upgrade_pressed)
	gear_button.pressed.connect(_on_gear_pressed)
	visible = false


func _on_game_over(won: bool) -> void:
	visible = true

	if won:
		title_label.text = "Escaped!"
		title_label.add_theme_color_override("font_color", Color.GREEN)
		score_label.text = "Distance: %.0f / %.0f\nTime: %.1f" % [
			GameState.target_distance - GameState.remaining_distance,
			GameState.target_distance,
			GameState.remaining_time]
	else:
		title_label.text = "Busted!"
		title_label.add_theme_color_override("font_color", Color.RED)
		score_label.text = "Distance remaining: %.0f" % GameState.remaining_distance


func _on_restart_pressed() -> void:
	visible = false
	restart_pressed.emit()


func _on_upgrade_pressed() -> void:
	visible = false
	upgrade_pressed.emit()


func _on_gear_pressed() -> void:
	visible = false
	gear_pressed.emit()
