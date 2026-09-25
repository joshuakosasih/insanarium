extends SceneTree
## Multi-seed active-play balance probe using the real aquarium entities and systems.
## Player profiles differ only in attention and purchase policy; no rewards are invented.

const RUNS_PER_PROFILE := 20
const DURATION := 5400.0
const STEP := 1.0
const REPORT_EVERY_STEPS := 180
const PROFILES := [
	{"name": "Attentive optimizer", "bubble": 0.95, "coin": 0.95, "waste": 0.90, "feed": 0.95, "alien": 0.95, "alien_hits": 8, "action_every": 1.0, "clean_at": 58.0, "strategy": "optimizer"},
	{"name": "Typical player", "bubble": 0.80, "coin": 0.80, "waste": 0.75, "feed": 0.85, "alien": 0.80, "alien_hits": 8, "action_every": 2.0, "clean_at": 48.0, "strategy": "balanced"},
	{"name": "Typical without aliens", "bubble": 0.80, "coin": 0.80, "waste": 0.75, "feed": 0.85, "alien": 0.0, "alien_hits": 0, "action_every": 2.0, "clean_at": 48.0, "strategy": "balanced", "challenges": false},
	{"name": "Relaxed player", "bubble": 0.50, "coin": 0.55, "waste": 0.45, "feed": 0.65, "alien": 0.55, "alien_hits": 8, "action_every": 4.0, "clean_at": 35.0, "strategy": "balanced"},
	{"name": "Pet-first player", "bubble": 0.80, "coin": 0.80, "waste": 0.75, "feed": 0.85, "alien": 0.80, "alien_hits": 8, "action_every": 2.0, "clean_at": 48.0, "strategy": "pets"}
]

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var started := Time.get_ticks_msec()
	for profile in PROFILES:
		var results: Array[Dictionary] = []
		for run_index in range(RUNS_PER_PROFILE):
			results.append(await simulate(profile, 20260925 + run_index * 7919 + results.size() * 17))
		print_profile(profile.name, results)
	print("Monte Carlo runtime: %.2fs" % ((Time.get_ticks_msec() - started) / 1000.0))
	quit()

func simulate(profile: Dictionary, run_seed: int) -> Dictionary:
	seed(run_seed)
	ActivityPace.multiplier = 1.0
	var tank = load("res://scenes/aquarium.tscn").instantiate()
	root.add_child(tank)
	tank.set_process(false)
	tank.invasions.set_process(false)
	if not bool(profile.get("challenges", true)):
		tank.set_challenges_enabled(false)
	var result := {"wallet": 0.0, "wallet_min": tank.economy.money, "fish": 0, "deaths": 0, "extinction": -1.0, "clicks": 0,
		"teen": -1.0, "adult": -1.0, "royal": -1.0, "diamond": -1.0,
		"snail": -1.0, "shrimp": -1.0, "seahorse": -1.0, "puffer": -1.0, "feeder": -1.0, "coin_upgrade": -1.0}
	var seen_bubbles: Dictionary = {}
	var seen_coins: Dictionary = {}
	var seen_waste: Dictionary = {}
	var tracked_fish: Dictionary = {}
	var death_counter := [0]
	var death_reasons: Dictionary = {}
	var next_action := 0.0
	var next_purchase := 0.0
	var elapsed := 0.0
	var step_index := 0
	while elapsed < DURATION:
		track_fish_deaths(tracked_fish, death_counter, death_reasons)
		tank._process(STEP)
		tank.invasions._process(STEP)
		if elapsed >= next_action:
			next_action += float(profile.action_every)
			perform_player_actions(tank, profile, seen_bubbles, seen_coins, seen_waste, result)
		if elapsed >= next_purchase:
			next_purchase += 10.0
			if try_purchase(tank, str(profile.strategy), elapsed, result):
				result.clicks += 1
		for group in ["fish", "food", "coins", "waste", "pets", "income_bubbles", "invaders"]:
			for entity in get_nodes_in_group(group):
				entity.set_process(false)
				if not entity.is_queued_for_deletion():
					entity._process(STEP)
		elapsed += STEP
		step_index += 1
		record_milestones(result, elapsed)
		result.wallet_min = minf(float(result.wallet_min), tank.economy.money)
		if get_nodes_in_group("fish").is_empty() and float(result.extinction) < 0.0:
			result.extinction = elapsed
		if step_index % REPORT_EVERY_STEPS == 0:
			await process_frame
	result.deaths = death_counter[0]
	result.death_reasons = death_reasons.duplicate()
	result.wallet = tank.economy.money
	result.fish = get_nodes_in_group("fish").size()
	result.clicks_per_minute = float(result.clicks) / (DURATION / 60.0)
	tank.free()
	await process_frame
	return result

func track_fish_deaths(tracked: Dictionary, counter: Array, reasons: Dictionary) -> void:
	for fish in get_nodes_in_group("fish"):
		var id := fish.get_instance_id()
		if tracked.has(id):
			continue
		tracked[id] = true
		fish.died.connect(func(_at: Vector2, reason: String) -> void:
			counter[0] = int(counter[0]) + 1
			reasons[reason] = int(reasons.get(reason, 0)) + 1)

func perform_player_actions(tank, profile: Dictionary, seen_bubbles: Dictionary, seen_coins: Dictionary, seen_waste: Dictionary, result: Dictionary) -> void:
	for bubble in get_nodes_in_group("income_bubbles"):
		var id := bubble.get_instance_id()
		if not seen_bubbles.has(id):
			seen_bubbles[id] = true
			if randf() <= float(profile.bubble):
				bubble.pop()
				result.clicks += 1
	for coin in get_nodes_in_group("coins"):
		var id := coin.get_instance_id()
		if not seen_coins.has(id):
			seen_coins[id] = true
			if randf() <= float(profile.coin):
				coin.collect()
				result.clicks += 1
	for waste in get_nodes_in_group("waste"):
		var id := waste.get_instance_id()
		if not seen_waste.has(id):
			seen_waste[id] = true
			if randf() <= float(profile.waste):
				tank.clean_waste(waste)
				result.clicks += 1
	for alien in get_nodes_in_group("invaders"):
		if randf() <= float(profile.alien) and not alien.dead:
			for hit_index in range(int(profile.alien_hits)):
				if alien.dead:
					break
				alien.hit(alien.position + Vector2(24, 0))
				result.clicks += 1
	var automated_food: bool = (tank.assets.owned.feeder and not tank.assets.reserve.is_empty()) or tank.assets.owned.seahorse
	var hunger_trigger: float = 0.90 if automated_food else FishProfile.new().hungry_threshold
	var hungry: Array = get_nodes_in_group("fish").filter(func(fish: AquariumFish) -> bool: return not fish.dead and fish.hunger >= hunger_trigger)
	if not hungry.is_empty() and randf() <= float(profile.feed) and get_nodes_in_group("food").size() < mini(hungry.size(), 8):
		var hungriest: AquariumFish = hungry[0]
		for fish in hungry:
			if fish.hunger > hungriest.hunger:
				hungriest = fish
		tank.food_cooldown = 0.0
		if tank.drop_food(hungriest.position + Vector2(0, -12)) != null:
			result.clicks += 1
	if tank.environment.cleanliness <= float(profile.clean_at) and tank.economy.money >= TankEnvironment.FULL_CLEAN_COST:
		tank.purchase_full_clean()
		result.clicks += 1

func try_purchase(tank, strategy: String, elapsed: float, result: Dictionary) -> bool:
	var reserve_cash: float = 20.0 + get_nodes_in_group("fish").size() * 4.0
	if tank.assets.owned.feeder and tank.assets.reserve.size() < 20:
		var refill_cost: int = mini(20, tank.assets.CAPACITY - tank.assets.reserve.size()) * tank.feeds[tank.feed_upgrades.unlocked_tier].price
		if refill_cost > 0 and tank.economy.money >= refill_cost + reserve_cash and tank.assets.restock(tank.feed_upgrades.unlocked_tier, tank.feeds, tank.economy):
			return true
	var order: Array = ["snail", "feeder", "shrimp", "fish5", "seahorse", "puffer"]
	if strategy == "pets":
		order = ["snail", "shrimp", "seahorse", "puffer", "feeder", "fish5"]
	elif strategy == "optimizer":
		order = ["feeder", "snail", "shrimp", "fish6", "coin1", "seahorse", "puffer"]
	for target in order:
		if str(target).begins_with("fish"):
			var target_population: int = int(str(target).trim_prefix("fish"))
			var population: int = get_nodes_in_group("fish").size()
			if population >= target_population:
				continue
			var fish_price: int = Economy.fish_price(population)
			if tank.economy.money >= fish_price + reserve_cash and tank.economy.buy_fish(population):
				tank.spawn_fish(false, "Simulation")
				return true
			return false # Save for the current plan target instead of impulse-buying something cheaper.
		if target == "coin1":
			if int(tank.assets.levels.coin_value) >= 1:
				continue
			var adults_now: int = get_nodes_in_group("fish").filter(func(fish: AquariumFish) -> bool: return fish.growth.stage >= 2).size()
			if adults_now < 4:
				continue
			var planned_coin_price: int = tank.assets.upgrade_price("coin_value")
			if planned_coin_price > 0 and tank.economy.money >= planned_coin_price + reserve_cash:
				tank.purchase_upgrade("coin_value")
				result.coin_upgrade = elapsed
				return true
			return false
		var kind := str(target)
		if tank.assets.owned[kind]:
			continue
		if tank.economy.money >= int(tank.assets.PRICES[kind]) + reserve_cash and tank.assets.purchase(kind, tank.economy):
			tank.spawn_asset(kind)
			result[kind] = elapsed
			return true
		return false
	var living: Array = get_nodes_in_group("fish")
	var adults: int = living.filter(func(fish: AquariumFish) -> bool: return fish.growth.stage >= 2).size()
	if strategy == "optimizer" and adults >= 4:
		var coin_price: int = tank.assets.upgrade_price("coin_value")
		if coin_price > 0 and tank.economy.money >= coin_price + reserve_cash:
			tank.purchase_upgrade("coin_value")
			if float(result.coin_upgrade) < 0.0:
				result.coin_upgrade = elapsed
			return true
	var feed_price: int = tank.feed_upgrades.next_price()
	if feed_price > 0 and tank.economy.money >= feed_price + reserve_cash and tank.feed_upgrades.purchase(tank.economy):
		return true
	var cheapest_track: String = ""
	var cheapest_price: int = 2147483647
	for track in tank.assets.levels:
		if track == "coin_value" and strategy != "optimizer":
			continue
		var price: int = tank.assets.upgrade_price(track)
		if price > 0 and price < cheapest_price:
			cheapest_track = track
			cheapest_price = price
	if not cheapest_track.is_empty() and tank.economy.money >= cheapest_price + reserve_cash:
		tank.purchase_upgrade(cheapest_track)
		if cheapest_track == "coin_value" and float(result.coin_upgrade) < 0.0:
			result.coin_upgrade = elapsed
		return true
	return false

func record_milestones(result: Dictionary, elapsed: float) -> void:
	var highest_stage: int = -1
	for fish in get_nodes_in_group("fish"):
		highest_stage = maxi(highest_stage, fish.growth.stage)
	for milestone in [{"key": "teen", "stage": 1}, {"key": "adult", "stage": 2}, {"key": "royal", "stage": 3}, {"key": "diamond", "stage": 4}]:
		if highest_stage >= milestone.stage and float(result[milestone.key]) < 0.0:
			result[milestone.key] = elapsed

func percentile(values: Array, fraction: float) -> float:
	var valid: Array[float] = []
	for value in values:
		if float(value) >= 0.0:
			valid.append(float(value))
	if valid.is_empty():
		return -1.0
	valid.sort()
	return valid[clampi(roundi((valid.size() - 1) * fraction), 0, valid.size() - 1)]

func time_text(seconds: float) -> String:
	if seconds < 0.0:
		return "never"
	return "%.1fm" % (seconds / 60.0)

func metric_values(results: Array[Dictionary], key: String) -> Array:
	var values: Array = []
	for result in results:
		values.append(result[key])
	return values

func print_profile(name: String, results: Array[Dictionary]) -> void:
	var deaths: int = results.filter(func(result: Dictionary) -> bool: return int(result.deaths) > 0).size()
	var extinctions: int = results.filter(func(result: Dictionary) -> bool: return float(result.extinction) >= 0.0).size()
	print("\nPROFILE: %s (%d runs, %.0f active minutes)" % [name, results.size(), DURATION / 60.0])
	print("  final wallet p10/median/p90: $%.2f / $%.2f / $%.2f" % [percentile(metric_values(results, "wallet"), 0.1), percentile(metric_values(results, "wallet"), 0.5), percentile(metric_values(results, "wallet"), 0.9)])
	print("  final fish p10/median/p90: %.0f / %.0f / %.0f" % [percentile(metric_values(results, "fish"), 0.1), percentile(metric_values(results, "fish"), 0.5), percentile(metric_values(results, "fish"), 0.9)])
	print("  clicks/min p10/median/p90: %.1f / %.1f / %.1f" % [percentile(metric_values(results, "clicks_per_minute"), 0.1), percentile(metric_values(results, "clicks_per_minute"), 0.5), percentile(metric_values(results, "clicks_per_minute"), 0.9)])
	print("  runs with death: %d%%; extinction: %d%%" % [roundi(100.0 * deaths / results.size()), roundi(100.0 * extinctions / results.size())])
	var reason_totals: Dictionary = {}
	for result in results:
		for reason in result.death_reasons:
			reason_totals[reason] = int(reason_totals.get(reason, 0)) + int(result.death_reasons[reason])
	print("  death reasons: %s" % JSON.stringify(reason_totals))
	for key in ["teen", "adult", "royal", "diamond", "snail", "feeder", "shrimp", "seahorse", "puffer", "coin_upgrade"]:
		var values: Array = metric_values(results, key)
		var reached: int = values.filter(func(value) -> bool: return float(value) >= 0.0).size()
		print("  %-12s reached %2d/%d; p10/median/p90 %s / %s / %s" % [key, reached, results.size(), time_text(percentile(values, 0.1)), time_text(percentile(values, 0.5)), time_text(percentile(values, 0.9))])
