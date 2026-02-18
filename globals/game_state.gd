extends Node

signal phase_changed(phase: Phase)
signal score_changed(score: int)
signal round_changed(round_num: int)
signal rerolls_changed(remaining: int)
signal pool_changed()
signal hand_changed()
signal active_changed()
signal game_over(won: bool)
signal transitioning_changed(is_transitioning: bool) ## 전환 애니메이션 상태 변경
signal draws_changed(remaining: int)

enum Phase {SETUP, PRE_ROLL, ROLLING, POST_ROLL, SCORING, GAME_OVER}

const DICE_COUNT: int = 5 ## Active 슬롯 수 (동시에 굴리는 주사위 개수)
const MAX_FACE_VALUE: int = 6 ## 주사위 최대 눈 (6면체)
const MAX_REROLLS: int = 2 ## 라운드당 최대 리롤 횟수

const DOUBLE_DOWN_COST: int = 2
const DOUBLE_DOWN_MULTIPLIER: float = 2.0
const BASE_MAX_DRAWS: int = 1

var inventory := Inventory.new()
var deck := Deck.new()
var is_double_down: bool = false

var current_phase: Phase = Phase.SETUP
var rerolls_remaining: int = MAX_REROLLS
var draws_remaining: int = 1
var max_draws_per_round: int = 1
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
		return deck.active_dice


func _ready() -> void:
	# 덱 시그널 연결
	deck.pool_changed.connect(pool_changed.emit)
	deck.hand_changed.connect(hand_changed.emit)
	deck.active_changed.connect(active_changed.emit)


#region Hand ↔ Active 이동 (PRE_ROLL에서 개별 클릭)
## Hand에서 단일 주사위를 Active로 이동
## @return 성공 시 Active 내 인덱스
func move_single_to_active(hand_index: int) -> int:
	return deck.move_single_to_active(hand_index)


## Active에서 단일 주사위를 Hand로 이동
## @return 성공 시 Hand 내 인덱스
func move_single_to_hand(active_index: int) -> int:
	return deck.move_single_to_hand(active_index)

## 점수 기록 (State Machine이 전환을 관리하므로 _start_round 호출하지 않음)
## @return 점수가 성공적으로 기록되었는지
func record_score(category_id: String, score: int) -> bool:
	# Burst는 0점으로 기록 (업그레이드 없음)
	if category_id == "burst":
		GameState.score_changed.emit(GameState.total_score)
		return true

	var upgrade := MetaState.get_upgrade(category_id)
	if not upgrade:
		return false

	# 배수 적용
	var multiplied_score := int(score * upgrade.get_total_multiplier())
	# Double Down 배수 적용
	if is_double_down:
		multiplied_score = int(multiplied_score * DOUBLE_DOWN_MULTIPLIER)
	GameState.total_score += multiplied_score
	GameState.score_changed.emit(GameState.total_score)
	return true

## Hand에서 선택된 인덱스의 주사위들을 Active로 이동 (일괄)
func move_hand_to_active(hand_indices: Array[int]) -> bool:
	if current_phase != Phase.PRE_ROLL:
		return false
	return deck.move_hand_to_active(hand_indices)
#endregion

func can_draw() -> bool:
	return draws_remaining > 0 and deck.can_draw()


func draw_one() -> bool:
	if not can_draw():
		return false
	deck.draw_to_hand(1)
	draws_remaining -= 1
	draws_changed.emit(draws_remaining)
	return true


func can_reroll() -> bool:
	return rerolls_remaining > 0


func can_double_down() -> bool:
	return rerolls_remaining >= DOUBLE_DOWN_COST and not is_double_down

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
