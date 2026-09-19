class_name FeedUpgrades
extends RefCounted
## Sequential upgrades; unlocked_tier is the only player feed tier.
signal upgraded(tier: int)
var unlocked_tier: int = 0
var prices: PackedInt32Array = PackedInt32Array([100, 250])

func next_price() -> int:
	return prices[unlocked_tier] if unlocked_tier < prices.size() else 0

func purchase(economy: Economy) -> bool:
	if next_price() == 0 or not economy.spend(next_price()):
		return false
	unlocked_tier += 1
	upgraded.emit(unlocked_tier)
	return true
