class_name CategoryResource
extends Resource

enum CategoryType {
	ONES,
	TWOS,
	THREES,
	FOURS,
	FIVES,
	SIXES,
	THREE_OF_A_KIND,
	FOUR_OF_A_KIND,
	FULL_HOUSE,
	SMALL_STRAIGHT,
	LARGE_STRAIGHT,
	YACHT,
	CHANCE,
}

@export var id: String = "ones"
@export var display_name: String = "Ones"
@export var description: String = "1의 합계"
@export var category_type: CategoryType = CategoryType.ONES
@export var base_uses: int = 1           # 기본 사용 횟수
@export var base_multiplier: float = 1.0 # 기본 배수
@export var max_uses: int = 3            # 최대 사용 횟수
@export var max_multiplier: float = 3.0  # 최대 배수
@export var fixed_score: int = 0         # 고정 점수 (Full House, Straights, Yacht)
@export var target_number: int = 0       # Ones~Sixes용 타겟 숫자
@export var multiplier_upgrade_step: float = 0.5  # 배수 업그레이드 단위


func is_number_category() -> bool:
	return category_type <= CategoryType.SIXES
