class_name EffectResult
extends RefCounted
## 효과 실행 결과 - 시각적 피드백 정보 포함


#region 다층 점수 보너스
## 임시 가산 (라운드 종료 시 리셋)
var value_bonus: int = 0

## 임시 배수 (라운드 종료 시 리셋)
var value_multiplier: float = 1.0

## 영구 가산
var permanent_bonus: int = 0

## 영구 배수
var permanent_multiplier: float = 1.0
#endregion


#region 기타 효과
## 와일드카드 여부
var is_wildcard: bool = false

## 롤 값 변경 (-1이면 변경 없음)
var modified_roll_value: int = -1

## 효과 우선순위 (정렬용)
var priority: int = 100
#endregion


#region 시각적 피드백용 출처 정보
## 효과 발생 주사위 인덱스
var source_index: int = -1

## 타겟 주사위 인덱스
var target_index: int = -1

## 효과 소유 주사위 이름 (예: "Golden Dice")
var source_name: String = ""

## 효과 이름 (예: "인접 보너스")
var effect_name: String = ""
#endregion


## 다른 결과와 병합 (여러 효과 누적)
func merge(other) -> void:
	value_bonus += other.value_bonus
	value_multiplier *= other.value_multiplier
	permanent_bonus += other.permanent_bonus
	permanent_multiplier *= other.permanent_multiplier
	is_wildcard = is_wildcard or other.is_wildcard
	if other.modified_roll_value >= 0:
		modified_roll_value = other.modified_roll_value


## 효과가 있는지 확인
func has_effect() -> bool:
	return value_bonus != 0 or value_multiplier != 1.0 or \
		   permanent_bonus != 0 or permanent_multiplier != 1.0 or \
		   is_wildcard or modified_roll_value >= 0
