extends Control

@onready var round_label: Label = $MarginContainer/HBoxContainer/RoundLabel
@onready var inventory_label: Label = $MarginContainer/HBoxContainer/InventoryLabel
@onready var hand_label: Label = $MarginContainer/HBoxContainer/ReserveLabel  ## 노드명 유지
@onready var score_label: Label = $MarginContainer/HBoxContainer/ScoreLabel
@onready var rerolls_label: Label = $MarginContainer/HBoxContainer/RerollsLabel


func _ready():
	GameState.round_changed.connect(_on_round_changed)
	GameState.inventory_changed.connect(_on_inventory_changed)
	GameState.hand_changed.connect(_on_hand_changed)
	GameState.score_changed.connect(_on_score_changed)
	GameState.rerolls_changed.connect(_on_rerolls_changed)

	_update_all()


func _update_all():
	_on_round_changed(GameState.current_round)
	_on_inventory_changed()
	_on_hand_changed()
	_on_score_changed(GameState.total_score)
	_on_rerolls_changed(GameState.rerolls_remaining)


func _on_round_changed(round_num: int):
	round_label.text = "Round: %d / %d" % [round_num, GameState.max_rounds]


func _on_inventory_changed():
	inventory_label.text = "Inventory: %d" % GameState.get_inventory_count()


func _on_hand_changed():
	hand_label.text = "Hand: %d" % GameState.get_hand_count()


func _on_score_changed(score: int):
	score_label.text = "Score: %d / %d" % [score, GameState.target_score]


func _on_rerolls_changed(remaining: int):
	rerolls_label.text = "Rerolls: %d" % remaining
