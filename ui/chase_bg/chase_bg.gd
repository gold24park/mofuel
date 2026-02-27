extends Control
## 패럴랙스 도주 배경 — 3개 레이어 + 차량 + 연출 시스템
##
## 핵심 규칙:
##   1. 배경은 항상 스크롤 (긴장감 유지 — 멈추면 오히려 몰입 깨짐)
##   2. 거리 획득 시: 배경 가속 + 경찰차 뒤로 밀림 + 플레이어 전진
##   3. 경찰차: 남은 시간에 비례하여 위치 결정 (시간↓ → 접근)
##   4. 타이머 정지 시: 2D 채도 감소 (3D와 통일)
##   5. 시간 2초 미만: 사이렌 + 붉은 점멸
##   6. 게임오버: 성공=가속 탈출, 실패=경찰 추월 차단

#region Constants
const VIEWPORT_WIDTH := 384
const VIEWPORT_HEIGHT := 216
const TEXTURE_HEIGHT := 240

## 패럴랙스 속도 (px/s) — 원경 느림, 근경 빠름 (부스트 수준이 기본)
const BACK_SPEED := 100.0
const BUILDING_SPEED := 200.0
const HIGHWAY_SPEED := 400.0

## 차량 기본
const CAR_FPS := 20.0
const CAR_SCALE := 0.5
const CAR_Y := 164.0

## 플레이어 차 X 범위 (거리 진행률 기반)
const PLAYER_X_START := 130.0    ## 출발 (거리 0% 진행)
const PLAYER_X_END := 300.0      ## 도착 직전 (거리 100% 진행)

## 차량 바운스 (서스펜션 흔들림 — 속력 비례)
const BOUNCE_AMP_MIN := 0.5        ## 기본 주행 시 진폭 (px)
const BOUNCE_AMP_MAX := 1.2        ## 부스트 시 최대 진폭 (px)
const BOUNCE_JITTER_MAX := 0.4     ## 고속 시 랜덤 떨림 (px)
const PLAYER_BOUNCE_FREQ := 4.0    ## 플레이어 Hz
const POLICE_BOUNCE_FREQ := 4.7    ## 경찰차 Hz (비동기)

## 아이들 드리프트 (엔진 공회전 — 정지 시에도 앞뒤 떠돌기)
const IDLE_DRIFT_AMP := 6.0        ## 기본 진폭 (px)
const IDLE_PLAYER_FREQ_1 := 0.35   ## 플레이어 저주파 Hz (느린 흔들림)
const IDLE_PLAYER_FREQ_2 := 0.83   ## 플레이어 고주파 Hz (불규칙감)
const IDLE_POLICE_FREQ_1 := 0.47   ## 경찰차 저주파 Hz (비동기)
const IDLE_POLICE_FREQ_2 := 1.1    ## 경찰차 고주파 Hz (비동기)

## 경찰차 X 범위 (확대: 화면 밖 → 바로 뒤)
const POLICE_X_FAR := -20.0       ## 시간 충분 (화면 밖, 위협 낮음)
const POLICE_X_NEAR := 78.0       ## 시간 임박 (앞범퍼 맞닿음)

## 경찰차 시각 차별화
const POLICE_TINT := Color(0.5, 0.6, 1.0)   ## 파란 틴트
const POLICE_FRAME_OFFSET := 2               ## 프레임 오프셋 (비동기 애니메이션)

## 사이렌 — 시간 2초 미만 긴박감
const URGENCY_THRESHOLD := 2.0
const SIREN_SPEED := 6.0          ## 점멸 Hz
const SIREN_RED := Color(1.0, 0.3, 0.3)
const SIREN_BLUE := Color(0.3, 0.3, 1.0)
const URGENCY_OVERLAY_ALPHA := 0.12

## 거리 획득 부스트 (기본 속도가 높으므로 배수 완화)
const BOOST_POLICE_PUSHBACK := 30.0   ## 경찰차 뒤로 밀리는 px
const BOOST_SCROLL_MULT := 1.5        ## 배경 스크롤 배수 (기본이 빠르므로 가벼운 추가)
const BOOST_DECAY_SPEED := 1.2        ## 감쇠 속도 (2→1.2, 부스트 오래 유지)
const PLAYER_BOOST_OFFSET := 25.0     ## 플레이어 전진 px
const PLAYER_BOOST_RETURN := 60.0     ## 전진 복귀 속도 (px/s)

## 경찰차 리액션 (시간 추가 시 swerve)
const POLICE_SWERVE_AMP := 8.0        ## Y축 스워브 진폭 (px)
const POLICE_SWERVE_FREQ := 5.0       ## 스워브 Hz (빠른 흔들림)
const POLICE_SWERVE_DECAY := 3.0      ## 감쇠 속도 (1/s)
const POLICE_OVERSHOOT := 30.0        ## X 오버슈트 거리 (px, 뒤로 더 밀림)

## 차량 이동 가속 (ease-in: 느리게 시작 → 빠르게 도달)
const MOVE_ACCEL_RATE := 6.0          ## 가속도 (lerp weight 증가율 /s)
const MOVE_MAX_LERP := 5.0            ## 최대 lerp weight
const MOVE_START_LERP := 0.3          ## 초기 lerp weight (완전 정지 방지)

## 타이머 정지 시 채도 감소
const PAUSED_MODULATE := Color(0.55, 0.55, 0.65, 1.0)
const MODULATE_LERP_SPEED := 3.0

## 게임오버 연출
const ESCAPE_ACCEL := 500.0           ## 탈출 가속도 (px/s²)
const BUST_POLICE_TARGET_X := 220.0   ## 체포 시 경찰차 목표 X (플레이어 앞)
const GAMEOVER_DECEL := 0.7           ## 체포 시 스크롤 감속 비율

## 속도선 (부스트 시)
const SPEED_LINE_COUNT := 8
const SPEED_LINE_SPEED := 600.0
const SPEED_LINE_MIN_Y := 140.0
const SPEED_LINE_MAX_Y := 195.0

## 배기가스
const EXHAUST_Y_OFFSET := 25.0       ## 차 상단으로부터의 Y 오프셋
#endregion


#region State
## 패럴랙스 레이어: {speed: float, sprites: Array[Sprite2D], scaled_width: float}
var _layers: Array[Dictionary] = []

var _player_car: Sprite2D
var _police_car: Sprite2D
var _car_frames: Array[Texture2D] = []
var _car_frame_index := 0
var _car_frame_timer := 0.0

## 경찰차 위치 (부드러운 보간)
var _police_target_x := POLICE_X_FAR       ## 실제 목표 (시간 기반)
var _police_display_target_x := POLICE_X_FAR  ## 표시용 목표 (오버슈트 포함)
var _police_current_x := POLICE_X_FAR

## 플레이어 차 위치 (거리 기반 보간)
var _player_target_x := PLAYER_X_START
var _player_current_x := PLAYER_X_START

## 거리 획득 부스트
var _boost_amount := 0.0
var _boost_holding := false
var _player_boost_x := 0.0      ## 플레이어 순간 전진 오프셋

## 경찰차 리액션 상태
var _police_swerve := 0.0       ## 스워브 세기 (0~1, 감쇠)
var _police_swerve_timer := 0.0 ## 스워브 타이머

## 차량 이동 가속 상태 (ease-in)
var _player_lerp_weight := MOVE_MAX_LERP   ## 플레이어 현재 lerp weight
var _police_lerp_weight := MOVE_MAX_LERP   ## 경찰차 현재 lerp weight

## 속력 계수 (바운스/이펙트용)
var _current_speed_factor := 1.0

## 채도 / 긴박감
var _target_modulate := Color.WHITE
var _is_urgent := false
var _siren_timer := 0.0
var _urgency_overlay: ColorRect

## 게임오버
var _game_over_active := false
var _game_over_won := false
var _escape_speed := 0.0
var _gameover_scroll_mult := 1.0

## VFX
var _speed_lines: Array[Dictionary] = []
var _exhaust_particles: Array[Dictionary] = []
#endregion


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_load_car_frames()
	_build_layers()
	_build_cars()
	_build_urgency_overlay()
	_init_speed_lines()
	GameState.time_changed.connect(_on_time_changed)
	GameState.distance_changed.connect(_on_distance_changed)
	GameState.phase_changed.connect(_on_phase_changed)
	GameState.timer_running_changed.connect(_on_timer_running_changed)


func _process(delta: float) -> void:
	if _game_over_active:
		_process_game_over(delta)
	else:
		_process_gameplay(delta)

	_apply_bounce()
	_scroll_layers(delta)
	_animate_cars(delta)
	_update_exhaust(delta)
	queue_redraw()


func _draw() -> void:
	_draw_speed_lines()
	_draw_exhaust()


#region Gameplay loop
func _process_gameplay(delta: float) -> void:
	# 부스트 감쇠
	if not _boost_holding:
		_boost_amount = move_toward(_boost_amount, 0.0, BOOST_DECAY_SPEED * delta)

	# 가속 (ease-in): lerp weight가 점점 빨라짐
	_player_lerp_weight = minf(_player_lerp_weight + MOVE_ACCEL_RATE * delta, MOVE_MAX_LERP)
	_police_lerp_weight = minf(_police_lerp_weight + MOVE_ACCEL_RATE * delta, MOVE_MAX_LERP)

	# 플레이어 X: 거리 기반 목표로 가속 보간
	_player_current_x = lerp(_player_current_x, _player_target_x, _player_lerp_weight * delta)
	# 플레이어 부스트 X 복귀
	_player_boost_x = move_toward(_player_boost_x, 0.0, PLAYER_BOOST_RETURN * delta)

	# 경찰차 스워브 감쇠
	_police_swerve = move_toward(_police_swerve, 0.0, POLICE_SWERVE_DECAY * delta)
	_police_swerve_timer += delta
	# 오버슈트 표시 목표 → 실제 목표로 점진 복귀 (느린 스프링백)
	_police_display_target_x = lerp(_police_display_target_x, _police_target_x, 0.7 * delta)

	# 경찰차 X: 표시 목표로 가속 보간 + 부스트 푸시백
	_police_current_x = lerp(_police_current_x, _police_display_target_x, _police_lerp_weight * delta)
	_police_car.position.x = _police_current_x - _boost_amount * BOOST_POLICE_PUSHBACK

	# 플레이어 X: 거리 진행 위치 + 부스트 전진
	_player_car.position.x = _player_current_x + _player_boost_x

	# 사이렌 / 긴박감
	_update_urgency(delta)

	# 속도선
	_update_speed_lines(delta)

	# 채도 보간 (정지 시 어두워짐)
	modulate = modulate.lerp(_target_modulate, MODULATE_LERP_SPEED * delta)
#endregion


#region Signal handlers
func _on_time_changed(time: float) -> void:
	if _game_over_active:
		return
	var ratio := maxf(time / GameState.BASE_TIME, 0.0)  ## 상한 없음 — 7초 초과 시 화면 밖으로
	var eased := ratio * ratio
	var new_target := lerpf(POLICE_X_NEAR, POLICE_X_FAR, eased)

	# 시간 추가 시 (경찰차가 뒤로 밀릴 때) 리액션 발동
	if new_target < _police_target_x:
		var push_dist := _police_target_x - new_target
		var push_strength := clampf(push_dist / absf(POLICE_X_NEAR - POLICE_X_FAR), 0.0, 1.0)
		# 스워브: 핸들 흔들리며 뒤로 밀림
		_police_swerve = clampf(_police_swerve + 0.6 + push_strength * 0.4, 0.0, 1.0)
		_police_swerve_timer = 0.0
		# 오버슈트: 표시 목표를 실제보다 더 뒤로 (급격히 밀렸다가 복귀)
		_police_display_target_x = new_target - POLICE_OVERSHOOT * push_strength
		# ease-in 리셋: 느리게 시작 → 점점 빨라짐
		_police_lerp_weight = MOVE_START_LERP
	else:
		_police_display_target_x = new_target

	_police_target_x = new_target
	_is_urgent = time > 0.0 and time <= URGENCY_THRESHOLD


func _on_distance_changed(distance: float) -> void:
	if _game_over_active:
		return
	# 거리 진행률 → 플레이어 차 오른쪽 이동
	var progress := 1.0 - clampf(distance / maxf(GameState.target_distance, 0.01), 0.0, 1.0)
	_player_target_x = lerpf(PLAYER_X_START, PLAYER_X_END, progress)
	# ease-in 리셋: 느리게 시작 → 점점 빨라짐
	_player_lerp_weight = MOVE_START_LERP
	# 배경 부스트 (스크롤 가속 + 속도선 + 배기)
	_boost_amount = 1.0
	_boost_holding = true


func _on_phase_changed(phase: GameState.Phase) -> void:
	match phase:
		GameState.Phase.SETUP:
			_reset()
		GameState.Phase.ROLLING:
			_boost_holding = false
		GameState.Phase.GAME_OVER:
			_start_game_over()


func _on_timer_running_changed(running: bool) -> void:
	if not _game_over_active:
		_target_modulate = Color.WHITE if running else PAUSED_MODULATE
#endregion


#region Urgency (시간 2초 미만)
func _update_urgency(delta: float) -> void:
	if _is_urgent:
		_siren_timer += delta * SIREN_SPEED
		# 경찰차 사이렌: 빨-파 번갈아 점멸
		var siren_phase := fmod(_siren_timer, 1.0)
		_police_car.modulate = SIREN_RED if siren_phase < 0.5 else SIREN_BLUE
		# 붉은 오버레이 펄스
		var pulse := absf(sin(_siren_timer * PI))
		_urgency_overlay.color.a = pulse * URGENCY_OVERLAY_ALPHA
		_urgency_overlay.visible = true
	else:
		_siren_timer = 0.0
		_police_car.modulate = POLICE_TINT
		_urgency_overlay.visible = false
#endregion


#region Game Over
func _start_game_over() -> void:
	_game_over_active = true
	_game_over_won = GameState.is_game_won()
	_is_urgent = false
	_urgency_overlay.visible = false
	_boost_amount = 0.0
	_boost_holding = false
	_gameover_scroll_mult = 1.0
	_target_modulate = Color.WHITE
	_police_car.modulate = POLICE_TINT

	_police_swerve = 0.0
	if _game_over_won:
		_escape_speed = 0.0
	else:
		_police_target_x = BUST_POLICE_TARGET_X
		_police_display_target_x = BUST_POLICE_TARGET_X


func _process_game_over(delta: float) -> void:
	if _game_over_won:
		# 성공: 플레이어 가속 탈출 + 배경 부스트
		_escape_speed += ESCAPE_ACCEL * delta
		_player_car.position.x += _escape_speed * delta
		_boost_amount = minf(_boost_amount + delta * 3.0, 1.0)
		_update_speed_lines(delta)
	else:
		# 실패: 경찰 추월 + 양쪽 감속 정지
		_police_current_x = lerp(_police_current_x, _police_target_x, 2.0 * delta)
		_police_car.position.x = _police_current_x
		_gameover_scroll_mult = move_toward(_gameover_scroll_mult, 0.05, GAMEOVER_DECEL * delta)

	modulate = modulate.lerp(_target_modulate, MODULATE_LERP_SPEED * delta)


func _reset() -> void:
	_game_over_active = false
	_game_over_won = false
	_escape_speed = 0.0
	_gameover_scroll_mult = 1.0
	_boost_amount = 0.0
	_boost_holding = false
	_player_boost_x = 0.0
	_is_urgent = false
	_siren_timer = 0.0
	_police_target_x = POLICE_X_FAR
	_police_display_target_x = POLICE_X_FAR
	_police_current_x = POLICE_X_FAR
	_police_swerve = 0.0
	_police_swerve_timer = 0.0
	_player_lerp_weight = MOVE_MAX_LERP
	_police_lerp_weight = MOVE_MAX_LERP
	_player_target_x = PLAYER_X_START
	_player_current_x = PLAYER_X_START
	_player_car.position.x = PLAYER_X_START
	_police_car.position.x = POLICE_X_FAR
	_police_car.modulate = POLICE_TINT
	_target_modulate = Color.WHITE
	modulate = Color.WHITE
	_urgency_overlay.visible = false
	_exhaust_particles.clear()
#endregion


#region Setup
func _load_car_frames() -> void:
	for i in range(1, 6):
		_car_frames.append(load("res://assets/car/car-running%d.png" % i) as Texture2D)


func _build_layers() -> void:
	var layer_defs: Array[Dictionary] = [
		{"path": "res://assets/drive/back.png",      "speed": BACK_SPEED,     "scale": 0.9},
		{"path": "res://assets/drive/buildings.png",  "speed": BUILDING_SPEED, "scale": 0.7},
		{"path": "res://assets/drive/highway.png",    "speed": HIGHWAY_SPEED,  "scale": 0.5},
	]

	for def in layer_defs:
		var tex := load(def["path"]) as Texture2D
		var s: float = def["scale"]
		var scaled_width: float = tex.get_width() * s
		var scaled_height: float = TEXTURE_HEIGHT * s
		var y_offset: float = VIEWPORT_HEIGHT - scaled_height

		var copy_count: int = ceili(VIEWPORT_WIDTH / scaled_width) + 1
		var container := Node2D.new()
		container.name = def["path"].get_file().get_basename().capitalize() + "Layer"
		add_child(container)

		var sprites: Array[Sprite2D] = []
		for i in copy_count:
			var spr := Sprite2D.new()
			spr.texture = tex
			spr.centered = false
			spr.scale = Vector2(s, s)
			spr.position = Vector2(i * scaled_width, y_offset)
			container.add_child(spr)
			sprites.append(spr)

		_layers.append({
			"speed": def["speed"] as float,
			"sprites": sprites,
			"scaled_width": scaled_width,
		})


func _build_cars() -> void:
	assert(_car_frames.size() == 5, "Expected 5 car frames")

	_player_car = Sprite2D.new()
	_player_car.name = "PlayerCar"
	_player_car.texture = _car_frames[0]
	_player_car.centered = false
	_player_car.scale = Vector2(CAR_SCALE, CAR_SCALE)
	_player_car.position = Vector2(PLAYER_X_START, CAR_Y)
	add_child(_player_car)

	_police_car = Sprite2D.new()
	_police_car.name = "PoliceCar"
	_police_car.texture = _car_frames[0]
	_police_car.centered = false
	_police_car.scale = Vector2(CAR_SCALE, CAR_SCALE)
	_police_car.position = Vector2(POLICE_X_FAR, CAR_Y)
	_police_car.modulate = POLICE_TINT
	add_child(_police_car)


func _build_urgency_overlay() -> void:
	_urgency_overlay = ColorRect.new()
	_urgency_overlay.name = "UrgencyOverlay"
	_urgency_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_urgency_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_urgency_overlay.color = Color(1.0, 0.0, 0.0, 0.0)
	_urgency_overlay.visible = false
	add_child(_urgency_overlay)


func _init_speed_lines() -> void:
	for i in SPEED_LINE_COUNT:
		_speed_lines.append({
			"x": randf_range(0, VIEWPORT_WIDTH),
			"y": randf_range(SPEED_LINE_MIN_Y, SPEED_LINE_MAX_Y),
			"length": randf_range(15.0, 40.0),
			"active": false,
		})
#endregion


#region Per-frame updates
func _apply_bounce() -> void:
	var t := Time.get_ticks_msec() / 1000.0
	# 속력 비례 바운스 — 부스트/게임오버 감속 반영
	_current_speed_factor = 1.0 + _boost_amount * (BOOST_SCROLL_MULT - 1.0)
	if _game_over_active and not _game_over_won:
		_current_speed_factor *= _gameover_scroll_mult
	var speed_ratio := clampf(_current_speed_factor / BOOST_SCROLL_MULT, 0.0, 1.0)
	var amp := lerpf(BOUNCE_AMP_MIN, BOUNCE_AMP_MAX, speed_ratio)
	# 고속 시 랜덤 떨림 추가 (노면 진동 느낌)
	var jitter := BOUNCE_JITTER_MAX * speed_ratio * sin(t * 23.7)  # 고주파 해쉬
	_player_car.position.y = CAR_Y + sin(t * PLAYER_BOUNCE_FREQ * TAU) * amp + jitter
	# 경찰차: 바운스 + 스워브 (리액션)
	var swerve_y := sin(_police_swerve_timer * POLICE_SWERVE_FREQ * TAU) * POLICE_SWERVE_AMP * _police_swerve
	_police_car.position.y = CAR_Y + sin(t * POLICE_BOUNCE_FREQ * TAU) * amp + jitter + swerve_y

	# 아이들 X 드리프트 — 두 주파수 합성으로 유기적인 앞뒤 떠돌기
	# 게임오버 중에는 드리프트 비활성 (경찰차 X를 _process_game_over에서 직접 제어)
	if not _game_over_active:
		var player_drift := sin(t * IDLE_PLAYER_FREQ_1 * TAU) * IDLE_DRIFT_AMP \
			+ sin(t * IDLE_PLAYER_FREQ_2 * TAU) * IDLE_DRIFT_AMP * 0.4
		var police_drift := sin(t * IDLE_POLICE_FREQ_1 * TAU) * IDLE_DRIFT_AMP \
			+ sin(t * IDLE_POLICE_FREQ_2 * TAU) * IDLE_DRIFT_AMP * 0.4
		_player_car.position.x += player_drift
		_police_car.position.x += police_drift


func _scroll_layers(delta: float) -> void:
	var speed_mult := 1.0 + _boost_amount * (BOOST_SCROLL_MULT - 1.0)
	if _game_over_active:
		speed_mult *= _gameover_scroll_mult

	for layer in _layers:
		var speed: float = layer["speed"] * speed_mult
		var sprites: Array[Sprite2D] = []
		sprites.assign(layer["sprites"])
		var sw: float = layer["scaled_width"]

		var rightmost_end := -999999.0
		for spr in sprites:
			var spr_end := spr.position.x + sw
			if spr_end > rightmost_end:
				rightmost_end = spr_end

		for spr in sprites:
			spr.position.x -= speed * delta
			if spr.position.x + sw <= 0:
				spr.position.x = rightmost_end - speed * delta


func _animate_cars(delta: float) -> void:
	var fps_mult := 1.0 + _boost_amount * 1.5
	# 체포 시 애니메이션도 감속
	if _game_over_active and not _game_over_won:
		fps_mult *= _gameover_scroll_mult

	_car_frame_timer += delta * fps_mult
	var frame_duration := 1.0 / CAR_FPS
	if _car_frame_timer >= frame_duration:
		_car_frame_timer -= frame_duration
		_car_frame_index = (_car_frame_index + 1) % _car_frames.size()
		_player_car.texture = _car_frames[_car_frame_index]
		# 경찰차: 프레임 오프셋으로 비동기 애니메이션
		var police_frame := (_car_frame_index + POLICE_FRAME_OFFSET) % _car_frames.size()
		_police_car.texture = _car_frames[police_frame]


func _update_speed_lines(delta: float) -> void:
	var active := _boost_amount > 0.1
	for line in _speed_lines:
		line["active"] = active
		if active:
			line["x"] -= SPEED_LINE_SPEED * _boost_amount * delta
			if line["x"] + line["length"] < 0:
				line["x"] = VIEWPORT_WIDTH + randf_range(0, 50)
				line["y"] = randf_range(SPEED_LINE_MIN_Y, SPEED_LINE_MAX_Y)
				line["length"] = randf_range(15.0, 40.0)


func _update_exhaust(delta: float) -> void:
	var spawn_rate := 10.0 + _boost_amount * 20.0
	# 체포 감속 시 배기도 줄어듬
	if _game_over_active and not _game_over_won:
		spawn_rate *= _gameover_scroll_mult

	# 차 뒤쪽(왼쪽 끝)에서 배기 스폰
	if randf() < spawn_rate * delta:
		_spawn_exhaust(_player_car.position.x, _player_car.position.y + EXHAUST_Y_OFFSET)
	if randf() < spawn_rate * delta * 0.7:
		_spawn_exhaust(_police_car.position.x, _police_car.position.y + EXHAUST_Y_OFFSET)

	# 파티클 업데이트
	var drift_speed := 80.0 + _boost_amount * 100.0
	if _game_over_active and not _game_over_won:
		drift_speed *= _gameover_scroll_mult

	for p in _exhaust_particles:
		p["x"] -= drift_speed * delta
		p["y"] -= randf() * 30.0 * delta
		p["alpha"] -= 1.5 * delta
		p["size"] += 1.0 * delta

	# 소멸된 파티클 제거
	_exhaust_particles = _exhaust_particles.filter(func(p: Dictionary) -> bool: return p["alpha"] > 0.01)


func _spawn_exhaust(x: float, y: float) -> void:
	_exhaust_particles.append({
		"x": x + randf_range(-2, 2),
		"y": y + randf_range(-1, 1),
		"alpha": 0.35 + _boost_amount * 0.25,
		"size": randf_range(1.0, 2.5),
	})
#endregion


#region Draw
func _draw_speed_lines() -> void:
	if _boost_amount <= 0.1:
		return
	var alpha := _boost_amount * 0.5
	for line in _speed_lines:
		if line["active"]:
			draw_line(
				Vector2(line["x"], line["y"]),
				Vector2(line["x"] + line["length"], line["y"]),
				Color(1.0, 1.0, 1.0, alpha), 1.0)


func _draw_exhaust() -> void:
	for p in _exhaust_particles:
		if p["alpha"] > 0.01:
			draw_circle(
				Vector2(p["x"], p["y"]), p["size"],
				Color(0.8, 0.8, 0.9, p["alpha"]))
#endregion
