extends Node

signal phase_changed(phase: int)
signal score_changed(score: int)
signal round_changed(round_num: int)
signal rerolls_changed(remaining: int)
signal inventory_changed()
signal hand_changed()
signal active_changed()
signal game_over(won: bool)
signal show_scoring_options(dice: Array)  ## UI에 스코어링 옵션 표시 요청

enum Phase { SETUP, ROUND_START, ACTION, SCORING }

var inventory: Array[DiceInstance] = []
var hand: Array[DiceInstance] = []  ## 매 라운드 Active 선택 풀
var active_dice: Array[DiceInstance] = []
var active_values: Array[int] = [0, 0, 0, 0, 0]

var current_phase: int = Phase.SETUP
var rerolls_remaining: int = 2
var total_score: int = 0
var target_score: int = 100
var current_round: int = 0
var max_rounds: int = 5
var _swap_used: bool = false  ## 라운드당 1회 Swap 사용 여부
var is_transitioning: bool = false  ## 라운드 전환 중 입력 차단


func _ready():
	pass


func start_new_game():
	_init_inventory()
	_setup_phase()


func _init_inventory():
	inventory.clear()
	hand.clear()
	active_dice.clear()
	active_values = [0, 0, 0, 0, 0]
	total_score = 0
	current_round = 0
	rerolls_remaining = 2
	_swap_used = false

	# 초기 인벤토리 구성
	for entry in DiceTypes.STARTING_INVENTORY:
		var type_id: String = entry[0]
		var count: int = entry[1]
		for i in range(count):
			var dice = DiceRegistry.create_instance(type_id)
			if dice:
				inventory.append(dice)

	inventory.shuffle()
	inventory_changed.emit()

	# MetaState의 사용 횟수 리셋
	MetaState.reset_all_uses()


func _setup_phase():
	current_phase = Phase.SETUP
	phase_changed.emit(current_phase)

	# 7개를 Hand로 Draw
	for i in range(7):
		if inventory.size() > 0:
			hand.append(inventory.pop_front())

	hand_changed.emit()
	inventory_changed.emit()

	# 첫 라운드 시작
	_start_round()


func _start_round():
	current_round += 1

	# Active 주사위를 Hand로 복귀 (첫 라운드가 아닌 경우)
	_return_active_to_hand()

	# Draw Phase: Inventory에서 1개 Draw
	if inventory.size() > 0:
		hand.append(inventory.pop_front())
		hand_changed.emit()
		inventory_changed.emit()

	# Hand에서 랜덤 5개를 Active로 선택
	_select_random_active()

	current_phase = Phase.ROUND_START
	rerolls_remaining = 2
	_swap_used = false

	# 모든 데이터 준비 후 시그널 발생
	round_changed.emit(current_round)
	rerolls_changed.emit(rerolls_remaining)
	phase_changed.emit(current_phase)


func _return_active_to_hand() -> void:
	for dice in active_dice:
		hand.append(dice)
	active_dice.clear()
	hand_changed.emit()


func _select_random_active() -> void:
	hand.shuffle()
	for i in range(5):
		if hand.size() > 0:
			active_dice.append(hand.pop_front())
	active_changed.emit()
	hand_changed.emit()


#region Swap (첫 굴림 전 1회)
func can_swap() -> bool:
	return current_phase == Phase.ROUND_START and not _swap_used and hand.size() > 0 and not is_transitioning


func swap_dice(active_index: int, hand_index: int) -> bool:
	if not can_swap():
		return false
	if active_index < 0 or active_index >= active_dice.size():
		return false
	if hand_index < 0 or hand_index >= hand.size():
		return false

	# Active ↔ Hand 교환
	var temp = active_dice[active_index]
	active_dice[active_index] = hand[hand_index]
	hand[hand_index] = temp

	_swap_used = true
	active_changed.emit()
	hand_changed.emit()
	return true
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
	active_values = values
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


#region Getters
func get_active_dice_count() -> int:
	return active_dice.size()


func get_hand_count() -> int:
	return hand.size()


func get_inventory_count() -> int:
	return inventory.size()
#endregion
