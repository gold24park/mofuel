extends Node

signal phase_changed(phase: int)
signal score_changed(score: int)
signal round_changed(round_num: int)
signal rerolls_changed(remaining: int)
signal swaps_changed(remaining: int)
signal inventory_changed()
signal hand_changed()
signal active_changed()
signal game_over(won: bool)
signal show_scoring_options(dice: Array)  ## UI에 스코어링 옵션 표시 요청
signal transitioning_changed(is_transitioning: bool)  ## 전환 애니메이션 상태 변경

enum Phase { SETUP, PRE_ROLL, ROLLING, POST_ROLL, SCORING, GAME_OVER }

var inventory_manager := InventoryManager.new()

# 기존 호환성을 위한 Getter들
var inventory: Array[DiceInstance]: get = _get_inventory
var hand: Array[DiceInstance]: get = _get_hand
var active_dice: Array[DiceInstance]: get = _get_active_dice

var current_phase: int = Phase.SETUP
var rerolls_remaining: int = 2
var total_score: int = 0
var target_score: int = 100
var current_round: int = 0
var max_rounds: int = 5
var swaps_remaining: int = 1  ## 라운드당 남은 Swap 횟수
var is_transitioning: bool = false:  ## 라운드 전환 중 입력 차단
	set(value):
		if is_transitioning != value:
			is_transitioning = value
			transitioning_changed.emit(value)


func _ready():
	# 인벤토리 매니저 신호 연결
	inventory_manager.inventory_changed.connect(func(): inventory_changed.emit())
	inventory_manager.hand_changed.connect(func(): hand_changed.emit())
	inventory_manager.active_changed.connect(func(): active_changed.emit())


## 새 게임 데이터 초기화 (State Machine에서 호출)
func start_new_game():
	inventory_manager.init_starting_deck()
	total_score = 0
	current_round = 0
	rerolls_remaining = 2
	swaps_remaining = 1

	# MetaState의 사용 횟수 리셋
	MetaState.reset_all_uses()

	# 초기 핸드 드로우
	inventory_manager.draw_initial_hand(7)

	# 첫 라운드 데이터 준비
	_prepare_first_round()


## 첫 라운드 데이터 준비 (start_new_game에서 호출)
func _prepare_first_round():
	current_round = 1

	# Hand에서 랜덤 5개를 Active로 선택
	inventory_manager.select_random_active(5)

	current_phase = Phase.PRE_ROLL
	rerolls_remaining = 2
	swaps_remaining = 1

	# 시그널 발생 (UI 갱신용)
	round_changed.emit(current_round)
	rerolls_changed.emit(rerolls_remaining)
	swaps_changed.emit(swaps_remaining)
	phase_changed.emit(current_phase)


#region Swap (첫 굴림 전 1회)
func can_swap() -> bool:
	return current_phase == Phase.PRE_ROLL and swaps_remaining > 0 and hand.size() > 0 and not is_transitioning


func swap_dice(active_index: int, hand_index: int) -> bool:
	if not can_swap():
		return false

	if inventory_manager.swap_dice(active_index, hand_index):
		swaps_remaining -= 1
		swaps_changed.emit(swaps_remaining)
		return true
	return false
#endregion


#region Roll
func roll_dice():
	if is_transitioning:
		return
	if current_phase != Phase.PRE_ROLL and current_phase != Phase.POST_ROLL:
		return

	# 다음 페이즈로 전환 (Swap 불가)
	current_phase = Phase.ROLLING
	phase_changed.emit(current_phase)


func on_dice_results(_values: Array[int]):
	current_phase = Phase.POST_ROLL
	phase_changed.emit(current_phase)
	active_changed.emit()

	# 게임 규칙: 리롤 불가 시 자동으로 스코어링 단계로 전환
	if not can_reroll():
		end_turn()
	else:
		# UI에 스코어링 옵션 표시 요청
		show_scoring_options.emit(active_dice)


func reroll_dice(_indices: Array) -> bool:
	if current_phase != Phase.POST_ROLL or rerolls_remaining <= 0:
		return false

	rerolls_remaining -= 1
	rerolls_changed.emit(rerolls_remaining)
	current_phase = Phase.ROLLING
	phase_changed.emit(current_phase)
	return true


func can_reroll() -> bool:
	return current_phase == Phase.POST_ROLL and rerolls_remaining > 0 and not is_transitioning
#endregion


#region Turn & Scoring
func end_turn():
	current_phase = Phase.SCORING
	phase_changed.emit(current_phase)


## 점수 기록 (State Machine이 전환을 관리하므로 _start_round 호출하지 않음)
## @return 점수가 성공적으로 기록되었는지
func record_score(category_id: String, score: int) -> bool:
	var upgrade = MetaState.get_upgrade(category_id)
	if not upgrade or not upgrade.can_use():
		return false

	# 배수 적용
	var multiplied_score = int(score * upgrade.get_total_multiplier())
	total_score += multiplied_score
	upgrade.use()
	score_changed.emit(total_score)
	return true


## 게임 종료 체크 (UI 시그널 발생용)
func check_game_over() -> void:
	if total_score >= target_score:
		game_over.emit(true)
	elif current_round >= max_rounds:
		game_over.emit(false)


## 다음 라운드 데이터 준비 (애니메이션 후 호출, 시그널 없이 데이터만 변경)
func start_next_round_data() -> void:
	current_round += 1

	# Active 주사위를 Hand로 복귀
	inventory_manager.return_active_to_hand()

	# Draw Phase: Inventory에서 1개 Draw
	inventory_manager.draw_to_hand(1)

	# Hand에서 랜덤 5개를 Active로 선택
	inventory_manager.select_random_active(5)

	current_phase = Phase.PRE_ROLL
	rerolls_remaining = 2
	swaps_remaining = 1

	# 시그널 발생 (UI 갱신용)
	round_changed.emit(current_round)
	rerolls_changed.emit(rerolls_remaining)
	swaps_changed.emit(swaps_remaining)
	phase_changed.emit(current_phase)
#endregion


#region Getters/Setters
func _get_inventory() -> Array[DiceInstance]: return inventory_manager.inventory
func _get_hand() -> Array[DiceInstance]: return inventory_manager.hand
func _get_active_dice() -> Array[DiceInstance]: return inventory_manager.active_dice

func get_hand_count() -> int:
	return inventory_manager.get_hand_count()


func get_inventory_count() -> int:
	return inventory_manager.get_inventory_count()
#endregion
