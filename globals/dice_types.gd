class_name DiceTypes
## 주사위 타입 정의 - 모든 데이터가 여기에 정의됨 (enum 직접 참조)

# Aliases for readability
const Target := DiceEffectResource.Target
const Field := DiceEffectResource.CompareField
const Op := DiceEffectResource.CompareOp
const ModifyTarget := ModifierEffect.ModifyTarget
const Action := ActionEffect.Action
# Special face values
const WILD := DiceTypeResource.FACE_WILDCARD
const SKULL := DiceTypeResource.FACE_SKULL


# 초기 인벤토리 구성 (타입 ID, 개수)
const STARTING_INVENTORY := [
	["king", 4],
	["peasant", 2],
	["even_only", 1],
	["odd_only", 1],
	["wild_six", 1],
]


# 모든 주사위 타입 데이터
const ALL := [
	{
		"id": "_error",
		"display_name": "ERROR",
		"description": "Failed to load dice type",
		"texture": "res://assets/dice/uv/dice_uv_error.png",
	},
	{
		"id": "normal",
		"display_name": "일반 주사위",
		"description": "1~6 균등 확률",
		"texture": "res://assets/dice/uv/dice_uv.png",
	},
	{
		"id": "multiplier_2x",
		"display_name": "배수 주사위",
		"description": "점수 계산 시 2배 적용",
		"effects": [
			{
				"type": "ModifierEffect",
				"target": Target.SELF,
				"modify_target": ModifyTarget.VALUE_MULTIPLIER,
				"delta": 2.0,
			},
		],
	},
	{
		"id": "wildcard",
		"display_name": "와일드카드 주사위",
		"description": "족보 판정 시 원하는 숫자로 사용 가능",
		"face_values": [WILD, WILD, WILD, WILD, WILD, WILD, WILD],
	},
	{
		"id": "odd_only",
		"display_name": "홀수 주사위",
		"description": "1, 3, 5만 나옵니다",
		"texture": "res://assets/dice/uv/dice_uv_odd.png",
		"face_values": [0, 1, 1, 3, 3, 5, 5],
	},
	{
		"id": "even_only",
		"display_name": "짝수 주사위",
		"description": "2, 4, 6만 나옵니다",
		"texture": "res://assets/dice/uv/dice_uv_even.png",
		"face_values": [0, 2, 2, 4, 4, 6, 6],
	},
	{
		"id": "fixed_six",
		"display_name": "고정 주사위",
		"description": "항상 6이 나옵니다",
		"face_values": [0, 6, 6, 6, 6, 6, 6],
	},
	{
		"id": "wild_six",
		"display_name": "와일드 식스",
		"description": "6이 나오면 와일드카드로 사용 가능",
		"texture": "res://assets/dice/uv/dice_uv_wild_6.png",
		"face_values": [WILD, 1, 2, 3, 4, 5, WILD],
	},
	{
		"id": "king",
		"display_name": "왕 주사위",
		"description": "인접 백성에게 +2, 인접 왕에게 -1",
		"groups": ["royal"],
		"texture": "res://assets/dice/uv/dice_uv.png",
		"effects": [
			{
				"type": "ModifierEffect",
				"target": Target.ADJACENT,
				"comparisons": [ {"a": Field.GROUP, "b": "peasant"}],
				"modify_target": ModifyTarget.VALUE_BONUS,
				"delta": 2,
				"anim": "bounce",
			},
			{
				"type": "ModifierEffect",
				"target": Target.ADJACENT,
				"comparisons": [ {"a": Field.GROUP, "b": "royal"}],
				"modify_target": ModifyTarget.VALUE_BONUS,
				"delta": - 1,
				"anim": "shake",
			},
		],
	},
	{
		"id": "peasant",
		"display_name": "백성 주사위",
		"description": "평범한 주사위",
		"groups": ["peasant"],
		"texture": "res://assets/dice/uv/dice_uv.png",
	},
	{
		"id": "draw",
		"display_name": "드로우 주사위",
		"description": "6이 나오면 추가 드로우 +1",
		"effects": [
			{
				"type": "ActionEffect",
				"target": Target.SELF,
				"comparisons": [ {"a": Field.VALUE, "b": 6}],
				"action": Action.ADD_DRAWS,
				"delta": 1,
			},
		],
	},
	{
		"id": "skull",
		"display_name": "해골 주사위",
		"description": "6면이 해골 — 해골이 나오면 파괴",
		"face_values": [WILD, 1, 2, 3, 4, 5, SKULL],
		"effects": [
			{
				"type": "ActionEffect",
				"target": Target.SELF,
				"comparisons": [ {"a": Field.VALUE, "b": SKULL}],
				"action": Action.DESTROY_SELF,
				"anim": "shake",
			},
		],
	},
	{
		"id": "evolve",
		"display_name": "진화 주사위",
		"description": "3번 굴리면 배수 주사위로 진화",
		"effects": [
			{
				"type": "ActionEffect",
				"target": Target.SELF,
				"comparisons": [ {"a": Field.ROLL_COUNT, "b": 3, "op": Op.GTE}],
				"action": Action.TRANSFORM,
				"params": {"to": "multiplier_2x"},
				"anim": "bounce",
			},
		],
	},
]
