extends Control

signal reroll_pressed
signal swap_pressed
signal end_turn_pressed

@onready var reroll_button: Button = $MarginContainer/HBoxContainer/RerollButton
@onready var swap_button: Button = $MarginContainer/HBoxContainer/ReplaceButton  # 씬 노드명 유지
@onready var end_turn_button: Button = $MarginContainer/HBoxContainer/EndTurnButton

var _selected_count: int = 0


func _ready():
	reroll_button.pressed.connect(_on_reroll_pressed)
	swap_button.pressed.connect(_on_swap_pressed)
	end_turn_button.pressed.connect(_on_end_turn_pressed)

	GameState.phase_changed.connect(_on_phase_changed)
	GameState.rerolls_changed.connect(_on_rerolls_changed)
	GameState.hand_changed.connect(_on_hand_changed)

	_update_buttons()


func set_selected_count(count: int):
	_selected_count = count
	_update_buttons()


func _update_buttons():
	var phase = GameState.current_phase

	# Swap: ROUND_START에서만 표시 (첫 굴림 전)
	swap_button.visible = phase == GameState.Phase.ROUND_START
	swap_button.disabled = not GameState.can_swap() or _selected_count != 1
	swap_button.text = "Swap" if GameState.can_swap() else "Swap (used)"

	# Reroll, End Turn: ACTION에서만 표시
	reroll_button.visible = phase == GameState.Phase.ACTION
	end_turn_button.visible = phase == GameState.Phase.ACTION

	reroll_button.disabled = not GameState.can_reroll() or _selected_count == 0

	if _selected_count > 0:
		reroll_button.text = "Reroll %d (%d)" % [_selected_count, GameState.rerolls_remaining]
	else:
		reroll_button.text = "Reroll (%d)" % GameState.rerolls_remaining


func _on_phase_changed(_phase):
	_selected_count = 0
	_update_buttons()


func _on_rerolls_changed(_remaining):
	_update_buttons()


func _on_hand_changed():
	_update_buttons()


func _on_reroll_pressed():
	reroll_pressed.emit()


func _on_swap_pressed():
	swap_pressed.emit()


func _on_end_turn_pressed():
	end_turn_pressed.emit()
