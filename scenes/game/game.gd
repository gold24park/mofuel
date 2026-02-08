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
@onready var dice_stats = $CanvasLayer/DiceStats
@onready var roll_button = $CanvasLayer/RollButton
@onready var inventory_deck = $CanvasLayer/InventoryDeck
@onready var dice_tooltip = $CanvasLayer/DiceTooltip
@onready var state_machine: GameStateMachine = $StateMachine


func _ready() -> void:
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


## 3D 주사위와 UI를 GameState의 active_dice와 동기화
func _sync_dice_instances() -> void:
	dice_manager.set_dice_instances(GameState.active_dice)
	dice_stats.setup(camera_3d, dice_manager)


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
