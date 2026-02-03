class_name HandDisplay
extends Control
## Hand 주사위 표시 및 PRE_ROLL 선택

signal dice_clicked(index: int) ## Hand 주사위 클릭 시 (Active로 이동 요청)
signal slot_animation_finished

const DICE_PREVIEW = preload("res://ui/dice_preview/dice_preview.tscn")

@onready var container: HBoxContainer = $CenterContainer/HBoxContainer
@onready var background: ColorRect = $ColorRect

var dice_previews: Array = []
var _manual_mode: bool = false ## 전환 애니메이션 중 수동 제어


func _ready():
	GameState.hand_changed.connect(_on_hand_changed)
	_update_display()


func _update_display():
	# 기존 프리뷰 제거
	for preview in dice_previews:
		preview.queue_free()
	dice_previews.clear()

	# Hand 주사위 표시
	for i in range(GameState.inventory_manager.hand.size()):
		var dice_instance: DiceInstance = GameState.inventory_manager.hand[i]
		var preview := _create_dice_preview(i)
		container.add_child(preview)
		preview.set_dice_instance(dice_instance)
		dice_previews.append(preview)


func _create_dice_preview(index: int) -> Control:
	var preview = DICE_PREVIEW.instantiate()
	preview.custom_minimum_size = Vector2(40, 40)

	# 클릭 이벤트를 위한 컨테이너
	var click_area := Control.new()
	click_area.set_anchors_preset(Control.PRESET_FULL_RECT)
	click_area.mouse_filter = Control.MOUSE_FILTER_STOP
	click_area.gui_input.connect(func(event):
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_on_preview_clicked(index)
	)
	preview.add_child(click_area)

	return preview


func _on_preview_clicked(index: int) -> void:
	# PRE_ROLL에서만 클릭 가능
	if GameState.current_phase != GameState.Phase.PRE_ROLL:
		return
	if GameState.is_transitioning:
		return

	# Active가 5개 이상이면 더 이상 추가 불가
	if GameState.active_dice.size() >= 5:
		return

	dice_clicked.emit(index)


func _on_hand_changed():
	if not _manual_mode:
		_update_display()


#region 전환 애니메이션 지원
var _temp_slots: Array = [] ## 애니메이션용 임시 슬롯

## 수동 모드 진입 (자동 업데이트 비활성화)
func enter_manual_mode() -> void:
	_manual_mode = true


## 수동 모드 종료 (자동 업데이트 활성화 및 동기화)
func exit_manual_mode() -> void:
	_manual_mode = false
	_clear_temp_slots()
	_update_display()


func _clear_temp_slots() -> void:
	for slot in _temp_slots:
		if is_instance_valid(slot):
			slot.queue_free()
	_temp_slots.clear()


## Active→Hand 준비: count개의 숨겨진 임시 슬롯 추가
func prepare_incoming_slots(count: int, dice_instances: Array) -> void:
	_clear_temp_slots()
	for i in range(count):
		var preview := _create_temp_slot()
		preview.modulate.a = 0.0
		preview.scale = Vector2(0.5, 0.5)
		container.add_child(preview) # _ready() 호출됨
		if i < dice_instances.size() and dice_instances[i]:
			preview.set_dice_instance(dice_instances[i]) # dice_model 생성 후 호출
		_temp_slots.append(preview)


## Hand→Active 준비: count개의 보이는 임시 슬롯 추가
func prepare_outgoing_slots(count: int, dice_instances: Array) -> void:
	_clear_temp_slots()
	for i in range(count):
		var preview := _create_temp_slot()
		container.add_child(preview) # _ready() 호출됨
		if i < dice_instances.size() and dice_instances[i]:
			preview.set_dice_instance(dice_instances[i]) # dice_model 생성 후 호출
		_temp_slots.append(preview)


func _create_temp_slot() -> Control:
	var preview = DICE_PREVIEW.instantiate()
	preview.custom_minimum_size = Vector2(40, 40)
	return preview


## 임시 슬롯 나타나기 애니메이션 (Active→Hand 시)
func animate_temp_slot_appear(index: int) -> void:
	if index < 0 or index >= _temp_slots.size():
		return

	var preview = _temp_slots[index]
	var tween := create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_parallel(true)
	tween.tween_property(preview, "modulate:a", 1.0, 0.2)
	tween.tween_property(preview, "scale", Vector2.ONE, 0.25)

	await tween.finished
	slot_animation_finished.emit()


## 임시 슬롯 사라지기 애니메이션 (Hand→Active 시)
func animate_temp_slot_disappear(index: int) -> void:
	if index < 0 or index >= _temp_slots.size():
		return

	var preview = _temp_slots[index]
	var tween := create_tween()
	tween.set_ease(Tween.EASE_IN)
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_parallel(true)
	tween.tween_property(preview, "modulate:a", 0.0, 0.15)
	tween.tween_property(preview, "scale", Vector2(0.3, 0.3), 0.2)

	await tween.finished
	slot_animation_finished.emit()


## 현재 표시된 주사위 수 반환 (임시 슬롯 포함)
func get_visible_count() -> int:
	return dice_previews.size() + _temp_slots.size()
#endregion
