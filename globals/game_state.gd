extends Node

signal phase_changed(phase: int)
signal score_changed(score: int)
signal round_changed(round_num: int)
signal rerolls_changed(remaining: int)
signal inventory_changed()
signal reserve_changed()
signal active_changed()
signal game_over(won: bool)

enum Phase { SETUP, ROUND_START, ACTION, SCORING }

var inventory: Array = []  # DiceInstance array
var reserve: Array = []    # DiceInstance array
var active_dice: Array = []  # DiceInstance array
var active_values: Array = [0, 0, 0, 0, 0]

var current_phase: int = Phase.SETUP
var rerolls_remaining: int = 2
var total_score: int = 0
var target_score: int = 100
var current_round: int = 0
var max_rounds: int = 5


func _ready():
	pass


func start_new_game():
	_init_inventory()
	_setup_phase()


func _init_inventory():
	inventory.clear()
	reserve.clear()
	active_dice.clear()
	active_values = [0, 0, 0, 0, 0]
	total_score = 0
	current_round = 0
	rerolls_remaining = 2

	# 일반 주사위 10개
	for i in range(10):
		var dice = DiceRegistry.create_instance("normal")
		if dice:
			inventory.append(dice)

	inventory.shuffle()
	inventory_changed.emit()

	# MetaState의 사용 횟수 리셋
	MetaState.reset_all_uses()


func _setup_phase():
	current_phase = Phase.SETUP
	phase_changed.emit(current_phase)

	# 7개를 Reserve로 Draw
	for i in range(7):
		if inventory.size() > 0:
			reserve.append(inventory.pop_front())

	reserve_changed.emit()
	inventory_changed.emit()

	# 5개를 Active로 배치
	for i in range(5):
		if reserve.size() > 0:
			active_dice.append(reserve.pop_front())

	active_changed.emit()
	reserve_changed.emit()

	# Round Start로 전환
	_start_round()


func _start_round():
	current_round += 1
	round_changed.emit(current_round)

	# Draw Phase: Inventory에서 1개 Draw
	if inventory.size() > 0:
		reserve.append(inventory.pop_front())
		reserve_changed.emit()
		inventory_changed.emit()

	current_phase = Phase.ROUND_START
	rerolls_remaining = 2
	rerolls_changed.emit(rerolls_remaining)
	phase_changed.emit(current_phase)


func roll_dice():
	if current_phase != Phase.ROUND_START and current_phase != Phase.ACTION:
		return

	# 다음 페이즈로 전환
	current_phase = Phase.ACTION
	phase_changed.emit(current_phase)


func on_dice_results(values: Array):
	active_values = values
	active_changed.emit()


func reroll_dice(_indices: Array) -> bool:
	if current_phase != Phase.ACTION or rerolls_remaining <= 0:
		return false

	rerolls_remaining -= 1
	rerolls_changed.emit(rerolls_remaining)
	return true


func replace_dice(active_index: int, reserve_index: int) -> bool:
	if current_phase != Phase.ACTION:
		return false
	if reserve.size() == 0:
		return false
	if active_index < 0 or active_index >= active_dice.size():
		return false
	if reserve_index < 0 or reserve_index >= reserve.size():
		return false

	# Active에서 제거 (영구 제거)
	active_dice.remove_at(active_index)

	# Reserve에서 Active로 이동
	var new_dice = reserve[reserve_index]
	reserve.remove_at(reserve_index)
	active_dice.insert(active_index, new_dice)

	active_changed.emit()
	reserve_changed.emit()
	return true


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


func get_active_dice_count() -> int:
	return active_dice.size()


func get_reserve_count() -> int:
	return reserve.size()


func get_inventory_count() -> int:
	return inventory.size()


func can_replace() -> bool:
	return current_phase == Phase.ACTION and reserve.size() > 0


func can_reroll() -> bool:
	return current_phase == Phase.ACTION and rerolls_remaining > 0
