extends Control

## Chase Bar — 화면 최상단 수평 트랙
## [Bank] 🔴···············🟢·················· [Camp]
## Police(빨강) — 시간이 줄수록 Player에 접근
## Player(초록) — 거리 환산할수록 Camp에 접근

const TRACK_MARGIN := 12.0   ## 좌우 여백
const TRACK_Y := 10.0        ## 트랙 세로 위치
const TRACK_HEIGHT := 4.0    ## 바 높이
const DOT_RADIUS := 3.0      ## 끝점 반지름
const BLIP_RADIUS := 4.0     ## 레이더 블립 기본 반지름
const PLAYER_CHASE := 4.0    ## 플레이어 블립 추적 속도 (lerp weight/s)
const POLICE_CHASE := 2.5    ## 경찰 블립 추적 속도 (플레이어보다 느려야 시차 발생)

#region Radar Pulse
const PULSE_FREQ := 2.5
const PULSE_ALPHA_MIN := 0.5
const PULSE_ALPHA_MAX := 1.0
const PULSE_SCALE_MIN := 0.8
const PULSE_SCALE_MAX := 1.2
const RING_INTERVAL := 1.2
const RING_DURATION := 0.8
const RING_MAX_RADIUS := 10.0
#endregion

const COLOR_TRACK_BG := Color(0.2, 0.2, 0.2, 0.6)
const COLOR_BANK := Color(0.8, 0.7, 0.2)
const COLOR_POLICE := Color(0.9, 0.15, 0.15)
const COLOR_PLAYER := Color(0.15, 0.85, 0.3)
const COLOR_CAMP := Color(0.3, 0.6, 1.0)

var _player_progress: float = 0.0
var _target_player: float = 0.0
var _police_progress: float = 0.0
var _target_police: float = 0.0
var _time: float = 0.0


func _ready() -> void:
	GameState.distance_changed.connect(_on_progress_changed)
	GameState.time_changed.connect(_on_progress_changed)

	_sync_targets()
	_player_progress = _target_player
	_police_progress = _police_target_from(_player_progress)


func _process(delta: float) -> void:
	_time += delta

	# lerp: 지수 감쇠로 부드럽게 접근 (move_toward의 선형 이동보다 자연스러움)
	_player_progress = lerpf(_player_progress, _target_player, PLAYER_CHASE * delta)

	# 경찰 목표: 플레이어의 "현재"(보간 중) 위치 기반 → 시차 발생
	_target_police = _police_target_from(_player_progress)
	_police_progress = lerpf(_police_progress, _target_police, POLICE_CHASE * delta)

	queue_redraw()


func _draw() -> void:
	var w := size.x
	var track_left := TRACK_MARGIN
	var track_right := w - TRACK_MARGIN
	var track_width := track_right - track_left
	var y := TRACK_Y
	var half_h := TRACK_HEIGHT * 0.5

	# 트랙 배경
	var bg_rect := Rect2(track_left, y - half_h, track_width, TRACK_HEIGHT)
	draw_rect(bg_rect, COLOR_TRACK_BG, true)

	# Bank (왼쪽 끝점)
	draw_circle(Vector2(track_left, y), DOT_RADIUS, COLOR_BANK)

	# Camp (오른쪽 끝점)
	draw_circle(Vector2(track_right, y), DOT_RADIUS, COLOR_CAMP)

	# Police — 빨간 블립 (progress > 0일 때만 표시)
	if _police_progress > 0.01:
		var police_x := track_left + track_width * clampf(_police_progress, 0.0, 1.0)
		_draw_radar_blip(Vector2(police_x, y), COLOR_POLICE, 0.0)

	# Player — 초록 블립
	var player_x := track_left + track_width * clampf(_player_progress, 0.0, 1.0)
	_draw_radar_blip(Vector2(player_x, y), COLOR_PLAYER, 0.4)

	# 라벨
	_draw_label(Vector2(track_left, y - half_h - 2.0), "Bank", COLOR_BANK)
	_draw_label(Vector2(track_right, y - half_h - 2.0), "Camp", COLOR_CAMP)


func _draw_radar_blip(pos: Vector2, color: Color, phase_offset: float) -> void:
	var sine := sin((_time + phase_offset) * PULSE_FREQ * TAU)
	var t := (sine + 1.0) * 0.5

	# 링 (주기적 확산)
	var ring_age := fmod(_time + phase_offset, RING_INTERVAL)
	if ring_age < RING_DURATION:
		var ring_t := ring_age / RING_DURATION
		var ring_radius := BLIP_RADIUS + ring_t * RING_MAX_RADIUS
		var ring_alpha := (1.0 - ring_t) * 0.4
		draw_arc(pos, ring_radius, 0, TAU, 24, Color(color, ring_alpha), 1.0)

	# 글로우
	var glow_alpha := lerpf(0.08, 0.2, t)
	draw_circle(pos, BLIP_RADIUS * 2.5, Color(color, glow_alpha))

	# 코어
	var pulse_scale := lerpf(PULSE_SCALE_MIN, PULSE_SCALE_MAX, t)
	var alpha := lerpf(PULSE_ALPHA_MIN, PULSE_ALPHA_MAX, t)
	draw_circle(pos, BLIP_RADIUS * pulse_scale, Color(color, alpha))


func _draw_label(pos: Vector2, text: String, color: Color) -> void:
	var font := get_theme_default_font()
	var font_size := 5
	var text_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
	var offset := Vector2(-text_size.x * 0.5, 0.0)
	draw_string(font, pos + offset, text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, color)


## 경찰 목표를 플레이어의 현재 위치에서 계산 (gap = bumper + time_extra)
func _police_target_from(player_pos: float) -> float:
	var time_ratio := maxf(GameState.remaining_time / maxf(GameState.BASE_TIME, 0.01), 0.0)
	var eased := time_ratio * time_ratio
	var gap := GameState.POLICE_BUMPER_GAP + GameState.POLICE_GAP * eased
	return player_pos - gap


func _sync_targets() -> void:
	_target_player = GameState.get_player_progress()
	# police는 _process에서 player_progress 기반으로 매 프레임 계산


func _on_progress_changed(_value: float = 0.0) -> void:
	_sync_targets()
