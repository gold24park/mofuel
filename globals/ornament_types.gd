class_name OrnamentTypes
## 오너먼트 타입 정의 — DiceTypes 패턴
## 모든 데이터가 여기에 정의됨 (enum 직접 참조)

# Aliases for readability (DiceEffectResource enums 재사용)
const Target := DiceEffectResource.Target
const ModifyTarget := ModifierEffect.ModifyTarget


# 초기 보유 오너먼트 ID
const STARTING_ORNAMENTS := ["extra_reroll", "bonus_chip", "lucky_charm"]


# 모든 오너먼트 타입 데이터
const ALL := [
	{
		"id": "extra_reroll",
		"display_name": "추가 리롤",
		"description": "라운드당 리롤 +1",
		"color": [0.3, 0.7, 1.0], # 파랑
		"shape": [Vector2i(0, 0), Vector2i(1, 0)], # ## (1×2 가로)
		"passive_effects": [
			{"type": "reroll_bonus", "delta": 1},
		],
	},
	{
		"id": "bonus_chip",
		"display_name": "보너스 칩",
		"description": "모든 주사위 +1 보너스",
		"color": [1.0, 0.8, 0.2], # 금색
		"shape": [Vector2i(0, 0)], # # (1×1)
		"dice_effects": [
			{
				"type": "ModifierEffect",
				"target": Target.ALL_DICE,
				"modify_target": ModifyTarget.VALUE_BONUS,
				"delta": 1,
			},
		],
	},
	{
		"id": "lucky_charm",
		"display_name": "행운의 부적",
		"description": "드로우 +1, 모든 주사위 ×1.2",
		"color": [0.2, 0.9, 0.4], # 초록
		"shape": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 1)], # L자
		"passive_effects": [
			{"type": "draw_bonus", "delta": 1},
		],
		"dice_effects": [
			{
				"type": "ModifierEffect",
				"target": Target.ALL_DICE,
				"modify_target": ModifyTarget.VALUE_MULTIPLIER,
				"delta": 1.2,
			},
		],
	},
	{
		"id": "shield",
		"display_name": "방패",
		"description": "리롤 +2",
		"color": [0.6, 0.6, 0.7], # 회색
		"shape": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)], # 2×2 정사각
		"passive_effects": [
			{"type": "reroll_bonus", "delta": 2},
		],
	},
	{
		"id": "amplifier",
		"display_name": "증폭기",
		"description": "모든 주사위 ×1.5",
		"color": [0.9, 0.3, 0.9], # 보라
		"shape": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(1, 1)], # T자
		"dice_effects": [
			{
				"type": "ModifierEffect",
				"target": Target.ALL_DICE,
				"modify_target": ModifyTarget.VALUE_MULTIPLIER,
				"delta": 1.5,
			},
		],
	},
	{
		"id": "tiny_boost",
		"display_name": "작은 강화",
		"description": "모든 주사위 +2 보너스",
		"color": [1.0, 0.5, 0.3], # 주황
		"shape": [Vector2i(0, 0)], # # (1×1)
		"dice_effects": [
			{
				"type": "ModifierEffect",
				"target": Target.ALL_DICE,
				"modify_target": ModifyTarget.VALUE_BONUS,
				"delta": 2,
			},
		],
	},
	{
		"id": "long_bar",
		"display_name": "긴 막대",
		"description": "드로우 +1, 리롤 +1",
		"color": [0.2, 0.8, 0.8], # 청록
		"shape": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0)], # #### (1×4 가로)
		"passive_effects": [
			{"type": "draw_bonus", "delta": 1},
			{"type": "reroll_bonus", "delta": 1},
		],
	},
]
