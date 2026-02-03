class_name DiceTypes

# 주사위 타입 ID 상수
const NORMAL := "normal"
const BIASED_HIGH := "biased_high"
const FIXED_SIX := "fixed_six"
const MULTIPLIER_2X := "multiplier_2x"
const WILDCARD := "wildcard"
const EVEN_ONLY := "even_only"
const ODD_ONLY := "odd_only"
const WILD_SIX := "wild_six"

# 초기 인벤토리 구성 (타입 ID, 개수)
const STARTING_INVENTORY := [
	[NORMAL, 3],
	["king", 1],
	["peasant", 1],
	[EVEN_ONLY, 1],
	[ODD_ONLY, 1],
	[WILD_SIX, 1],
]
