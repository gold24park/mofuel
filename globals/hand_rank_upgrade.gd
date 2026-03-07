class_name HandRankUpgrade
extends RefCounted

var hand_rank: HandRankResource = null
var extra_multiplier: float = 0.0


func init_with_hand_rank(cat: HandRankResource) -> HandRankUpgrade:
	assert(cat != null, "HandRankUpgrade: hand_rank cannot be null")
	hand_rank = cat
	return self


func get_total_multiplier() -> float:
	assert(hand_rank != null, "HandRankUpgrade not initialized")
	return hand_rank.base_multiplier + extra_multiplier


func can_upgrade_multiplier() -> bool:
	assert(hand_rank != null, "HandRankUpgrade not initialized")
	return get_total_multiplier() < hand_rank.max_multiplier


func upgrade_multiplier() -> bool:
	if can_upgrade_multiplier():
		extra_multiplier += hand_rank.multiplier_upgrade_step
		return true
	return false
