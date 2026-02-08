extends Control
## 발라트로 스타일 오도미터(계기판) 점수 표시
## 1. show_initial(): 카테고리명 + base chips × x1 표시
## 2. add_contribution(): 효과 발동 시 chips/mult 오도미터 증분 업데이트
## 3. show_final(): 최종 점수 라인 오도미터 표시

signal score_display_finished

@onready var category_label: Label = $PanelContainer/VBoxContainer/CategoryLabel
@onready var chips_container: HBoxContainer = $PanelContainer/VBoxContainer/ScoreLine/ChipsContainer
@onready var mult_container: HBoxContainer = $PanelContainer/VBoxContainer/ScoreLine/MultContainer
@onready var final_line: HBoxContainer = $PanelContainer/VBoxContainer/FinalLine
@onready var final_container: HBoxContainer = $PanelContainer/VBoxContainer/FinalLine/FinalContainer
@onready var dd_label: Label = $PanelContainer/VBoxContainer/FinalLine/DoubleDownLabel

const CYCLE_INTERVAL: float = 0.03 ## 자릿수 순환 속도 (초)
const SETTLE_DELAY: float = 0.1    ## 자릿수 간 확정 딜레이 (초)
const DIGIT_FONT_SIZE: int = 32
const DIGIT_MIN_SIZE := Vector2(20, 40)
const PUNCH_SCALE: float = 1.3
const CHIPS_COLOR := Color(0.3, 0.55, 1.0)
const MULT_COLOR := Color(1.0, 0.3, 0.3)
const FINAL_COLOR := Color(1.0, 0.85, 0.2)

var _gen: int = 0 ## 전체 세대 카운터 (hide/새 show 시 모든 coroutine 종료)
var _container_gen: Dictionary = {} ## container별 세대 (증분 업데이트 시 해당 container cycle만 종료)
var _current_chips: int = 0
var _dice_mult: float = 1.0      ## 주사위 효과 배수 풀 (가산: 1.0 + Σ(dice_mult - 1))
var _category_mult: float = 1.0  ## 카테고리 기본 배수 (곱산: base_multiplier + extra)


func _ready() -> void:
	visible = false


#region Public API — 3단계 점수 표시

## 1단계: 카테고리명 + 기본 점수 표시 (효과 적용 전)
## cat_mult: 카테고리 배수 (upgrade.get_total_multiplier())
func show_initial(category_name: String, base: int, cat_mult: float = 1.0) -> void:
	_gen += 1
	visible = true
	final_line.visible = false
	_clear_all()

	category_label.text = category_name
	_current_chips = base
	_dice_mult = 1.0
	_category_mult = cat_mult
	_set_static(chips_container, str(_current_chips), CHIPS_COLOR)
	_set_static(mult_container, _format_mult(_get_display_mult()), MULT_COLOR)


## 2단계: 효과 발동 시 증분 업데이트 (오도미터 연출)
## PostRollState에서 효과 애니메이션 콜백으로 호출됨
func add_contribution(bonus: int, mult: float) -> void:
	if bonus != 0:
		_current_chips += bonus
		_animate_odometer_fire(chips_container, str(_current_chips), CHIPS_COLOR)
	if mult != 1.0:
		_dice_mult += mult - 1.0
		_animate_odometer_fire(mult_container, _format_mult(_get_display_mult()), MULT_COLOR)


## 3단계: 최종 점수 표시 (효과 완료 후)
func show_final(dd: bool) -> void:
	_gen += 1
	var gen := _gen
	final_line.visible = true
	dd_label.visible = dd
	dd_label.text = " (x2!)" if dd else ""

	var final_val := int(_current_chips * _get_display_mult())
	if dd:
		final_val = int(final_val * GameState.DOUBLE_DOWN_MULTIPLIER)
	await _animate_odometer(final_container, str(final_val), FINAL_COLOR, gen)
	if _gen != gen: return
	await get_tree().create_timer(0.3).timeout
	if _gen != gen: return
	score_display_finished.emit()


## 점수 없음 표시 (유효 족보 없을 때)
func show_no_score() -> void:
	_gen += 1
	var gen := _gen
	visible = true
	category_label.text = "Burst"
	_set_static(chips_container, "0", CHIPS_COLOR)
	_set_static(mult_container, "x1", MULT_COLOR)
	final_line.visible = true
	dd_label.visible = false
	_set_static(final_container, "0", FINAL_COLOR)

	await get_tree().create_timer(0.6).timeout
	if _gen != gen: return
	score_display_finished.emit()


func hide_display() -> void:
	_gen += 1
	visible = false
#endregion


#region Odometer Animation

## 풀 오도미터: 자릿수 순환 후 왼→오 순차 확정 (await 가능)
func _animate_odometer(container: HBoxContainer, text: String, color: Color, gen: int) -> void:
	var cgen := _bump_container_gen(container)
	_clear_container(container)

	var labels: Array[Label] = []
	var cycling: Array[bool] = []
	var digit_map: Array[int] = []

	for i in text.length():
		var lbl := _make_char_label(color)
		container.add_child(lbl)
		labels.append(lbl)
		if text[i].is_valid_int():
			lbl.text = "0"
			digit_map.append(cycling.size())
			cycling.append(true)
			_run_cycle(lbl, cycling, cycling.size() - 1, gen, container, cgen)
		else:
			lbl.text = text[i]
			digit_map.append(-1)

	for i in labels.size():
		if digit_map[i] == -1:
			continue
		await get_tree().create_timer(SETTLE_DELAY).timeout
		if _gen != gen: return
		cycling[digit_map[i]] = false
		labels[i].text = text[i]
		_punch(labels[i])


## fire-and-forget 오도미터: 증분 업데이트 시 사용 (await 없이 즉시 반환)
func _animate_odometer_fire(container: HBoxContainer, text: String, color: Color) -> void:
	var cgen := _bump_container_gen(container)
	_clear_container(container)

	var labels: Array[Label] = []
	var cycling: Array[bool] = []
	var digit_map: Array[int] = []

	for i in text.length():
		var lbl := _make_char_label(color)
		container.add_child(lbl)
		labels.append(lbl)
		if text[i].is_valid_int():
			lbl.text = "0"
			digit_map.append(cycling.size())
			cycling.append(true)
			_run_cycle(lbl, cycling, cycling.size() - 1, _gen, container, cgen)
		else:
			lbl.text = text[i]
			digit_map.append(-1)

	_settle_digits_async(labels, digit_map, cycling, text, _gen, container, cgen)


## 자릿수 순차 확정 (별도 coroutine)
func _settle_digits_async(labels: Array[Label], digit_map: Array[int],
		cycling: Array[bool], text: String, gen: int,
		container: HBoxContainer, cgen: int) -> void:
	for i in labels.size():
		if digit_map[i] == -1:
			continue
		await get_tree().create_timer(SETTLE_DELAY).timeout
		if _gen != gen or _container_gen.get(container, -1) != cgen:
			return
		cycling[digit_map[i]] = false
		labels[i].text = text[i]
		_punch(labels[i])
#endregion


#region Helpers

## container별 세대 카운터 증가 — 해당 container의 이전 cycle/settle 전부 종료
func _bump_container_gen(container: HBoxContainer) -> int:
	var next: int = _container_gen.get(container, 0) + 1
	_container_gen[container] = next
	return next


## 개별 자릿수 순환 coroutine — 전체 gen 또는 container gen이 바뀌면 종료
func _run_cycle(label: Label, flags: Array[bool], idx: int, gen: int,
		container: HBoxContainer, cgen: int) -> void:
	while _gen == gen and _container_gen.get(container, -1) == cgen and flags[idx]:
		label.text = str(randi() % 10)
		await get_tree().create_timer(CYCLE_INTERVAL).timeout


func _punch(label: Label) -> void:
	label.pivot_offset = label.size / 2
	var tween := create_tween()
	tween.tween_property(label, "scale", Vector2.ONE * PUNCH_SCALE, 0.04)
	tween.tween_property(label, "scale", Vector2.ONE, 0.12) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)


func _make_char_label(color: Color) -> Label:
	var lbl := Label.new()
	lbl.add_theme_font_size_override("font_size", DIGIT_FONT_SIZE)
	lbl.add_theme_color_override("font_color", color)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.custom_minimum_size = DIGIT_MIN_SIZE
	return lbl


## 표시용 통합 배수: dice_mult × category_mult
func _get_display_mult() -> float:
	return _dice_mult * _category_mult


func _format_mult(mult: float) -> String:
	if mult == float(int(mult)):
		return "x%d" % int(mult)
	return "x%.1f" % mult


func _set_static(container: HBoxContainer, text: String, color: Color) -> void:
	_bump_container_gen(container)
	_clear_container(container)
	for ch in text:
		var lbl := _make_char_label(color)
		lbl.text = ch
		container.add_child(lbl)


func _clear_all() -> void:
	_clear_container(chips_container)
	_clear_container(mult_container)
	_clear_container(final_container)


func _clear_container(container: HBoxContainer) -> void:
	for child in container.get_children():
		child.free()
#endregion
