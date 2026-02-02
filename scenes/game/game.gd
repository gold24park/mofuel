extends Control

## 메인 게임 씬
## State Machine이 대부분의 게임 로직을 처리하고,
## 이 스크립트는 초기화와 공통 유틸리티를 제공

@onready var dice_manager = $SubViewportContainer/SubViewport/World3D/DiceManager
@onready var camera_3d = $SubViewportContainer/SubViewport/World3D/Camera3D
@onready var hud = $CanvasLayer/HUD
@onready var action_buttons = $CanvasLayer/ActionButtons
@onready var score_card = $CanvasLayer/ScoreCard
@onready var game_over_screen = $CanvasLayer/GameOver
@onready var upgrade_screen = $CanvasLayer/UpgradeScreen
@onready var hand_display = $CanvasLayer/HandDisplay
@onready var quick_score = $CanvasLayer/QuickScore
@onready var dice_labels = $CanvasLayer/DiceLabels
@onready var roll_button = $CanvasLayer/RollButton
@onready var inventory_deck = $CanvasLayer/InventoryDeck
@onready var state_machine: GameStateMachine = $StateMachine

var _prev_active_dice: Array = []  ## 이전 라운드의 active dice (애니메이션용)


func _ready():
	# State Machine 초기화
	state_machine.init(self)


## 3D 주사위와 UI를 GameState의 active_dice와 동기화
func _sync_dice_instances():
	dice_manager.set_dice_instances(GameState.active_dice)
	dice_labels.setup(camera_3d, dice_manager.dice_nodes, GameState.active_dice)
