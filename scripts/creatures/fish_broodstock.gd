class_name FishBroodstock
extends RefCounted
## Solo feeder-fry production after serum conversion.
const SERUM_PRICE: int = 180
const MAX_LIVE_FRY: int = 2

static func interval_for(fertility: float) -> float:
	return lerpf(270.0, 150.0, clampf(fertility, 0.0, 1.0))

static func can_convert(fish: AquariumFish) -> bool:
	return not fish.dead and fish.profile.species_id == "starter_fish" and fish.growth.stage >= 2 and not fish.broodstock

static func live_fry_for(parent_id: String, fish_list: Array) -> int:
	var count: int = 0
	for fish in fish_list:
		if fish is AquariumFish and not fish.dead and fish.profile.species_id == "feeder_guppy" and parent_id in fish.life.parent_ids:
			count += 1
	return count
