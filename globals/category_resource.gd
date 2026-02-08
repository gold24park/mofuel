class_name CategoryResource
extends Resource

enum CategoryType {
	HIGH_DICE,        ## 하이다이스 — 최고 눈 1개
	ONE_PAIR,         ## 원 페어 — 같은 눈 2개
	TWO_PAIR,         ## 투 페어 — 서로 다른 페어 2쌍
	TRIPLE,           ## 트리플 — 같은 눈 3개
	SMALL_STRAIGHT,   ## 스몰 스트레이트 — 연속 4개
	FULL_HOUSE,       ## 풀하우스 — 3+2 조합
	LARGE_STRAIGHT,   ## 라지 스트레이트 — 연속 5개
	FOUR_CARD,        ## 포카드 — 같은 눈 4개
	FIVE_CARD,        ## 파이브카드 — 같은 눈 5개
}

@export var id: String = "high_dice"
@export var display_name: String = "하이다이스"
@export var description: String = "가장 높은 주사위 눈"
@export var category_type: CategoryType = CategoryType.HIGH_DICE
@export var base_uses: int = 1           # 기본 사용 횟수
@export var base_multiplier: float = 1.0 # 기본 배수
@export var max_uses: int = 3            # 최대 사용 횟수
@export var max_multiplier: float = 3.0  # 최대 배수
@export var base_chips: int = 0          # 카테고리 고유 chips (패턴 복잡도 반영, 주사위 값에 가산)
@export var multiplier_upgrade_step: float = 0.5  # 배수 업그레이드 단위
