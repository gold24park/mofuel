extends Control

@onready var round_label: Label = $MarginContainer/HBoxContainer/RoundLabel
@onready var inventory_label: Label = $MarginContainer/HBoxContainer/InventoryLabel
@onready var hand_label: Label = $MarginContainer/HBoxContainer/ReserveLabel ## 노드명 유지
@onready var score_label: Label = $MarginContainer/HBoxContainer/ScoreLabel
@onready var rerolls_label: Label = $MarginContainer/HBoxContainer/RerollsLabel
@onready var draws_label: Label = $MarginContainer/HBoxContainer/DrawsLabel


func _ready() -> void:
	GameState.round_changed.connect(_on_round_changed)
	GameState.pool_changed.connect(_on_pool_changed)
	GameState.hand_changed.connect(_on_hand_changed)
	GameState.score_changed.connect(_on_score_changed)
	GameState.rerolls_changed.connect(_on_rerolls_changed)
	GameState.draws_changed.connect(_on_draws_changed)

	_update_all()


func _update_all() -> void:
	_on_round_changed(GameState.current_round)
	_on_pool_changed()
	_on_hand_changed()
	_on_score_changed(GameState.total_score)
	_on_rerolls_changed(GameState.rerolls_remaining)
	_on_draws_changed(GameState.draws_remaining)


func _on_round_changed(round_num: int) -> void:
	round_label.text = "Round: %d / %d" % [round_num, GameState.max_rounds]


func _on_pool_changed() -> void:
	inventory_label.text = "Pool: %d" % GameState.deck.get_pool_count()


func _on_hand_changed() -> void:
	hand_label.text = "Hand: %d" % GameState.deck.get_hand_count()


func _on_score_changed(score: int) -> void:
	score_label.text = "Score: %d / %d" % [score, GameState.target_score]


func _on_rerolls_changed(remaining: int) -> void:
	rerolls_label.text = "Rerolls: %d" % remaining


func _on_draws_changed(remaining: int) -> void:
	draws_label.text = "Draws: %d" % remaining
