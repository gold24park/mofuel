class_name DrawButton
extends Control

## Deck에서 Hand로 주사위 드로우 버튼

signal draw_pressed

@onready var _button: Button = $Button


func _ready() -> void:
	_button.pressed.connect(func(): draw_pressed.emit())
	_button.disabled = true


func set_enabled(enabled: bool) -> void:
	_button.disabled = not enabled
