class_name OfflineProgress
extends RefCounted
## Bounded, deterministic data-only care model. No movement, natural breeding, or aliens.
const MAX_AWAY: float = 28800.0

static func advance(source: Dictionary, now: float) -> Dictionary:
	var data := SaveMigration.upgrade(source)
	var away: float = maxf(0.0, now - float(data.get("saved_at", now)))
	var idle_level: int = int(data.get("asset_levels", {}).get("idle_duration", 0))
	var away_limit: float = IdleAssets.idle_limit_for(idle_level)
	var elapsed: float = minf(away, away_limit) * ActivityPace.IDLE_RATE
	var report := {"away": away, "simulated": elapsed, "capped": away > away_limit, "away_limit": away_limit,
		"first_loss_at": -1.0, "first_water_loss_at": -1.0, "first_old_age_loss_at": -1.0, "stock_empty_at": -1.0, "earned": 0, "collected": 0, "fed": 0, "stock_used": 0, "growth": 0, "mutations": 0, "lost": 0, "water_lost": 0, "old_age_lost": 0, "waste": 0, "spoiled": 0}
	report["shrimp_cleaned"] = 0
	report["pellets_rescued"] = 0
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(JSON.stringify(source))
	var diamond_bag := FishDiamondBag.new()
	diamond_bag.from_data(data.get("guppy_diamond_bag", []))
	var profile := FishProfile.new()
	var profiles := {"starter_fish": profile, "piranha": FishProfile.for_species("piranha"), "feeder_guppy": FishProfile.for_species("feeder_guppy")}
	var feeds := FeedProfile.tiers()
	var owned: Dictionary = data.get("owned", {})
	var asset_levels: Dictionary = data.get("asset_levels", {})
	var coin_lifetime: float = IdleAssets.coin_lifetime_for(int(asset_levels.get("coin_lifetime", 0)))
	var diamond_lifetime: float = IdleAssets.diamond_lifetime_for(int(asset_levels.get("diamond_lifetime", 0)))
	var coin_multiplier: int = IdleAssets.COIN_MULTIPLIERS[clampi(int(asset_levels.get("coin_value", 0)), 0, IdleAssets.MAX_UPGRADE_LEVEL)]
	var diamond_multiplier: int = IdleAssets.DIAMOND_MULTIPLIERS[clampi(int(asset_levels.get("diamond_value", 0)), 0, IdleAssets.MAX_UPGRADE_LEVEL)]
	var reserve: Array = data.get("reserve", []).duplicate()
	var fish_list: Array = data.get("fish", []).duplicate(true)
	var next_fish_id: int = int(data.get("next_fish_id", 1))
	report["brood_fry"] = 0
	report["preyed"] = 0
	var food: Array = data.get("food", []).duplicate(true)
	var rewards: Array = data.get("coins", []).duplicate(true)
	var waste: Array = data.get("waste", []).duplicate(true)
	var cleanliness: float = clampf(float(data.get("cleanliness", TankEnvironment.MAX_CLEANLINESS)), 0.0, TankEnvironment.MAX_CLEANLINESS)
	var feeder: float = float(data.get("feeder_left", 2.0))
	var seahorse_interval: float = IdleAssets.SEAHORSE_INTERVALS[clampi(int(asset_levels.get("seahorse_interval", 0)), 0, IdleAssets.SEAHORSE_INTERVALS.size() - 1)]
	var seahorse_tier: int = IdleAssets.SEAHORSE_FEED_TIERS[clampi(int(asset_levels.get("seahorse_feed", 0)), 0, IdleAssets.SEAHORSE_FEED_TIERS.size() - 1)]
	var seahorse: float = clampf(float(data.get("seahorse_left", seahorse_interval)), 0.0, seahorse_interval)
	var seahorse_served: Array = data.get("seahorse_served", []).duplicate()
	var sponge_rate: float = IdleAssets.SPONGE_RATES[clampi(int(asset_levels.get("sponge_breath", 0)), 0, IdleAssets.MAX_UPGRADE_LEVEL)] if bool(owned.get("sponge", false)) else 0.0
	var snail_progress: float = clampf(float(data.get("snail_collection_progress", 0.0)), 0.0, 0.999)
	var snail_speed: float = IdleAssets.SNAIL_SPEEDS[clampi(int(asset_levels.get("snail_speed", 0)), 0, IdleAssets.MAX_UPGRADE_LEVEL)]
	var snail_stamina: float = IdleAssets.SNAIL_STAMINAS[clampi(int(asset_levels.get("snail_stamina", 0)), 0, IdleAssets.MAX_UPGRADE_LEVEL)]
	var snail_sleep: float = IdleAssets.SNAIL_SLEEPS[clampi(int(asset_levels.get("snail_sleep", 0)), 0, IdleAssets.MAX_UPGRADE_LEVEL)]
	var snail_average_speed: float = snail_speed * snail_stamina / (snail_stamina + snail_sleep)
	var snail_collection_rate: float = snail_average_speed / 180.0
	var shrimp_progress: float = clampf(float(data.get("shrimp_cleanup_progress", 0.0)), 0.0, 0.999)
	var shrimp_speed: float = IdleAssets.SHRIMP_SPEEDS[clampi(int(asset_levels.get("shrimp_speed", 0)), 0, IdleAssets.MAX_UPGRADE_LEVEL)]
	var shrimp_digestion: float = IdleAssets.SHRIMP_DIGESTION[clampi(int(asset_levels.get("shrimp_digestion", 0)), 0, IdleAssets.MAX_UPGRADE_LEVEL)]
	var shrimp_cleanup_rate: float = 1.0 / (shrimp_digestion + 240.0 / shrimp_speed)
	# Old starvation clocks were real idle seconds, before shared pace was introduced.
	if int(data.get("pace_version", 1)) < 2:
		for fish in fish_list:
			fish.starving = float(fish.get("starving", 0)) * profile.starvation_grace / 180.0
	data.pace_version = 2
	var remaining: float = elapsed
	while remaining > 0.000001:
		var dt: float = minf(1.0, remaining)
		remaining -= dt
		var pet_count: int = int(bool(owned.get("snail", false))) + int(bool(owned.get("shrimp", false))) + int(bool(owned.get("seahorse", false))) + int(bool(owned.get("puffer", false))) + int(bool(owned.get("sponge", false)))
		cleanliness = clampf(cleanliness + dt * (sponge_rate - (fish_list.size() + pet_count) * TankEnvironment.BIOLOAD_PER_CREATURE - waste.size() * TankEnvironment.WASTE_PER_SECOND), 0.0, TankEnvironment.MAX_CLEANLINESS)
		for waste_item in waste:
			if bool(waste_item.get("settled", float(waste_item.get("y", 642)) >= 642.0)):
				waste_item.settled = true
				waste_item.life = float(waste_item.get("life", FishWaste.FLOOR_LIFETIME)) - dt
			else:
				waste_item.y = minf(642.0, float(waste_item.get("y", 642)) + 24.0 * dt)
				if waste_item.y >= 642.0:
					waste_item.settled = true
		waste = waste.filter(func(item: Dictionary) -> bool: return float(item.get("life", FishWaste.FLOOR_LIFETIME)) > 0.0)
		for coin in rewards:
			var default_reward_lifetime: float = diamond_lifetime if bool(coin.get("diamond", false)) else coin_lifetime
			var grounded: bool = bool(coin.get("grounded", float(coin.get("y", 650)) >= 650.0))
			if not grounded:
				var fall_distance: float = 650.0 - float(coin.get("y", 650))
				var fall_time: float = maxf(0.0, fall_distance / 34.0)
				if fall_time >= dt:
					coin.y = minf(650.0, float(coin.get("y", 650)) + 34.0 * dt)
				else:
					coin.y = 650.0
					coin.grounded = true
					coin.life = float(coin.get("life", default_reward_lifetime)) - (dt - fall_time)
			else:
				coin.grounded = true
				coin.life = float(coin.get("life", default_reward_lifetime)) - dt
		rewards = rewards.filter(func(c: Dictionary) -> bool: return c.life > 0.0)
		var grounded_rewards: Array = rewards.filter(func(c: Dictionary) -> bool: return bool(c.get("grounded", float(c.get("y", 650)) >= 650.0)))
		if owned.get("snail", false) and not grounded_rewards.is_empty():
			snail_progress += snail_collection_rate * dt
			grounded_rewards.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.life < b.life)
			while snail_progress >= 1.0 and not grounded_rewards.is_empty():
				var collected_coin: Dictionary = grounded_rewards.pop_front()
				report.collected += int(collected_coin.value)
				rewards.erase(collected_coin)
				snail_progress -= 1.0
		else:
			snail_progress = minf(snail_progress, 0.999)
		for pellet in food:
			if bool(pellet.get("settled", float(pellet.get("y", 350.0)) >= 640.0)):
				pellet.settled = true
				pellet.life = float(pellet.get("life", 14.0)) - dt
			else:
				var fall_time: float = maxf(0.0, 640.0 - float(pellet.get("y", 350.0))) / FishFood.FALL_SPEED
				pellet.y = minf(640.0, float(pellet.get("y", 350.0)) + FishFood.FALL_SPEED * dt)
				if pellet.y >= 640.0:
					pellet.settled = true
					pellet.life = float(pellet.get("life", 14.0)) - maxf(0.0, dt - fall_time)
		var settled_waste: Array = waste.filter(func(item: Dictionary) -> bool: return bool(item.get("settled", false)))
		var endangered_food: Array = food.filter(func(pellet: Dictionary) -> bool:
			return float(pellet.get("y", 350.0)) >= 640.0 and float(pellet.get("life", 14.0)) > 0.0 and float(pellet.get("life", 14.0)) <= CleanupShrimpPet.PELLET_RESCUE_TIME)
		if owned.get("shrimp", false) and (not settled_waste.is_empty() or not endangered_food.is_empty()):
			shrimp_progress += shrimp_cleanup_rate * dt
			settled_waste.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a.get("life", FishWaste.FLOOR_LIFETIME)) < float(b.get("life", FishWaste.FLOOR_LIFETIME)))
			endangered_food.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a.get("life", 14.0)) < float(b.get("life", 14.0)))
			while shrimp_progress >= 1.0 and (not settled_waste.is_empty() or not endangered_food.is_empty()):
				if not settled_waste.is_empty():
					var cleaned_waste: Dictionary = settled_waste.pop_front()
					waste.erase(cleaned_waste)
					cleanliness = minf(TankEnvironment.MAX_CLEANLINESS, cleanliness + TankEnvironment.SHRIMP_WASTE_RECOVERY)
					report.shrimp_cleaned += 1
				else:
					var rescued: Dictionary = endangered_food.pop_front()
					food.erase(rescued)
					report.pellets_rescued += 1
				shrimp_progress -= 1.0
		else:
			shrimp_progress = minf(shrimp_progress, 0.999)
		for pellet_index in range(food.size() - 1, -1, -1):
			if float(food[pellet_index].get("life", 14.0)) <= 0.0:
				food.remove_at(pellet_index)
				cleanliness = maxf(0.0, cleanliness - TankEnvironment.SPOILED_PELLET_POLLUTION)
				report.spoiled += 1
		var hungry: bool = false
		var hungry_ids: Array[String] = []
		for fish in fish_list:
			var fish_profile: FishProfile = profiles.get(str(fish.get("species_id", "starter_fish")), profile)
			var metabolism: float = FishGenome.phenotype_from_data(fish.get("genome", {}), "metabolism")
			fish.hunger = minf(1.0, float(fish.get("hunger", 0)) + fish_profile.hunger_rate_at(int(fish.get("stage", 0))) * FishGenome.hunger_multiplier_for(metabolism) * dt)
			fish.life.age = float(fish.life.age) + dt
			fish.breeding_left = maxf(0.0, float(fish.get("breeding_left", 0)) - dt)
			if fish_profile.eats_pellets_at(int(fish.get("stage", 0))) and fish.hunger >= fish_profile.hungry_threshold:
				hungry = true
				hungry_ids.append(str(fish.life.id))
		for i in range(seahorse_served.size() - 1, -1, -1):
			if not str(seahorse_served[i]) in hungry_ids:
				seahorse_served.remove_at(i)
		# Serum broodstock keep their own clock and saved per-fish booster state.
		var new_fry: Array = []
		for parent in fish_list:
			if not bool(parent.get("broodstock", false)):
				continue
			parent.brood_left = maxf(0.0, float(parent.get("brood_left", 0)) - dt)
			if parent.brood_left > 0.0 or not bool(data.get("breeding_enabled", true)) or float(parent.hunger) >= profile.hungry_threshold or fish_list.size() + new_fry.size() >= (25 if int(data.get("tank_index", 1)) == 2 else FishBreeding.CAPACITY):
				continue
			var live_fry: int = 0
			for candidate in fish_list + new_fry:
				if str(candidate.get("species_id", "")) == "feeder_guppy" and str(parent.life.id) in candidate.get("life", {}).get("parents", []):
					live_fry += 1
			if live_fry >= FishBroodstock.live_limit_for(bool(parent.get("brood_boosted", false))):
				continue
			var fry_genome: Dictionary = parent.get("genome", {}).duplicate(true)
			var fry_life := {"id": "F%06d" % next_fish_id, "parents": [str(parent.life.id)], "age": 0.0, "born_at": float(data.get("simulation_elapsed", 0)) + elapsed - remaining, "age_known": true, "origin": "Feeder fry"}
			next_fish_id += 1
			new_fry.append({"x": parent.get("x", 550), "y": parent.get("y", 350), "hunger": 0.1, "health": FishGenome.max_health_for(FishGenome.phenotype_from_data(fry_genome, "vitality")), "genome": fry_genome, "life": fry_life, "species_id": "feeder_guppy", "sex": 2, "breeding_left": 0.0, "broodstock": false, "brood_boosted": false, "brood_left": 0.0, "starving": 0.0, "meals": 0, "credit": 0.0, "stage": 0, "diamond_trial_done": false, "mutation": 0, "coin_left": 20.0})
			parent.brood_left = FishBroodstock.interval_for(FishGenome.phenotype_from_data(parent.get("genome", {}), "fertility"), bool(parent.get("brood_boosted", false)))
			report.brood_fry += 1
		fish_list.append_array(new_fry)
		var eaten_ids: Dictionary = {}
		for predator in fish_list:
			if str(predator.get("species_id", "")) != "piranha" or int(predator.get("stage", 0)) < 2 or float(predator.hunger) < profiles.piranha.predation_hunger:
				continue
			var prey: Dictionary = {}
			for candidate in fish_list:
				if eaten_ids.has(str(candidate.life.id)) or int(candidate.get("stage", 0)) > 1:
					continue
				if str(candidate.get("species_id", "")) == "feeder_guppy":
					prey = candidate
					break
				if prey.is_empty() and str(candidate.get("species_id", "")) == "starter_fish":
					prey = candidate
			if not prey.is_empty():
				eaten_ids[str(prey.life.id)] = true
				predator.hunger = maxf(0.0, float(predator.hunger) - profiles.piranha.prey_nutrition)
				predator.starving = 0.0
				predator.meals = int(predator.get("meals", 0)) + 1
				predator.credit = float(predator.get("credit", 0)) + profiles.piranha.prey_growth_credit
				report.preyed += 1
		feeder -= dt
		seahorse = maxf(0.0, seahorse - dt)
		if feeder <= 0.0:
			feeder = 2.0
			if owned.get("feeder", false) and hungry and not reserve.is_empty() and food.size() < 80:
				food.append({"tier": reserve.pop_front(), "life": 14.0, "x": 550, "y": 205, "settled": false})
				report.stock_used += 1
				if reserve.is_empty():
					report.stock_empty_at = elapsed - remaining
		if seahorse <= 0.0 and owned.get("seahorse", false) and food.size() < 80:
			for fish_id in hungry_ids:
				if not fish_id in seahorse_served:
					food.append({"tier": seahorse_tier, "life": 14.0, "x": 550, "y": 320, "settled": false})
					seahorse_served.append(fish_id)
					seahorse = seahorse_interval
					break
		# Abstract availability: hungry fish can reach pellets; prioritize greatest need.
		fish_list.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.hunger > b.hunger)
		var survivors: Array = []
		for fish in fish_list:
			if eaten_ids.has(str(fish.life.id)):
				continue
			var fish_profile: FishProfile = profiles.get(str(fish.get("species_id", "starter_fish")), profile)
			var genome_data: Dictionary = fish.get("genome", {})
			var metabolism: float = FishGenome.phenotype_from_data(genome_data, "metabolism")
			var allocation: float = FishGenome.phenotype_from_data(genome_data, "allocation")
			var vitality: float = FishGenome.phenotype_from_data(genome_data, "vitality")
			if float(fish.life.age) >= minf(FishAging.lifespan_from_data(genome_data), fish_profile.maximum_lifespan):
				report.lost += 1
				report.old_age_lost += 1
				if report.first_old_age_loss_at < 0.0:
					report.first_old_age_loss_at = elapsed - remaining
				continue
			var health_rate: float = FishHealth.rate_for_conditions(cleanliness, fish.hunger < fish_profile.hungry_threshold)
			var constitution: float = FishGenome.constitution_for(allocation)
			health_rate = health_rate * constitution if health_rate >= 0.0 else health_rate / constitution
			var maximum_health: float = FishGenome.max_health_for(vitality)
			fish.health = clampf(float(fish.get("health", maximum_health)) + health_rate * dt, 0.0, maximum_health)
			if fish.health <= 0.0:
				report.lost += 1
				report.water_lost += 1
				if report.first_water_loss_at < 0.0:
					report.first_water_loss_at = elapsed - remaining
				continue
			if fish_profile.eats_pellets_at(int(fish.get("stage", 0))) and fish.hunger >= fish_profile.hungry_threshold and not food.is_empty():
				var pellet: Dictionary = food.pop_front()
				var feed: FeedProfile = feeds[clampi(int(pellet.tier), 0, 2)]
				fish.hunger = maxf(0.0, fish.hunger - feed.nutrition)
				fish.starving = 0.0
				fish.meals = int(fish.get("meals", 0)) + 1
				fish.credit = float(fish.get("credit", 0)) + feed.growth_credit * FishGenome.growth_multiplier_for(metabolism)
				report.fed += 1
				var old_stage: int = int(fish.get("stage", 0))
				for stage in range(fish_profile.max_growth_stage + 1):
					if bool(fish.get("broodstock", false)) and stage >= fish_profile.diamond_stage:
						continue
					if fish.credit >= fish_profile.growth_meals[stage] and fish.meals >= fish_profile.minimum_meals[stage]:
						if stage == fish_profile.diamond_stage and int(fish.get("stage", 0)) < stage:
							if not bool(fish.get("diamond_trial_done", false)):
								fish.diamond_trial_done = true
								var awarded: bool = diamond_bag.draw_with_rng(rng) if fish_profile.species_id == "starter_fish" else rng.randf() < fish_profile.diamond_growth_chance
								if not awarded:
									continue
							else:
								continue
						fish.stage = maxi(int(fish.get("stage", 0)), stage)
				if int(fish.stage) > old_stage:
					report.growth += 1
					if fish_profile.species_id != "feeder_guppy" and int(fish.get("mutation", 0)) == 0 and rng.randf() < 0.08:
						fish.mutation = rng.randi_range(1, 3)
						report.mutations += 1
			fish.starving = float(fish.get("starving", 0)) + dt if fish.hunger >= 1.0 else 0.0
			if fish.starving >= fish_profile.starvation_grace:
				report.lost += 1
				if report.first_loss_at < 0.0:
					report.first_loss_at = elapsed - remaining
				continue
			fish.coin_left = float(fish.get("coin_left", fish_profile.coin_interval)) - dt
			if fish.coin_left <= 0.0:
				fish.coin_left += FishGenome.output_interval_for(fish_profile.coin_interval, metabolism)
				var output_stage: int = int(fish.get("stage", 0))
				if output_stage <= 0:
					pass
				elif bool(fish.get("broodstock", false)) or fish_profile.produces_only_waste or rng.randf() > FishGenome.coin_chance_for(allocation):
					cleanliness = maxf(0.0, cleanliness - TankEnvironment.WASTE_OUTPUT_POLLUTION)
					report.waste += 1
					if waste.size() < 100:
						waste.append({"x": fish.get("x", 550), "y": 642, "settled": true, "life": FishWaste.FLOOR_LIFETIME})
				else:
					var is_diamond: bool = fish_profile.reward_is_diamond(output_stage)
					var value: int = fish_profile.coin_value * fish_profile.growth_rewards[output_stage] * (diamond_multiplier if is_diamond else coin_multiplier)
					report.earned += value
					if rewards.size() < 150:
						rewards.append({"x": fish.get("x", 550), "y": 650, "value": value, "diamond": is_diamond, "grade": fish_profile.reward_grade(output_stage), "life": diamond_lifetime if is_diamond else coin_lifetime, "grounded": true})
					else:
						rewards[0].value = int(rewards[0].value) + value
			survivors.append(fish)
		fish_list = survivors
	data.fish = fish_list
	data.next_fish_id = next_fish_id
	data.guppy_diamond_bag = diamond_bag.to_data()
	data.food = food
	data.coins = rewards
	data.waste = waste
	data.cleanliness = cleanliness
	data.reserve = reserve
	data.feeder_left = feeder
	data.seahorse_left = seahorse
	data.seahorse_served = seahorse_served
	data.snail_collection_progress = snail_progress
	data.shrimp_cleanup_progress = shrimp_progress
	data.money = snappedf(float(data.get("money", 0)) + report.collected, 0.01)
	data.simulation_elapsed = float(data.get("simulation_elapsed", 0)) + elapsed
	data.saved_at = maxf(now, float(source.get("saved_at", now))) # Consume the entire interval, including any capped portion.
	return {"data": data, "report": report}
