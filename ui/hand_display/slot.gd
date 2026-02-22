class_name Slot
extends Control

@onready var dice_preview: SubViewportContainer = $DicePreview

func set_dice_instance(dice_instance: DiceInstance) -> void:
	if dice_instance == null:
		dice_preview.visible = false
	else:
		dice_preview.visible = true
		dice_preview.set_dice_instance(dice_instance)
