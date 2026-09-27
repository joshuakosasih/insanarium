class_name FishInspector
extends RefCounted

static func duration(seconds: float) -> String:
	var total: int = maxi(0, int(seconds))
	return "%dh %02dm %02ds" % [total / 3600, (total / 60) % 60, total % 60]

static func describe(fish: AquariumFish) -> String:
	var life := fish.life
	var age: String = duration(life.age_seconds)
	if not life.age_known:
		age += " tracked; prior age unknown"
	var lifespan: float = minf(FishAging.lifespan_for(fish.genome), fish.profile.maximum_lifespan)
	var age_summary: String = "%s / ~%s (%s)" % [age, duration(lifespan), FishAging.phase(life.age_seconds, lifespan)]
	var parents: String = "Unknown (legacy save)" if life.origin == "Legacy" else "No recorded parents"
	if not life.parent_ids.is_empty():
		parents = " + ".join(life.parent_ids)
	var readiness: String = "Ready for an eligible mate"
	if fish.sex == AquariumFish.Sex.ASEXUAL:
		readiness = "Asexual — does not breed"
	if fish.broodstock:
		readiness = "Solo feeder fry in %s · max 2 live" % duration(fish.brood_left)
	elif fish.growth.stage < 2:
		readiness = "Needs adult growth stage"
	elif fish.hunger >= fish.profile.hungry_threshold:
		readiness = "Needs feeding"
	elif fish.breeding_left > 0:
		readiness = "Cooldown: " + duration(fish.breeding_left)
	var birth: String = "Unknown" if life.birth_sim_time < 0 else duration(life.birth_sim_time) + " tank time"
	var output_kind: String = "waste only" if fish.broodstock or fish.profile.produces_only_waste else "coin/waste"
	return "%s · %s\n%s · %s · %s\nAge: %s\nOrigin: %s\nBorn/introduced: %s\nParents: %s\nHealth: %d/%d · Hunger: %d%%\nMeals: %d · Growth credits: %.1f\nOutput: %.1fs · %s\nBreeding: %s\nSale value: $%d" % [life.id, "Broodstock Guppy" if fish.broodstock else fish.profile.species_name,
		fish.profile.growth_names[fish.growth.stage], AquariumFish.SEX_NAMES[fish.sex], FishMutation.NAMES[fish.mutation.variant],
		age_summary, life.origin, birth, parents, roundi(fish.health.current), roundi(fish.health.maximum), roundi(fish.hunger * 100), fish.growth.meals, fish.growth.growth_credit,
		fish.genome.output_interval(fish.profile.coin_interval), output_kind, readiness, fish.sell_value()]

static func trait_rows(fish: AquariumFish) -> Array[Dictionary]:
	var profile := fish.profile
	var hunts_prey: bool = not profile.eats_pellets_at(fish.growth.stage)
	var hunger_threshold: float = profile.predation_hunger if hunts_prey else profile.hungry_threshold
	var food_endurance: float = hunger_threshold / (profile.hunger_rate_at(fish.growth.stage) * fish.genome.hunger_multiplier())
	var actual_speed: float = fish.swim_speed()
	var coin_chance: float = 0.0 if fish.broodstock or profile.produces_only_waste else fish.genome.coin_chance()
	var lifespan: float = minf(FishAging.lifespan_for(fish.genome), profile.maximum_lifespan)
	var breed_seconds: int = roundi(fish.genome.breeding_cooldown())
	if fish.broodstock:
		breed_seconds = roundi(FishBroodstock.interval_for(fish.genome.fertility_value()))
	return [
		{"title": "Vitality", "value": "%d HP · %.1fh" % [roundi(fish.health.maximum), lifespan / 3600.0], "progress": fish.genome.vitality_value()},
		{"title": "Metabolism", "value": "%ds %s · ×%.2f" % [roundi(food_endurance), "prey" if hunts_prey else "food", fish.genome.growth_multiplier()], "progress": fish.genome.metabolism_value()},
		{"title": "Agility", "value": "%d px/s" % roundi(actual_speed), "progress": fish.genome.speed_value()},
		{"title": "Productivity", "value": "%d%% coin" % roundi(coin_chance * 100.0), "progress": fish.genome.allocation_value()},
		{"title": "Fertility", "value": "%dm %02ds" % [breed_seconds / 60, breed_seconds % 60], "progress": fish.genome.fertility_value()}]
