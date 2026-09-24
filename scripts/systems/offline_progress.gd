class_name OfflineProgress
extends RefCounted
## Bounded, deterministic data-only care model. No movement, breeding, or aliens.
const MAX_AWAY: float = 28800.0

static func advance(source: Dictionary, now: float) -> Dictionary:
	var data := SaveMigration.upgrade(source)
	var away: float = maxf(0.0, now - float(data.get("saved_at", now)))
	var idle_level: int = int(data.get("asset_levels", {}).get("idle_duration", 0))
	var away_limit: float = IdleAssets.idle_limit_for(idle_level)
	var elapsed: float = minf(away, away_limit) * ActivityPace.IDLE_RATE
	var report := {"away": away, "simulated": elapsed, "capped": away > away_limit, "away_limit": away_limit,
		"first_loss_at": -1.0, "first_water_loss_at": -1.0, "first_old_age_loss_at": -1.0, "stock_empty_at": -1.0, "earned": 0, "collected": 0, "fed": 0, "stock_used": 0, "growth": 0, "mutations": 0, "lost": 0, "water_lost": 0, "old_age_lost": 0, "waste": 0, "spoiled": 0}
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(JSON.stringify(source))
	var profile := FishProfile.new()
	var feeds := FeedProfile.tiers()
	var owned: Dictionary = data.get("owned", {})
	var asset_levels: Dictionary = data.get("asset_levels", {})
	var coin_lifetime: float = IdleAssets.coin_lifetime_for(int(asset_levels.get("coin_lifetime", 0)))
	var coin_multiplier: int = IdleAssets.COIN_MULTIPLIERS[clampi(int(asset_levels.get("coin_value", 0)), 0, IdleAssets.MAX_UPGRADE_LEVEL)]
	var reserve: Array = data.get("reserve", []).duplicate()
	var fish_list: Array = data.get("fish", []).duplicate(true)
	var food: Array = data.get("food", []).duplicate(true)
	var rewards: Array = data.get("coins", []).duplicate(true)
	var waste: Array = data.get("waste", []).duplicate(true)
	var cleanliness: float = clampf(float(data.get("cleanliness", TankEnvironment.MAX_CLEANLINESS)), 0.0, TankEnvironment.MAX_CLEANLINESS)
	var feeder: float = float(data.get("feeder_left", 2.0))
	var seahorse: float = float(data.get("seahorse_left", 8.0))
	var snail_progress: float = clampf(float(data.get("snail_collection_progress", 0.0)), 0.0, 0.999)
	var snail_speed: float = IdleAssets.SNAIL_SPEEDS[clampi(int(asset_levels.get("snail_speed", 0)), 0, IdleAssets.MAX_UPGRADE_LEVEL)]
	var snail_stamina: float = IdleAssets.SNAIL_STAMINAS[clampi(int(asset_levels.get("snail_stamina", 0)), 0, IdleAssets.MAX_UPGRADE_LEVEL)]
	var snail_sleep: float = IdleAssets.SNAIL_SLEEPS[clampi(int(asset_levels.get("snail_sleep", 0)), 0, IdleAssets.MAX_UPGRADE_LEVEL)]
	var snail_average_speed: float = snail_speed * snail_stamina / (snail_stamina + snail_sleep)
	var snail_collection_rate: float = snail_average_speed / 180.0
	# Old starvation clocks were real idle seconds, before shared pace was introduced.
	if int(data.get("pace_version", 1)) < 2:
		for fish in fish_list:
			fish.starving = float(fish.get("starving", 0)) * profile.starvation_grace / 180.0
	data.pace_version = 2
	var remaining: float = elapsed
	while remaining > 0.000001:
		var dt: float = minf(1.0, remaining)
		remaining -= dt
		var pet_count: int = int(bool(owned.get("snail", false))) + int(bool(owned.get("seahorse", false))) + int(bool(owned.get("puffer", false)))
		cleanliness = maxf(0.0, cleanliness - dt * ((fish_list.size() + pet_count) * TankEnvironment.BIOLOAD_PER_CREATURE + waste.size() * TankEnvironment.WASTE_PER_SECOND))
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
			var grounded: bool = bool(coin.get("grounded", float(coin.get("y", 650)) >= 650.0))
			if not grounded:
				var fall_distance: float = 650.0 - float(coin.get("y", 650))
				var fall_time: float = maxf(0.0, fall_distance / 34.0)
				if fall_time >= dt:
					coin.y = minf(650.0, float(coin.get("y", 650)) + 34.0 * dt)
				else:
					coin.y = 650.0
					coin.grounded = true
					coin.life = float(coin.get("life", coin_lifetime)) - (dt - fall_time)
			else:
				coin.grounded = true
				coin.life = float(coin.get("life", coin_lifetime)) - dt
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
		for pellet_index in range(food.size() - 1, -1, -1):
			var pellet: Dictionary = food[pellet_index]
			pellet.life = float(pellet.get("life", 14.0)) - dt
			if pellet.life <= 0.0:
				food.remove_at(pellet_index)
				cleanliness = maxf(0.0, cleanliness - TankEnvironment.SPOILED_PELLET_POLLUTION)
				report.spoiled += 1
		var hungry: bool = false
		for fish in fish_list:
			var metabolism: float = FishGenome.phenotype_from_data(fish.get("genome", {}), "metabolism")
			fish.hunger = minf(1.0, float(fish.get("hunger", 0)) + profile.hunger_rate * FishGenome.hunger_multiplier_for(metabolism) * dt)
			fish.life.age = float(fish.life.age) + dt
			fish.breeding_left = maxf(0.0, float(fish.get("breeding_left", 0)) - dt)
			hungry = hungry or fish.hunger >= profile.hungry_threshold
		feeder -= dt
		seahorse -= dt
		if feeder <= 0.0:
			feeder = 2.0
			if owned.get("feeder", false) and hungry and not reserve.is_empty() and food.size() < 80:
				food.append({"tier": reserve.pop_front(), "life": 14.0, "x": 550, "y": 350})
				report.stock_used += 1
				if reserve.is_empty():
					report.stock_empty_at = elapsed - remaining
		if seahorse <= 0.0:
			seahorse = 8.0
			if owned.get("seahorse", false) and hungry and food.size() < 80:
				food.append({"tier": 0, "life": 14.0, "x": 200, "y": 320})
		# Abstract availability: hungry fish can reach pellets; prioritize greatest need.
		fish_list.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.hunger > b.hunger)
		var survivors: Array = []
		for fish in fish_list:
			var genome_data: Dictionary = fish.get("genome", {})
			var metabolism: float = FishGenome.phenotype_from_data(genome_data, "metabolism")
			var allocation: float = FishGenome.phenotype_from_data(genome_data, "allocation")
			var vitality: float = FishGenome.phenotype_from_data(genome_data, "vitality")
			if float(fish.life.age) >= FishAging.lifespan_from_data(genome_data):
				report.lost += 1
				report.old_age_lost += 1
				if report.first_old_age_loss_at < 0.0:
					report.first_old_age_loss_at = elapsed - remaining
				continue
			var health_rate: float = FishHealth.rate_for_conditions(cleanliness, fish.hunger < profile.hungry_threshold)
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
			if fish.hunger >= profile.hungry_threshold and not food.is_empty():
				var pellet: Dictionary = food.pop_front()
				var feed: FeedProfile = feeds[clampi(int(pellet.tier), 0, 2)]
				fish.hunger = maxf(0.0, fish.hunger - feed.nutrition)
				fish.starving = 0.0
				fish.meals = int(fish.get("meals", 0)) + 1
				fish.credit = float(fish.get("credit", 0)) + feed.growth_credit * FishGenome.growth_multiplier_for(metabolism)
				report.fed += 1
				var old_stage: int = int(fish.get("stage", 0))
				for stage in range(profile.growth_meals.size()):
					if fish.credit >= profile.growth_meals[stage] and fish.meals >= profile.minimum_meals[stage]:
						fish.stage = maxi(int(fish.get("stage", 0)), stage)
				if int(fish.stage) > old_stage:
					report.growth += 1
					if int(fish.get("mutation", 0)) == 0 and rng.randf() < 0.08:
						fish.mutation = rng.randi_range(1, 3)
						report.mutations += 1
			fish.starving = float(fish.get("starving", 0)) + dt if fish.hunger >= 1.0 else 0.0
			if fish.starving >= profile.starvation_grace:
				report.lost += 1
				if report.first_loss_at < 0.0:
					report.first_loss_at = elapsed - remaining
				continue
			fish.coin_left = float(fish.get("coin_left", profile.coin_interval)) - dt
			if fish.coin_left <= 0.0:
				fish.coin_left += FishGenome.output_interval_for(profile.coin_interval, metabolism)
				var output_stage: int = int(fish.get("stage", 0))
				if output_stage <= 0:
					pass
				elif rng.randf() > FishGenome.coin_chance_for(allocation):
					cleanliness = maxf(0.0, cleanliness - TankEnvironment.WASTE_OUTPUT_POLLUTION)
					report.waste += 1
					if waste.size() < 100:
						waste.append({"x": fish.get("x", 550), "y": 642, "settled": true, "life": FishWaste.FLOOR_LIFETIME})
				else:
					var value: int = profile.coin_value * profile.growth_rewards[output_stage] * coin_multiplier
					report.earned += value
					if rewards.size() < 150:
						rewards.append({"x": fish.get("x", 550), "y": 650, "value": value, "diamond": output_stage == profile.diamond_stage, "grade": output_stage, "life": coin_lifetime, "grounded": true})
					else:
						rewards[0].value = int(rewards[0].value) + value
			survivors.append(fish)
		fish_list = survivors
	data.fish = fish_list
	data.food = food
	data.coins = rewards
	data.waste = waste
	data.cleanliness = cleanliness
	data.reserve = reserve
	data.feeder_left = feeder
	data.seahorse_left = seahorse
	data.snail_collection_progress = snail_progress
	data.money = snappedf(float(data.get("money", 0)) + report.collected, 0.01)
	data.simulation_elapsed = float(data.get("simulation_elapsed", 0)) + elapsed
	data.saved_at = maxf(now, float(source.get("saved_at", now))) # Consume the entire interval, including any capped portion.
	return {"data": data, "report": report}
