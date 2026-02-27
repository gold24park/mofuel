extends Node

signal phase_changed(phase: Phase)
signal rerolls_changed(remaining: int)
signal pool_changed()
signal hand_changed()
signal active_changed()
signal game_over(won: bool)
signal transitioning_changed(is_transitioning: bool) ## 전환 애니메이션 상태 변경
signal draws_changed(remaining: int)
signal time_changed(time: float)
signal distance_changed(distance: float)
signal redraws_changed(remaining: int)
signal timer_running_changed(running: bool)

enum Phase {SETUP, PRE_ROLL, ROLLING, POST_ROLL, CONVERSION, GAME_OVER}

const DICE_COUNT: int = 5 ## Active 슬롯 수 (동시에 굴리는 주사위 개수)
const MAX_FACE_VALUE: int = 6 ## 주사위 최대 눈 (6면체)
const MAX_REROLLS: int = 3 ## 게임당 최대 리롤 횟수

const DOUBLE_DOWN_COST: int = 2
const DOUBLE_DOWN_MULTIPLIER: float = 2.0

const BASE_TIME: float = 7.0 ## 기본 타이머 (초)
const MAX_REDRAWS: int = 2 ## 게임당 리드로우 횟수
const HAND_DRAW_COUNT: int = 8 ## PRE_ROLL에서 Hand로 드로우하는 수
const DISTANCE_FACTOR: float = 1.0 ## 점수→거리 환산 비율
const TIME_FACTOR: float = 0.05 ## 점수→시간 환산 비율

var inventory := Inventory.new()
var deck := Deck.new()
var is_double_down: bool = false

var current_phase: Phase = Phase.SETUP
var rerolls_remaining: int = MAX_REROLLS
var draws_remaining: int = 1
var is_transitioning: bool = false: ## 전환 중 입력 차단
	set(value):
		if is_transitioning != value:
			is_transitioning = value
			transitioning_changed.emit(value)

# 타이머
var remaining_time: float = BASE_TIME
var timer_running: bool = false

# 거리
var remaining_distance: float = 100.0
var target_distance: float = 100.0

# 리드로우
var redraws_remaining: int = MAX_REDRAWS

var active_dice: Array[DiceInstance]:
	get:
		return deck.active_dice


func _ready() -> void:
	# 덱 시그널 연결
	deck.pool_changed.connect(pool_changed.emit)
	deck.hand_changed.connect(hand_changed.emit)
	deck.active_changed.connect(active_changed.emit)


func _process(delta: float) -> void:
	if not timer_running:
		return
	if remaining_time <= 0:
		return

	remaining_time -= delta
	if remaining_time < 0:
		remaining_time = 0
	time_changed.emit(remaining_time)

	# 시간 초과 → 타이머 정지 (상태 전환은 현재 활성 State가 처리)
	if remaining_time <= 0:
		set_timer_running(false)


#region Timer / Distance
func set_timer_running(running: bool) -> void:
	if timer_running != running:
		timer_running = running
		timer_running_changed.emit(running)


func convert_to_distance(score: int) -> void:
	remaining_distance -= score * DISTANCE_FACTOR
	if remaining_distance < 0:
		remaining_distance = 0
	distance_changed.emit(remaining_distance)


func convert_to_time(score: int) -> void:
	remaining_time += score * TIME_FACTOR
	time_changed.emit(remaining_time)


func is_game_won() -> bool:
	return remaining_distance <= 0


func is_time_up() -> bool:
	return remaining_time <= 0
#endregion


#region Redraw
func can_redraw() -> bool:
	return redraws_remaining > 0


func redraw() -> bool:
	if not can_redraw():
		return false
	redraws_remaining -= 1
	redraws_changed.emit(redraws_remaining)
	deck.redraw_hand(HAND_DRAW_COUNT)
	return true
#endregion


#region Hand ↔ Active 이동 (PRE_ROLL에서 개별 클릭)
## Hand에서 단일 주사위를 Active로 이동
## @return 성공 시 Active 내 인덱스
func move_single_to_active(hand_index: int) -> int:
	return deck.move_single_to_active(hand_index)


## Active에서 단일 주사위를 Hand로 이동
## @return 성공 시 Hand 내 인덱스
func move_single_to_hand(active_index: int) -> int:
	return deck.move_single_to_hand(active_index)


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


#region Pending Score (PostRollState → ConversionState 전달용)
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
