extends Area2D

signal focused
signal unfocused

@export var interact_name: String = ""
@export var is_interactable: bool = true

var interact: Callable = func():
	pass
