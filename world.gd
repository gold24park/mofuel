extends Node3D

@onready var result_label = $CanvasLayer/ResultLabel

func _ready():
	Engine.time_scale = 2.0

func _on_dice_roll_finished(value: int) -> void:
	result_label.text = str(value)
