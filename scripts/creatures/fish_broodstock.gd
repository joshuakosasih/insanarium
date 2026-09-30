class_name FishBroodstock
extends RefCounted
## Solo feeder-fry production after serum conversion.
const SERUM_PRICE: int = 180
const BOOSTER_PRICE: int = 400
const MAX_LIVE_FRY: int = 2
const BOOSTED_LIVE_FRY: int = 4
const MAX_INTERVAL: float = 365.0
const MIN_INTERVAL: float = 104.0
const BOOSTED_INTERVAL_FACTOR: float = 0.65
const HUNGER_FACTOR: float = 0.5

static func interval_for(fertility: float, boosted: bool = false) -> float:
	# A max-Fertility boosted broodstock supplies about 3.5 neutral Adult
	# piranhas; the minimum supplies about one. The curve also improves
	# midrange breeders enough throughput to support a Tank 2 predator group.
	var interval: float = lerpf(MAX_INTERVAL, MIN_INTERVAL, pow(clampf(fertility, 0.0, 1.0), 0.1))
	return interval * BOOSTED_INTERVAL_FACTOR if boosted else interval

static func live_limit_for(boosted: bool) -> int:
	return BOOSTED_LIVE_FRY if boosted else MAX_LIVE_FRY

static func can_convert(fish: AquariumFish) -> bool:
	return not fish.dead and fish.profile.species_id == "starter_fish" and fish.growth.stage >= 2 and fish.growth.stage < fish.profile.diamond_stage and not fish.broodstock

static func can_boost(fish: AquariumFish) -> bool:
	return not fish.dead and fish.broodstock and not fish.brood_boosted

static func live_fry_for(parent_id: String, fish_list: Array) -> int:
	var count: int = 0
	for fish in fish_list:
		if fish is AquariumFish and not fish.dead and fish.profile.species_id == "feeder_guppy" and parent_id in fish.life.parent_ids:
			count += 1
	return count
