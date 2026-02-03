extends Control

signal roll_pressed

@onready var button: Button = $CenterContainer/Button

var _pulse_time: float = 0.0
var _enabled: bool = true ## 버튼 활성화 상태
const PULSE_SPEED: float = 3.0
const PULSE_MIN: float = 1.0
const PULSE_MAX: float = 1.08


func _ready():
	button.pressed.connect(_on_button_pressed)
	GameState.phase_changed.connect(_on_phase_changed)
	GameState.transitioning_changed.connect(_on_transitioning_changed)
	GameState.active_changed.connect(_on_active_changed)
	_update()


## 버튼 활성화/비활성화 설정
func set_enabled(enabled: bool) -> void:
	_enabled = enabled
	button.disabled = not enabled
	if enabled:
		button.modulate = Color.WHITE
	else:
		button.modulate = Color(0.5, 0.5, 0.5, 0.7)


func _process(delta: float) -> void:
	if visible:
		_pulse_time += delta * PULSE_SPEED
		var scale_factor := lerpf(PULSE_MIN, PULSE_MAX, (sin(_pulse_time * PI) + 1.0) / 2.0)
		button.scale = Vector2.ONE * scale_factor


func _on_phase_changed(_phase: int) -> void:
	_update()

func _on_active_changed() -> void:
	_update()

func _on_transitioning_changed(_is_transitioning: bool) -> void:
	_update()


func _update() -> void:
	# active 주사위 수가 5개일때만 활성화
	var is_ready: bool = GameState.active_dice.size() == 5
	set_enabled(is_ready)
	
	# PRE_ROLL이고 전환 애니메이션 중이 아닐 때만 표시
	var should_show := GameState.current_phase == GameState.Phase.PRE_ROLL and not GameState.is_transitioning
	visible = should_show
	if should_show:
		_pulse_time = 0.0
		button.scale = Vector2.ONE


func _on_button_pressed() -> void:
	if _enabled:
		roll_pressed.emit()
