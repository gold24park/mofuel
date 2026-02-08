class_name HandDisplay
extends Control
## Hand 주사위 표시 — 고정 10슬롯 + DiscardSlot + DrawButton
##
## 레이아웃: [X] [1] [2] ... [10] [Draw]
## - 슬롯 클릭 (release): dice_clicked → PreRollState가 Hand→Active 처리
## - 슬롯 드래그 → DiscardSlot 드롭: dice_discarded
## - Draw 버튼: draw_pressed

signal dice_clicked(index: int) ## Hand 주사위 클릭 시 (Active로 이동 요청)
signal dice_discarded(index: int) ## Hand 주사위 버리기 (드래그 앤 드롭)
signal draw_pressed ## Draw 버튼 클릭
signal slot_animation_finished

const DICE_PREVIEW = preload("res://ui/dice_preview/dice_preview.tscn")
const SLOT_SIZE := Vector2(48, 48)
const HAND_MAX := 10

@onready var container: HBoxContainer = $MarginContainer/HBoxContainer
@onready var background: ColorRect = $ColorRect

var _slots: Array[Panel] = [] ## 10개 고정 슬롯
var _slot_previews: Array = [] ## 슬롯별 DicePreview (null if empty)
var _discard_slot: Panel = null
var _draw_button: Button = null
var _manual_mode: bool = false ## 전환 애니메이션 중 수동 제어


func _ready():
	GameState.hand_changed.connect(_on_hand_changed)
	GameState.phase_changed.connect(_on_phase_changed)
	_build_ui()
	_update_display()


#region UI 구축
func _build_ui() -> void:
	# 1. Discard Slot (빨간 X)
	_discard_slot = _create_discard_slot()
	container.add_child(_discard_slot)

	# 2. 10개 Hand Slots
	for i in range(HAND_MAX):
		var slot := _create_hand_slot(i)
		container.add_child(slot)
		_slots.append(slot)
		_slot_previews.append(null)

	# 3. Draw Button
	_draw_button = Button.new()
	_draw_button.text = "+"
	_draw_button.custom_minimum_size = SLOT_SIZE
	_draw_button.pressed.connect(func(): draw_pressed.emit())
	_draw_button.disabled = true
	container.add_child(_draw_button)


func _create_hand_slot(index: int) -> Panel:
	var slot := Panel.new()
	slot.custom_minimum_size = SLOT_SIZE
	slot.mouse_filter = Control.MOUSE_FILTER_STOP

	# 빈 슬롯 스타일: 회색 테두리
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.2, 0.2, 0.2, 0.3)
	style.border_color = Color(0.4, 0.4, 0.4, 0.5)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	slot.add_theme_stylebox_override("panel", style)

	# 클릭 + 드래그 처리
	slot.gui_input.connect(_on_slot_gui_input.bind(index))
	slot.set_drag_forwarding(
		_slot_get_drag_data.bind(index),
		Callable(), # _can_drop_data 불필요
		Callable()  # _drop_data 불필요
	)

	return slot


func _create_discard_slot() -> Panel:
	var slot := Panel.new()
	slot.custom_minimum_size = SLOT_SIZE
	slot.mouse_filter = Control.MOUSE_FILTER_STOP

	# 빨간 X 스타일
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.4, 0.1, 0.1, 0.6)
	style.border_color = Color(0.7, 0.2, 0.2, 0.8)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	slot.add_theme_stylebox_override("panel", style)

	# X 라벨
	var label := Label.new()
	label.text = "X"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	label.add_theme_font_size_override("font_size", 20)
	label.add_theme_color_override("font_color", Color(1, 0.4, 0.4))
	slot.add_child(label)

	# 드롭 타겟 설정
	slot.set_drag_forwarding(
		Callable(), # _get_drag_data 불필요
		_discard_can_drop_data,
		_discard_drop_data
	)

	return slot
#endregion


#region 슬롯 업데이트
func _update_display() -> void:
	var hand := GameState.deck.hand
	for i in range(HAND_MAX):
		_update_slot(i, hand[i] if i < hand.size() else null)
	_update_discard_slot_style()


func _update_slot(index: int, dice_instance: DiceInstance) -> void:
	var slot := _slots[index]

	# 기존 프리뷰 제거
	var old_preview = _slot_previews[index]
	if old_preview and is_instance_valid(old_preview):
		old_preview.queue_free()
		_slot_previews[index] = null

	if dice_instance:
		# DicePreview 생성 및 슬롯에 배치
		var preview = DICE_PREVIEW.instantiate()
		preview.custom_minimum_size = SLOT_SIZE
		preview.set_anchors_preset(Control.PRESET_FULL_RECT)
		preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot.add_child(preview)
		preview.set_dice_instance(dice_instance)
		_slot_previews[index] = preview

		# 채워진 슬롯 스타일
		var style := slot.get_theme_stylebox("panel") as StyleBoxFlat
		style.bg_color = Color(0.15, 0.15, 0.2, 0.5)
		style.border_color = Color(0.5, 0.5, 0.6, 0.7)
	else:
		# 빈 슬롯 스타일
		var style := slot.get_theme_stylebox("panel") as StyleBoxFlat
		style.bg_color = Color(0.2, 0.2, 0.2, 0.3)
		style.border_color = Color(0.4, 0.4, 0.4, 0.5)


## Discard 가능 조건: hand + active > 5 (라운드 끝에 active가 hand로 돌아오므로)
func _can_discard() -> bool:
	return GameState.deck.hand.size() + GameState.active_dice.size() > 5


func _update_discard_slot_style() -> void:
	var can_discard := _can_discard()
	var style := _discard_slot.get_theme_stylebox("panel") as StyleBoxFlat
	if can_discard:
		style.bg_color = Color(0.4, 0.1, 0.1, 0.6)
		style.border_color = Color(0.7, 0.2, 0.2, 0.8)
		_discard_slot.modulate = Color.WHITE
	else:
		style.bg_color = Color(0.2, 0.2, 0.2, 0.3)
		style.border_color = Color(0.4, 0.4, 0.4, 0.5)
		_discard_slot.modulate = Color(0.5, 0.5, 0.5, 0.7)
#endregion


#region 클릭 처리 (mouse release — 드래그와 충돌 방지)
func _on_slot_gui_input(event: InputEvent, index: int) -> void:
	# release에서만 클릭 처리: 드래그 시작 시 Godot가 입력을 가져가므로 release 도달 안 함
	if event is InputEventMouseButton and not event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_on_slot_clicked(index)


func _on_slot_clicked(index: int) -> void:
	if GameState.current_phase != GameState.Phase.PRE_ROLL:
		return
	if GameState.is_transitioning:
		return
	if index >= GameState.deck.hand.size():
		return
	if GameState.active_dice.size() >= 5:
		return
	dice_clicked.emit(index)
#endregion


#region 드래그 앤 드롭 (Discard)
func _slot_get_drag_data(_at_position: Vector2, index: int) -> Variant:
	if GameState.current_phase != GameState.Phase.PRE_ROLL:
		return null
	if GameState.is_transitioning:
		return null
	if index >= GameState.deck.hand.size():
		return null
	if not _can_discard():
		return null

	# 드래그 프리뷰 (축소판)
	var preview_label := Label.new()
	preview_label.text = GameState.deck.hand[index].type.display_name
	preview_label.add_theme_font_size_override("font_size", 14)
	preview_label.add_theme_color_override("font_color", Color.WHITE)
	set_drag_preview(preview_label)

	return {"type": "hand_dice", "index": index}


func _discard_can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	if data is not Dictionary or data.get("type") != "hand_dice":
		return false
	return _can_discard()


func _discard_drop_data(_at_position: Vector2, data: Variant) -> void:
	dice_discarded.emit(data["index"])
#endregion


#region Draw 버튼 제어
func set_draw_enabled(enabled: bool) -> void:
	if _draw_button:
		_draw_button.disabled = not enabled
#endregion


#region Phase 변경
func _on_phase_changed(_phase: int) -> void:
	_update_discard_slot_style()


func _on_hand_changed() -> void:
	if not _manual_mode:
		_update_display()
#endregion


#region 전환 애니메이션 지원 (고정 슬롯 내부 애니메이션)
var _incoming_slot_indices: Array[int] = [] ## 들어오는 주사위가 배치될 슬롯 인덱스

## 수동 모드 진입 (자동 업데이트 비활성화)
func enter_manual_mode() -> void:
	_manual_mode = true


## 수동 모드 종료 (자동 업데이트 활성화 및 동기화)
func exit_manual_mode() -> void:
	_manual_mode = false
	_clear_incoming_slots()
	_update_display()


func _clear_incoming_slots() -> void:
	for idx in _incoming_slot_indices:
		var preview = _slot_previews[idx]
		if preview and is_instance_valid(preview):
			preview.queue_free()
			_slot_previews[idx] = null
	_incoming_slot_indices.clear()


## Active→Hand 준비: 빈 고정 슬롯에 숨겨진 프리뷰 배치
func prepare_incoming_slots(count: int, dice_instances: Array) -> void:
	_clear_incoming_slots()

	var placed := 0
	for slot_idx in range(HAND_MAX):
		if placed >= count:
			break
		# 이미 차있는 슬롯 건너뛰기
		if _slot_previews[slot_idx] != null:
			continue

		_incoming_slot_indices.append(slot_idx)

		# 슬롯 내부에 숨겨진 프리뷰 생성
		var slot := _slots[slot_idx]
		var preview = DICE_PREVIEW.instantiate()
		preview.custom_minimum_size = SLOT_SIZE
		preview.set_anchors_preset(Control.PRESET_FULL_RECT)
		preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
		preview.modulate.a = 0.0
		preview.scale = Vector2(0.5, 0.5)
		slot.add_child(preview)
		if placed < dice_instances.size() and dice_instances[placed]:
			preview.set_dice_instance(dice_instances[placed])
		_slot_previews[slot_idx] = preview

		placed += 1


## 임시 슬롯 나타나기 애니메이션 (Active→Hand 시)
func animate_temp_slot_appear(index: int) -> void:
	if index < 0 or index >= _incoming_slot_indices.size():
		return

	var slot_idx := _incoming_slot_indices[index]
	var preview = _slot_previews[slot_idx]
	if not preview or not is_instance_valid(preview):
		return

	# 슬롯 스타일을 채워진 상태로 변경
	var style := _slots[slot_idx].get_theme_stylebox("panel") as StyleBoxFlat
	style.bg_color = Color(0.15, 0.15, 0.2, 0.5)
	style.border_color = Color(0.5, 0.5, 0.6, 0.7)

	var tween := create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_parallel(true)
	tween.tween_property(preview, "modulate:a", 1.0, 0.2)
	tween.tween_property(preview, "scale", Vector2.ONE, 0.25)

	await tween.finished
	slot_animation_finished.emit()


## 현재 표시된 주사위 수 반환
func get_visible_count() -> int:
	var count := 0
	for p in _slot_previews:
		if p != null:
			count += 1
	return count
#endregion
