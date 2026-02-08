extends Control

signal restart_pressed
signal upgrade_pressed

@onready var title_label: Label = $Panel/VBoxContainer/TitleLabel
@onready var score_label: Label = $Panel/VBoxContainer/ScoreLabel
@onready var restart_button: Button = $Panel/VBoxContainer/RestartButton
@onready var upgrade_button: Button = $Panel/VBoxContainer/UpgradeButton


func _ready() -> void:
	GameState.game_over.connect(_on_game_over)
	restart_button.pressed.connect(_on_restart_pressed)
	upgrade_button.pressed.connect(_on_upgrade_pressed)
	visible = false


func _on_game_over(won: bool) -> void:
	visible = true

	if won:
		title_label.text = "Victory!"
		title_label.add_theme_color_override("font_color", Color.GREEN)
	else:
		title_label.text = "Game Over"
		title_label.add_theme_color_override("font_color", Color.RED)

	score_label.text = "Final Score: %d" % GameState.total_score


func _on_restart_pressed() -> void:
	visible = false
	restart_pressed.emit()


func _on_upgrade_pressed() -> void:
	visible = false
	upgrade_pressed.emit()
