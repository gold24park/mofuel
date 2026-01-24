extends Control

signal reroll_pressed
signal replace_pressed
signal end_turn_pressed

@onready var reroll_button: Button = $MarginContainer/HBoxContainer/RerollButton
@onready var replace_button: Button = $MarginContainer/HBoxContainer/ReplaceButton
@onready var end_turn_button: Button = $MarginContainer/HBoxContainer/EndTurnButton

var _kept_count: int = 0


func _ready():
	reroll_button.pressed.connect(_on_reroll_pressed)
	replace_button.pressed.connect(_on_replace_pressed)
	end_turn_button.pressed.connect(_on_end_turn_pressed)

	GameState.phase_changed.connect(_on_phase_changed)
	GameState.rerolls_changed.connect(_on_rerolls_changed)
	GameState.reserve_changed.connect(_on_reserve_changed)

	_update_buttons()


func set_kept_count(count: int):
	_kept_count = count
	_update_buttons()


func _update_buttons():
	var phase = GameState.current_phase
	var unkept_count = 5 - _kept_count

	reroll_button.visible = phase == GameState.Phase.ACTION
	replace_button.visible = phase == GameState.Phase.ACTION
	end_turn_button.visible = phase == GameState.Phase.ACTION

	# 리롤: Keep되지 않은 주사위가 있고, 리롤 횟수가 남아있어야 함
	reroll_button.disabled = not GameState.can_reroll() or unkept_count == 0
	# Replace: Reserve가 있고, 주사위가 정확히 1개 Keep되어 있어야 함
	replace_button.disabled = not GameState.can_replace() or _kept_count != 1

	if unkept_count < 5:
		reroll_button.text = "Reroll %d (%d)" % [unkept_count, GameState.rerolls_remaining]
	else:
		reroll_button.text = "Reroll (%d)" % GameState.rerolls_remaining


func _on_phase_changed(_phase):
	_kept_count = 0
	_update_buttons()


func _on_rerolls_changed(_remaining):
	_update_buttons()


func _on_reserve_changed():
	_update_buttons()


func _on_reroll_pressed():
	reroll_pressed.emit()


func _on_replace_pressed():
	replace_pressed.emit()


func _on_end_turn_pressed():
	end_turn_pressed.emit()
