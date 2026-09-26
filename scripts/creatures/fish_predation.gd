class_name FishPredation
extends RefCounted
## Shared diet rules for future species and food-chain interactions.

static func eligible(hunter: AquariumFish, prey: AquariumFish) -> bool:
	return hunter != prey and not prey.dead and not prey.is_queued_for_deletion() and hunter.growth.stage >= hunter.profile.hunter_stage and prey.profile.species_id == hunter.profile.prey_species_id and prey.growth.stage <= hunter.profile.max_prey_stage

static func nearest(hunter: AquariumFish, candidates: Array) -> AquariumFish:
	if hunter.profile.prey_species_id.is_empty() or hunter.hunger < hunter.profile.predation_hunger:
		return null
	var nearest_prey: AquariumFish
	var distance: float = hunter.profile.prey_detection_radius
	for candidate in candidates:
		if candidate is AquariumFish and eligible(hunter, candidate):
			var gap: float = hunter.position.distance_to(candidate.position)
			if gap < distance:
				distance = gap
				nearest_prey = candidate
	return nearest_prey
