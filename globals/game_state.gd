extends Node

signal phase_changed(phase: Phase)
signal score_changed(score: int)
signal round_changed(round_num: int)
signal rerolls_changed(remaining: int)
signal inventory_changed()
signal hand_changed()
signal active_changed()
signal game_over(won: bool)
signal show_scoring_options(dice: Array) ## UI에 스코어링 옵션 표시 요청
signal transitioning_changed(is_transitioning: bool) ## 전환 애니메이션 상태 변경

enum Phase {SETUP, PRE_ROLL, ROLLING, POST_ROLL, SCORING, GAME_OVER}

var inventory_manager := InventoryManager.new()

var current_phase: Phase = Phase.SETUP
var rerolls_remaining: int = 2
var total_score: int = 0
var target_score: int = 100
var current_round: int = 0
var max_rounds: int = 5
var is_transitioning: bool = false: ## 라운드 전환 중 입력 차단
	set(value):
		if is_transitioning != value:
			is_transitioning = value
			transitioning_changed.emit(value)

var active_dice: Array[DiceInstance]:
	get:
		return inventory_manager.active_dice


func _ready():
	# 인벤토리 매니저 신호 연결
	inventory_manager.inventory_changed.connect(func(): inventory_changed.emit())
	inventory_manager.hand_changed.connect(func(): hand_changed.emit())
	inventory_manager.active_changed.connect(func(): active_changed.emit())


#region Hand ↔ Active 이동 (PRE_ROLL에서 개별 클릭)
## Hand에서 단일 주사위를 Active로 이동
## @return 성공 시 Active 내 인덱스
func move_single_to_active(hand_index: int) -> int:
	return inventory_manager.move_single_to_active(hand_index)


## Active에서 단일 주사위를 Hand로 이동
## @return 성공 시 Hand 내 인덱스
func move_single_to_hand(active_index: int) -> int:
	return inventory_manager.move_single_to_hand(active_index)

## 점수 기록 (State Machine이 전환을 관리하므로 _start_round 호출하지 않음)
## @return 점수가 성공적으로 기록되었는지
func record_score(category_id: String, score: int) -> bool:
	var upgrade = MetaState.get_upgrade(category_id)
	if not upgrade or not upgrade.can_use():
		return false

	# 배수 적용
	var multiplied_score = int(score * upgrade.get_total_multiplier())
	GameState.total_score += multiplied_score
	upgrade.use()
	GameState.score_changed.emit(GameState.total_score)
	return true

## Hand에서 선택된 인덱스의 주사위들을 Active로 이동 (일괄)
func move_hand_to_active(hand_indices: Array[int]) -> bool:
	if current_phase != Phase.PRE_ROLL:
		return false
	return inventory_manager.move_hand_to_active(hand_indices)
#endregion

func can_reroll() -> bool:
	return rerolls_remaining > 0

func is_game_over() -> bool:
	return total_score >= target_score or current_round >= max_rounds


#region Pending Score (PostRollState → ScoringState 전달용)
class PendingScore:
	var category_id: String
	var score: int

	func _init(cat_id: String, s: int) -> void:
		category_id = cat_id
		score = s

var _pending_score: PendingScore = null

func set_pending_score(category_id: String, score: int) -> void:
	_pending_score = PendingScore.new(category_id, score)

func consume_pending_score() -> PendingScore:
	var result := _pending_score
	_pending_score = null
	return result
#endregion
