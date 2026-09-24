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
	var lifespan: float = FishAging.lifespan_for(fish.genome)
	var age_summary: String = "%s / ~%s (%s)" % [age, duration(lifespan), FishAging.phase(life.age_seconds, lifespan)]
	var parents: String = "Unknown (legacy save)" if life.origin == "Legacy" else "No recorded parents"
	if not life.parent_ids.is_empty():
		parents = " + ".join(life.parent_ids)
	var readiness: String = "Ready for an eligible mate"
	if fish.sex == AquariumFish.Sex.ASEXUAL:
		readiness = "Asexual — does not breed"
	elif fish.growth.stage < 2:
		readiness = "Needs adult growth stage"
	elif fish.hunger >= fish.profile.hungry_threshold:
		readiness = "Needs feeding"
	elif fish.breeding_left > 0:
		readiness = "Cooldown: " + duration(fish.breeding_left)
	var birth: String = "Unknown" if life.birth_sim_time < 0 else duration(life.birth_sim_time) + " tank time"
	return "%s · %s\n%s · %s · %s\nAge: %s\nOrigin: %s\nBorn/introduced: %s\nParents: %s\nHealth: %d/%d · Hunger: %d%%\nMeals: %d · Growth credits: %.1f\nOutput interval: %.1fs\nBreeding: %s\nSale value: $%d" % [life.id, fish.profile.species_name,
		fish.profile.growth_names[fish.growth.stage], AquariumFish.SEX_NAMES[fish.sex], FishMutation.NAMES[fish.mutation.variant],
		age_summary, life.origin, birth, parents, roundi(fish.health.current), roundi(fish.health.maximum), roundi(fish.hunger * 100), fish.growth.meals, fish.growth.growth_credit,
		fish.genome.output_interval(fish.profile.coin_interval), readiness, fish.sell_value()]

static func trait_rows(fish: AquariumFish) -> Array[Dictionary]:
	var profile := fish.profile
	var food_endurance: float = profile.hungry_threshold / (profile.hunger_rate * fish.genome.hunger_multiplier())
	var minimum_food_endurance: float = profile.hungry_threshold / (profile.hunger_rate * FishGenome.hunger_multiplier_for(1.0))
	var maximum_food_endurance: float = profile.hungry_threshold / (profile.hunger_rate * FishGenome.hunger_multiplier_for(0.0))
	var actual_speed: float = fish.swim_speed()
	var minimum_speed: float = profile.swim_speed * FishGenome.MIN_SPEED_MULTIPLIER
	var maximum_speed: float = profile.swim_speed * FishGenome.MAX_SPEED_MULTIPLIER
	var growth_speed: float = fish.genome.growth_multiplier()
	var coin_chance: float = fish.genome.coin_chance()
	var resistance: float = fish.genome.constitution()
	return [
		{"title": "Maximum health", "value": "%d HP" % roundi(fish.health.maximum), "progress": inverse_lerp(FishGenome.MIN_MAX_HEALTH, FishGenome.MAX_MAX_HEALTH, fish.health.maximum)},
		{"title": "Swim speed", "value": "%d px/s" % roundi(actual_speed), "progress": inverse_lerp(minimum_speed, maximum_speed, actual_speed)},
		{"title": "Food endurance", "value": "%ds" % roundi(food_endurance), "progress": inverse_lerp(minimum_food_endurance, maximum_food_endurance, food_endurance)},
		{"title": "Growth speed", "value": "×%.2f" % growth_speed, "progress": inverse_lerp(FishGenome.growth_multiplier_for(0.0), FishGenome.growth_multiplier_for(1.0), growth_speed)},
		{"title": "Coin probability", "value": "%d%%" % roundi(coin_chance * 100.0), "progress": inverse_lerp(FishGenome.coin_chance_for(0.0), FishGenome.coin_chance_for(1.0), coin_chance)},
		{"title": "Water resistance", "value": "%d%%" % roundi(resistance * 100.0), "progress": inverse_lerp(FishGenome.constitution_for(1.0), FishGenome.constitution_for(0.0), resistance)}]
