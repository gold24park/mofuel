extends Control

@onready var timer_label: Label = $TimerLabel
@onready var distance_label: Label = $DistanceLabel
@onready var inventory_label: Label = $InventoryLabel
@onready var hand_label: Label = $ReserveLabel ## 노드명 유지
@onready var rerolls_label: Label = $RerollsLabel
@onready var draws_label: Label = $DrawsLabel
@onready var redraws_label: Label = $RedrawsLabel


func _ready() -> void:
	GameState.time_changed.connect(_on_time_changed)
	GameState.distance_changed.connect(_on_distance_changed)
	GameState.pool_changed.connect(_on_pool_changed)
	GameState.hand_changed.connect(_on_hand_changed)
	GameState.rerolls_changed.connect(_on_rerolls_changed)
	GameState.draws_changed.connect(_on_draws_changed)
	GameState.redraws_changed.connect(_on_redraws_changed)

	_update_all()


func _update_all() -> void:
	_on_time_changed(GameState.remaining_time)
	_on_distance_changed(GameState.remaining_distance)
	_on_pool_changed()
	_on_hand_changed()
	_on_rerolls_changed(GameState.rerolls_remaining)
	_on_draws_changed(GameState.draws_remaining)
	_on_redraws_changed(GameState.redraws_remaining)


func _on_time_changed(time: float) -> void:
	timer_label.text = "Time: %.1f" % time
	# 긴박감 표시: 2초 미만이면 붉은색
	if time < 2.0:
		timer_label.add_theme_color_override("font_color", Color.RED)
	else:
		timer_label.remove_theme_color_override("font_color")


func _on_distance_changed(distance: float) -> void:
	distance_label.text = "Distance: %.0f" % distance


func _on_pool_changed() -> void:
	inventory_label.text = "Pool: %d" % GameState.deck.get_pool_count()


func _on_hand_changed() -> void:
	hand_label.text = "Hand: %d" % GameState.deck.get_hand_count()


func _on_rerolls_changed(remaining: int) -> void:
	rerolls_label.text = "Rerolls: %d" % remaining


func _on_draws_changed(remaining: int) -> void:
	draws_label.text = "Draws: %d" % remaining


func _on_redraws_changed(remaining: int) -> void:
	redraws_label.text = "Redraws: %d" % remaining
