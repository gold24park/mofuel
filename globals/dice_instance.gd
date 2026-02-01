class_name DiceInstance
extends RefCounted

var type: DiceTypeResource
var current_value: int = 0
var wildcard_assigned_value: int = 0


#region Effect Results
## 라운드별 효과 결과 (라운드 종료 시 리셋)
var roll_effects: Array = []
var score_effects: Array = []

## 영구 보너스 (게임 전체 유지)
var permanent_value_bonus: int = 0
var permanent_value_multiplier: float = 1.0
#endregion


func _init(dice_type: DiceTypeResource) -> void:
	if not Guard.verify(dice_type != null, "DiceInstance requires a valid DiceTypeResource"):
		return
	type = dice_type


#region Roll
## 물리적 주사위 값 설정 (효과 적용 전)
func roll(physical_value: int = -1) -> int:
	current_value = physical_value if physical_value > 0 else randi_range(1, 6)
	return current_value


## 롤 효과 결과 적용 (EffectProcessor가 처리한 결과)
func apply_roll_effects_from_results() -> void:
	for result in roll_effects:
		if result.modified_roll_value >= 0:
			current_value = result.modified_roll_value
		# 영구 보너스 누적
		permanent_value_bonus += result.permanent_bonus
		permanent_value_multiplier *= result.permanent_multiplier
#endregion


#region Display
func get_display_value() -> int:
	if wildcard_assigned_value > 0:
		return wildcard_assigned_value
	return current_value


func get_display_text() -> String:
	return type.get_display_text(current_value)
#endregion


#region Wildcard
## value must be 1-6 (caller guarantees this via Scoring._find_best_wildcard_value)
func set_wildcard_value(value: int) -> void:
	assert(value >= 1 and value <= 6, "Wildcard value must be 1-6, got %d" % value)
	wildcard_assigned_value = value


func clear_wildcard_value() -> void:
	wildcard_assigned_value = 0


func is_wildcard() -> bool:
	return type.is_wildcard_value(current_value)
#endregion


#region Scoring
## 모든 효과가 적용된 점수 값 반환
func get_scoring_value() -> int:
	var base := get_display_value()
	var bonus := permanent_value_bonus
	var mult := permanent_value_multiplier

	# 현재 라운드 효과 적용
	for result in score_effects:
		bonus += result.value_bonus
		mult *= result.value_multiplier

	return int((base + bonus) * mult)


## 모든 효과가 적용된 배수 반환
func get_total_score_multiplier() -> float:
	var multiplier := 1.0

	# score_effects의 배수 적용
	for result in score_effects:
		multiplier *= result.value_multiplier
		multiplier *= result.permanent_multiplier

	return multiplier * permanent_value_multiplier
#endregion


#region Effect Management
## 롤 효과 추가 (캡슐화 - 나중에 애니메이션 등 추가 가능)
func add_roll_effect(result: EffectResult) -> void:
	roll_effects.append(result)


## 스코어 효과 추가
func add_score_effect(result: EffectResult) -> void:
	score_effects.append(result)


## 라운드 효과 초기화 (라운드 종료 시 호출)
func clear_round_effects() -> void:
	roll_effects.clear()
	score_effects.clear()


## 모든 효과 초기화 (게임 종료 시 호출)
func clear_all_effects() -> void:
	clear_round_effects()
	permanent_value_bonus = 0
	permanent_value_multiplier = 1.0


## 효과가 있는지 확인
func has_active_effects() -> bool:
	return not roll_effects.is_empty() or not score_effects.is_empty() or \
		   permanent_value_bonus != 0 or permanent_value_multiplier != 1.0
#endregion
