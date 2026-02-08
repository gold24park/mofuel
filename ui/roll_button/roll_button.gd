extends Control

signal roll_pressed
signal reroll_pressed

@onready var button: Button = $CenterContainer/Button

var _pulse_time: float = 0.0
var _enabled: bool = true ## 버튼 활성화 상태
var _selected_count: int = 0 ## POST_ROLL용 선택된 주사위 수
const PULSE_SPEED: float = 3.0
const PULSE_MIN: float = 1.0
const PULSE_MAX: float = 1.08


func _ready() -> void:
	button.pressed.connect(_on_button_pressed)
	GameState.phase_changed.connect(_on_phase_changed)
	GameState.transitioning_changed.connect(_on_transitioning_changed)
	GameState.active_changed.connect(_on_active_changed)
	GameState.rerolls_changed.connect(_on_rerolls_changed)
	_update()


## 버튼 활성화/비활성화 설정
func set_enabled(enabled: bool) -> void:
	_enabled = enabled
	button.disabled = not enabled
	if enabled:
		button.modulate = Color.WHITE
	else:
		button.modulate = Color(0.5, 0.5, 0.5, 0.7)


## POST_ROLL에서 선택된 주사위 수 업데이트
func set_selected_count(count: int) -> void:
	_selected_count = count
	_update()


func _process(delta: float) -> void:
	if visible and _enabled:
		_pulse_time += delta * PULSE_SPEED
		var scale_factor := lerpf(PULSE_MIN, PULSE_MAX, (sin(_pulse_time * PI) + 1.0) / 2.0)
		button.scale = Vector2.ONE * scale_factor


func _on_phase_changed(_phase: int) -> void:
	_selected_count = 0
	_update()

func _on_active_changed() -> void:
	_update()

func _on_transitioning_changed(_is_transitioning: bool) -> void:
	_update()

func _on_rerolls_changed(_remaining: int) -> void:
	_update()


func _update() -> void:
	match GameState.current_phase:
		GameState.Phase.PRE_ROLL:
			var should_show := not GameState.is_transitioning
			visible = should_show
			button.text = "ROLL!"
			set_enabled(GameState.active_dice.size() == 5)
			if should_show:
				_pulse_time = 0.0
				button.scale = Vector2.ONE
		GameState.Phase.POST_ROLL:
			visible = true
			if _selected_count > 0 and GameState.can_reroll():
				button.text = "REROLL %d (%d)" % [_selected_count, GameState.rerolls_remaining]
				set_enabled(true)
			else:
				button.text = "REROLL (%d)" % GameState.rerolls_remaining
				set_enabled(false)
		_:
			visible = false


func _on_button_pressed() -> void:
	if not _enabled:
		return
	match GameState.current_phase:
		GameState.Phase.PRE_ROLL:
			roll_pressed.emit()
		GameState.Phase.POST_ROLL:
			reroll_pressed.emit()
