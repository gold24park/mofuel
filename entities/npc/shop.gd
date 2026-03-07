extends Node2D

@onready var interactable: Area2D = $Interactable
@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	interactable.interact = _on_interact
	interactable.focused.connect(_show_interact_hints)
	interactable.unfocused.connect(_hide_interact_hints)
	_hide_interact_hints()

func _on_interact():
	_hide_interact_hints()
	print("shop")
	# TODO: await shop UI
	_show_interact_hints()

func _show_interact_hints() -> void:
	animated_sprite_2d.show()
	sprite_2d.material.set_shader_parameter("outline_width", 1.0)

func _hide_interact_hints() -> void:
	animated_sprite_2d.hide()
	sprite_2d.material.set_shader_parameter("outline_width", 0.0)
