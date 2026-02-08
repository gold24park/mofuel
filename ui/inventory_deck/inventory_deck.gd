class_name InventoryDeck
extends Control

signal draw_finished
signal draw_pressed ## 플레이어가 드로우 버튼 클릭

@export var draw_duration: float = 0.3
@export var card_size: Vector2 = Vector2(60, 80)

@onready var deck_container: Control = $DeckContainer
@onready var count_label: Label = $DeckContainer/CountLabel

var _deck_center: Vector2
var _draw_enabled: bool = false
var _draw_button: Button = null


func _ready() -> void:
	GameState.pool_changed.connect(_on_pool_changed)
	_update_count()
	_deck_center = deck_container.get_rect().get_center()
	_create_draw_button()


func _update_count() -> void:
	count_label.text = str(GameState.deck.get_pool_count())


func _on_pool_changed() -> void:
	_update_count()


func _create_draw_button() -> void:
	_draw_button = Button.new()
	_draw_button.text = "Draw"
	_draw_button.custom_minimum_size = Vector2(70, 30)
	_draw_button.pressed.connect(func(): draw_pressed.emit())
	_draw_button.disabled = true
	add_child(_draw_button)
	_draw_button.position = Vector2(0, 0)


func set_draw_enabled(enabled: bool) -> void:
	_draw_enabled = enabled
	if _draw_button:
		_draw_button.disabled = not enabled
	deck_container.modulate = Color.WHITE if enabled else Color(0.5, 0.5, 0.5)


## 드로우 애니메이션 실행 (Hand 영역으로)
func animate_draw(target_position: Vector2) -> void:
	# 카드 비주얼 생성
	var card := _create_card_visual()
	add_child(card)
	card.position = deck_container.position + deck_container.size / 2

	# 애니메이션
	var tween := create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_QUAD)

	# 위치 이동 + 약간 회전
	tween.set_parallel(true)
	tween.tween_property(card, "position", target_position, draw_duration)
	tween.tween_property(card, "rotation", randf_range(-0.2, 0.2), draw_duration * 0.5)
	tween.tween_property(card, "scale", Vector2(0.5, 0.5), draw_duration).set_delay(draw_duration * 0.7)
	tween.tween_property(card, "modulate:a", 0.0, draw_duration * 0.3).set_delay(draw_duration * 0.7)

	await tween.finished
	card.queue_free()
	draw_finished.emit()


func _create_card_visual() -> Control:
	var card := ColorRect.new()
	card.custom_minimum_size = card_size
	card.size = card_size
	card.color = Color(0.9, 0.85, 0.75) # 베이지색 카드
	card.pivot_offset = card_size / 2

	# 테두리 효과용 내부 사각형
	var inner := ColorRect.new()
	inner.custom_minimum_size = card_size - Vector2(8, 8)
	inner.size = card_size - Vector2(8, 8)
	inner.position = Vector2(4, 4)
	inner.color = Color(1, 0.98, 0.95)
	card.add_child(inner)

	# 주사위 아이콘 (간단한 도트)
	var dots := _create_dice_dots()
	dots.position = card_size / 2 - Vector2(15, 15)
	card.add_child(dots)

	return card


func _create_dice_dots() -> Control:
	var container := Control.new()
	container.custom_minimum_size = Vector2(30, 30)

	# 5 도트 패턴 (주사위 5)
	var positions := [
		Vector2(0, 0), Vector2(24, 0),
		Vector2(12, 12),
		Vector2(0, 24), Vector2(24, 24)
	]

	for pos in positions:
		var dot := ColorRect.new()
		dot.custom_minimum_size = Vector2(6, 6)
		dot.size = Vector2(6, 6)
		dot.position = pos
		dot.color = Color(0.3, 0.3, 0.3)
		container.add_child(dot)

	return container
