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

enum Phase { SETUP, ROUND_START, ACTION, SCORING }

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


func start_new_game():
	inventory_manager.init_starting_deck()
	total_score = 0
	current_round = 0
	rerolls_remaining = 2
	swaps_remaining = 1
	
	# MetaState의 사용 횟수 리셋
	MetaState.reset_all_uses()
	
	_setup_phase()


func _setup_phase():
	current_phase = Phase.SETUP
	phase_changed.emit(current_phase)

	# 초기 핸드 드로우
	inventory_manager.draw_initial_hand(7)

	# 첫 라운드 시작
	_start_round()


func _start_round():
	current_round += 1

	# Active 주사위를 Hand로 복귀 (첫 라운드가 아닌 경우)
	if current_round > 1:
		inventory_manager.return_active_to_hand()

	# Draw Phase: Inventory에서 1개 Draw
	inventory_manager.draw_to_hand(1)

	# Hand에서 랜덤 5개를 Active로 선택
	inventory_manager.select_random_active(5)

	current_phase = Phase.ROUND_START
	rerolls_remaining = 2
	swaps_remaining = 1

	# 모든 데이터 준비 후 시그널 발생
	round_changed.emit(current_round)
	rerolls_changed.emit(rerolls_remaining)
	swaps_changed.emit(swaps_remaining)
	phase_changed.emit(current_phase)


#region Swap (첫 굴림 전 1회)
func can_swap() -> bool:
	return current_phase == Phase.ROUND_START and swaps_remaining > 0 and hand.size() > 0 and not is_transitioning


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
	if current_phase != Phase.ROUND_START and current_phase != Phase.ACTION:
		return

	# 다음 페이즈로 전환 (Swap 불가)
	current_phase = Phase.ACTION
	phase_changed.emit(current_phase)


func on_dice_results(values: Array[int]):
	active_changed.emit()

	# 게임 규칙: 리롤 불가 시 자동으로 스코어링 단계로 전환
	if not can_reroll():
		end_turn()
	else:
		# UI에 스코어링 옵션 표시 요청
		show_scoring_options.emit(active_dice)


func reroll_dice(_indices: Array) -> bool:
	if current_phase != Phase.ACTION or rerolls_remaining <= 0:
		return false

	rerolls_remaining -= 1
	rerolls_changed.emit(rerolls_remaining)
	return true


func can_reroll() -> bool:
	return current_phase == Phase.ACTION and rerolls_remaining > 0 and not is_transitioning
#endregion


#region Turn & Scoring
func end_turn():
	current_phase = Phase.SCORING
	phase_changed.emit(current_phase)


func record_score(category_id: String, score: int):
	var upgrade = MetaState.get_upgrade(category_id)
	if upgrade and upgrade.can_use():
		# 배수 적용
		var multiplied_score = int(score * upgrade.get_total_multiplier())
		total_score += multiplied_score
		upgrade.use()
		score_changed.emit(total_score)

		# 승리 체크
		if total_score >= target_score:
			game_over.emit(true)
			return

		# 라운드 체크
		if current_round >= max_rounds:
			game_over.emit(false)
			return

		# 다음 라운드
		_start_round()
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
