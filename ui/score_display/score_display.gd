extends Control
## BBCode 기반 점수 표시 (패널 없음)
## 1. show_initial(): Hand Rank명 + base chips × mult
## 2. add_contribution(): 효과 발동 시 chips/mult 증분 업데이트
## 3. show_final(): 최종 점수 라인 표시

@onready var rich_label: RichTextLabel = $RichTextLabel

const CHIPS_COLOR := "#4d8dff"   # 파란색
const MULT_COLOR := "#ff4d4d"    # 빨간색
const FINAL_COLOR := "#ffd94d"   # 금색
const HR_COLOR := "#ffffff"      # 흰색
const DD_COLOR := "#ff6644"      # 더블다운 주황

var _gen: int = 0
var _current_chips: int = 0
var _dice_mult: float = 1.0
var _hand_rank_mult: float = 1.0
var _hand_rank_name: String = ""


func _ready() -> void:
	visible = false
	rich_label.bbcode_enabled = true
	rich_label.fit_content = true


#region Public API

## 1단계: Hand Rank명 + 기본 점수 표시
func show_initial(hand_rank_name: String, base: int, hr_mult: float = 1.0) -> void:
	_gen += 1
	visible = true
	_hand_rank_name = hand_rank_name
	_current_chips = base
	_dice_mult = 1.0
	_hand_rank_mult = hr_mult
	_render_score()


## 2단계: 효과 발동 시 증분 업데이트
func add_contribution(bonus: int, mult: float) -> void:
	if bonus != 0:
		_current_chips += bonus
	if mult != 1.0:
		_dice_mult += mult - 1.0
	_render_score()


## 3단계: 최종 점수 표시
func show_final(dd: bool) -> void:
	_gen += 1
	var gen := _gen

	var final_val := int(_current_chips * _get_display_mult())
	if dd:
		final_val = int(final_val * GameState.DOUBLE_DOWN_MULTIPLIER)
	_render_final(final_val, dd)

	await get_tree().create_timer(0.5).timeout
	if _gen != gen: return


## 점수 없음 표시
func show_no_score() -> void:
	_gen += 1
	var gen := _gen
	visible = true
	rich_label.text = "[center][shake rate=8.0 level=3][font_size=10]Burst[/font_size][/shake][/center]"

	await get_tree().create_timer(0.6).timeout
	if _gen != gen: return


func hide_display() -> void:
	_gen += 1
	visible = false
#endregion


#region Rendering
func _build_header_bbcode() -> String:
	var mult_str := _format_mult(_get_display_mult())
	var bbcode := "[center]"
	bbcode += "[font_size=10][color=%s]%s[/color][/font_size]\n" % [HR_COLOR, _hand_rank_name]
	bbcode += "[font_size=8]"
	bbcode += "[color=%s]%d[/color]" % [CHIPS_COLOR, _current_chips]
	bbcode += " x "
	bbcode += "[color=%s]%s[/color]" % [MULT_COLOR, mult_str]
	bbcode += "[/font_size]"
	return bbcode


func _render_score() -> void:
	rich_label.text = _build_header_bbcode() + "[/center]"


func _render_final(final_val: int, dd: bool) -> void:
	var bbcode := _build_header_bbcode() + "\n"
	bbcode += "[font_size=12][wave amp=20 freq=3][color=%s]%d[/color][/wave][/font_size]" % [FINAL_COLOR, final_val]
	if dd:
		bbcode += " [font_size=8][color=%s](x2!)[/color][/font_size]" % DD_COLOR
	bbcode += "[/center]"
	rich_label.text = bbcode
#endregion


#region Helpers
func _get_display_mult() -> float:
	return _dice_mult * _hand_rank_mult


func _format_mult(mult: float) -> String:
	if mult == float(int(mult)):
		return "x%d" % int(mult)
	return "x%.1f" % mult
#endregion
