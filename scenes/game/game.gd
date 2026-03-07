extends Control

## 메인 게임 씬
## State Machine이 대부분의 게임 로직을 처리하고,
## 이 스크립트는 초기화와 공통 유틸리티를 제공

@onready var dice_manager = $SubViewportContainer/SubViewport/World3D/DiceManager
@onready var camera_3d = $SubViewportContainer/SubViewport/World3D/Camera3D
@onready var hud = $CanvasLayer/HUD
@onready var game_over_screen = $CanvasLayer/GameOver
@onready var upgrade_screen = $CanvasLayer/UpgradeScreen
@onready var hand_display = $CanvasLayer/HandDisplay
@onready var score_display = $CanvasLayer/ScoreDisplay
@onready var action_bar = $CanvasLayer/ActionBar
@onready var roll_button = $CanvasLayer/RollButton
@onready var inventory_deck = $CanvasLayer/InventoryDeck
@onready var dice_tooltip = $CanvasLayer/DiceTooltip
@onready var gear_grid_ui = $CanvasLayer/GearGridUI
@onready var gear_mini_grid = $CanvasLayer/GearMiniGrid
@onready var chase_bar = $CanvasLayer/ChaseBar
@onready var chase_bg = $ChaseBg
@onready var world_env: WorldEnvironment = $SubViewportContainer/SubViewport/World3D/WorldEnvironment
@onready var state_machine: GameStateMachine = $StateMachine
var juice_fx: JuiceFX

## 채도 전환 (타이머 정지 시 3D 영역 탈색)
const DESAT_SPEED := 4.0
const PAUSED_SATURATION_3D := 0.4
var _target_saturation_3d := 1.0


func _ready() -> void:
	# JuiceFX 초기화
	juice_fx = JuiceFX.new()
	add_child(juice_fx)
	juice_fx.setup(camera_3d, $SubViewportContainer/SubViewport/World3D)

	# 타이머 정지/재개 시 3D 채도 조절
	GameState.timer_running_changed.connect(_on_timer_running_changed)
	# Environment adjustment 활성화
	world_env.environment.adjustment_enabled = true
	world_env.environment.adjustment_saturation = 1.0

	# State Machine 초기화
	state_machine.init(self)

	# 툴팁 연결 - 플랫폼에 따라 분기
	if Platform.is_mobile():
		# 모바일: 터치(클릭)로 툴팁 표시
		dice_manager.selection_changed.connect(_on_dice_selection_changed)
	else:
		# PC: 호버로 툴팁 표시
		dice_manager.dice_hovered.connect(_on_dice_hovered)
		dice_manager.dice_unhovered.connect(_on_dice_unhovered)


func _process(delta: float) -> void:
	# 3D 채도 보간
	var current_sat: float = world_env.environment.adjustment_saturation
	var new_sat := move_toward(current_sat, _target_saturation_3d, DESAT_SPEED * delta)
	if current_sat != new_sat:
		world_env.environment.adjustment_saturation = new_sat


func _on_timer_running_changed(running: bool) -> void:
	_target_saturation_3d = 1.0 if running else PAUSED_SATURATION_3D


## 3D 주사위와 UI를 GameState의 active_dice와 동기화
func _sync_dice_instances() -> void:
	dice_manager.set_dice_instances(GameState.active_dice)


## 주사위 선택 변경 시 툴팁 업데이트 (모바일)
func _on_dice_selection_changed(indices: Array) -> void:
	if indices.is_empty():
		dice_tooltip.hide_tooltip()
	else:
		dice_tooltip.show_dice_info(indices[-1])


## 주사위 호버 시 툴팁 표시 (PC)
func _on_dice_hovered(dice_index: int) -> void:
	dice_tooltip.show_dice_info(dice_index)


## 주사위 호버 해제 시 툴팁 숨김 (PC)
func _on_dice_unhovered(_dice_index: int) -> void:
	dice_tooltip.hide_tooltip()
