extends Control
## Cowboy Bebop 스타일 세로 패널 액션 바
## AnimationPlayer로 show/hide/slide_in 제어, sweep/flash만 tween
##
## Normal 모드: Smoke (시간) / Reroll / Nitro (거리)
## Reroll 모드: Roll / Double Down

signal nitro_pressed
signal smoke_pressed
signal reroll_pressed
signal reroll_confirmed
signal double_down_pressed


#region Constants
const VIEWPORT_W := 384.0
const PANEL_COUNT := 3
const BAND_Y := 120.0
const BAND_H := 70.0
const PANEL_GAP := VIEWPORT_W / PANEL_COUNT
const PANEL_EXTRA := 40.0
const PANEL_W := PANEL_GAP + PANEL_EXTRA

const SWEEP_DURATION := 0.18
const FLASH_DURATION := 0.12
const MODE_FADE_DURATION := 0.12

## 패널 틴트 컬러
const SMOKE_TINT := Color(0.2, 0.3, 0.7, 0.95)
const REROLL_TINT := Color(0.7, 0.6, 0.1, 0.95)
const NITRO_TINT := Color(0.7, 0.15, 0.1, 0.95)
const ROLL_TINT := Color(0.15, 0.6, 0.25, 0.95)
const DD_TINT := Color(0.8, 0.3, 0.1, 0.95)
const DISABLED_ALPHA := 0.4
#endregion


enum PanelAction { SMOKE, REROLL, NITRO, ROLL, DOUBLE_DOWN, NONE }


#region Scene References
@onready var _sweep: ColorRect = $Sweep
@onready var _anim: AnimationPlayer = $AnimationPlayer
@onready var _panels: Array[TextureRect] = [$Panel0, $Panel1, $Panel2]
@onready var _labels: Array[Label] = [
	$Panel0/Label as Label,
	$Panel1/Label as Label,
	$Panel2/Label as Label,
]
#endregion


#region State
var _reroll_mode := false
var _is_animating := false
var _score_preview := 0
var _selected_count := 0
var _panel_actions: Array[PanelAction] = [
	PanelAction.SMOKE, PanelAction.REROLL, PanelAction.NITRO]
#endregion


func _ready() -> void:
	visible = false
	for i in PANEL_COUNT:
		_panels[i].pivot_offset = Vector2(PANEL_W / 2.0, BAND_H / 2.0)
		_panels[i].gui_input.connect(_on_panel_input.bind(i))
	_anim.animation_finished.connect(_on_animation_finished)


#region Public API

func show_bar() -> void:
	_reroll_mode = false
	_configure_normal_mode()
	visible = true
	_is_animating = true
	_anim.play("show")


func hide_bar() -> void:
	_is_animating = false
	_reroll_mode = false
	if visible:
		_anim.play("hide")


func enter_reroll_mode() -> void:
	_reroll_mode = true
	_transition_to_reroll()


func is_reroll_mode() -> bool:
	return _reroll_mode


func set_score_preview(score: int) -> void:
	_score_preview = score
	if not _reroll_mode:
		_refresh_labels()


func update_state(selected_count: int) -> void:
	_selected_count = selected_count
	_refresh_labels()
#endregion


#region Mode Configuration

func _configure_normal_mode() -> void:
	_panel_actions = [PanelAction.SMOKE, PanelAction.REROLL, PanelAction.NITRO]
	var tints := [SMOKE_TINT, REROLL_TINT, NITRO_TINT]
	for i in PANEL_COUNT:
		_panels[i].visible = true
		_set_tint(i, tints[i])
	_refresh_labels()


func _configure_reroll_mode() -> void:
	_panel_actions = [PanelAction.NONE, PanelAction.ROLL, PanelAction.DOUBLE_DOWN]
	_panels[0].visible = false
	_panels[1].visible = true
	_set_tint(1, ROLL_TINT)
	var show_dd := GameState.can_double_down()
	_panels[2].visible = show_dd
	if show_dd:
		_set_tint(2, DD_TINT)
	_refresh_labels()


func _refresh_labels() -> void:
	if _reroll_mode:
		_labels[1].text = "ROLL %d" % _selected_count if _selected_count > 0 else "ROLL"
		_labels[2].text = "DD x2"
		_panels[1].modulate.a = 1.0 if _selected_count > 0 else DISABLED_ALPHA
	else:
		if _score_preview > 0:
			_labels[0].text = "SMOKE\n+%.1fs" % (_score_preview * GameState.TIME_FACTOR)
			_labels[2].text = "NITRO\n-%.0fm" % (_score_preview * GameState.DISTANCE_FACTOR)
			_panels[0].modulate.a = 1.0
			_panels[2].modulate.a = 1.0
		else:
			_labels[0].text = "SMOKE"
			_labels[2].text = "NITRO"
			_panels[0].modulate.a = DISABLED_ALPHA
			_panels[2].modulate.a = DISABLED_ALPHA
		var can := GameState.can_reroll()
		_labels[1].text = "REROLL (%d)" % GameState.rerolls_remaining if can else "REROLL"
		_panels[1].modulate.a = 1.0 if can else DISABLED_ALPHA
#endregion


#region Animation Callbacks

func _on_animation_finished(anim_name: StringName) -> void:
	match anim_name:
		&"show", &"slide_in":
			_is_animating = false
			_refresh_labels()  # disabled alpha 적용
		&"hide":
			visible = false
			for p in _panels:
				p.rotation = 0.0
#endregion


#region Input

func _on_panel_input(event: InputEvent, index: int) -> void:
	if not (event is InputEventMouseButton and event.pressed \
			and event.button_index == MOUSE_BUTTON_LEFT):
		return
	if _is_animating or not _panels[index].visible:
		return
	if _panels[index].modulate.a < 0.5:
		return  # Disabled panel

	var action := _panel_actions[index]
	if action == PanelAction.NONE:
		return

	_do_select(index, action)


func _do_select(index: int, action: PanelAction) -> void:
	_is_animating = true
	await _animate_sweep(index)
	_is_animating = false

	if not visible:
		return

	match action:
		PanelAction.NITRO: nitro_pressed.emit()
		PanelAction.SMOKE: smoke_pressed.emit()
		PanelAction.REROLL: reroll_pressed.emit()
		PanelAction.ROLL: reroll_confirmed.emit()
		PanelAction.DOUBLE_DOWN: double_down_pressed.emit()
#endregion


#region Tween Animations (dynamic — sweep/flash/mode fade)

func _set_tint(index: int, tint: Color) -> void:
	(_panels[index].material as ShaderMaterial).set_shader_parameter("tint", tint)


func _get_tint(index: int) -> Color:
	return (_panels[index].material as ShaderMaterial).get_shader_parameter("tint") as Color


## 스위프 관통 + 선택된 패널 플래시
func _animate_sweep(selected: int) -> void:
	_sweep.visible = true
	_sweep.position = Vector2(-_sweep.size.x, BAND_Y)
	_sweep.modulate = Color.WHITE

	var tween := create_tween()
	tween.tween_property(_sweep, "position:x", VIEWPORT_W, SWEEP_DURATION) \
		.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	await tween.finished
	_sweep.visible = false

	if not visible:
		return

	var orig_tint := _get_tint(selected)
	var flash := create_tween()
	flash.tween_method(func(c: Color): _set_tint(selected, c),
		Color.WHITE, orig_tint, FLASH_DURATION)
	await flash.finished


## Normal → Reroll 모드 전환: 패널 페이드아웃(tween) → 재구성 → slide_in(AnimationPlayer)
func _transition_to_reroll() -> void:
	var fade := create_tween().set_parallel(true)
	for i in PANEL_COUNT:
		fade.tween_property(_panels[i], "modulate:a", 0.0, MODE_FADE_DURATION)
	await fade.finished
	_configure_reroll_mode()
	_is_animating = true
	_anim.play("slide_in")
#endregion
