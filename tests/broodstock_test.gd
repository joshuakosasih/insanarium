extends SceneTree
var failures: int = 0

func check(ok: bool, description: String) -> void:
	if ok:
		print("PASS: ", description)
	else:
		failures += 1
		push_error(description)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var tank = load("res://scenes/aquarium.tscn").instantiate()
	root.add_child(tank)
	tank.set_process(false)
	for fish in get_nodes_in_group("fish"):
		fish.set_process(false)
	var adult: AquariumFish = get_nodes_in_group("fish")[0]
	adult.growth.stage = 2
	adult.hunger = 0.0
	check(not tank.piranha_unlocked and tank.serum_doses == 0, "serum starts locked and empty")
	while get_nodes_in_group("fish").size() < 10:
		var fish: AquariumFish = tank.spawn_fish()
		fish.set_process(false)
	tank.economy.credit(1000)
	var before: float = tank.economy.money
	tank.purchase_serum()
	check(tank.serum_doses == 1 and tank.economy.money == before - FishBroodstock.SERUM_PRICE, "shop purchase adds one serum dose")
	tank.selected_fish = adult
	tank.inject_selected()
	check(adult.broodstock and tank.serum_doses == 0 and adult.brood_left > 0.0, "selected Adult guppy consumes one dose")
	adult.growth.stage = 3
	adult.growth.meals = 74
	adult.growth.growth_credit = 74.0
	var final_pellet: FishFood = tank.spawn_food(adult.position, tank.feeds[0])
	adult.hunger = 0.6
	adult.food_target = final_pellet
	adult._process(0.1)
	check(final_pellet.consumed and adult.growth.stage == 3 and not adult.growth.diamond_trial_done and not adult.wears_crown(), "broodstock stay Royal and skip the Diamond growth roll after eating")
	var diamond_candidate: AquariumFish = get_nodes_in_group("fish")[1]
	diamond_candidate.growth.stage = 4
	check(not FishBroodstock.can_convert(diamond_candidate), "Diamond guppies cannot be converted into broodstock")
	diamond_candidate.growth.stage = 0
	check("waste only" in FishInspector.describe(adult), "inspector shows broodstock output")
	var snap: Dictionary = tank.snapshot()
	check(int(snap.serum_doses) == 0 and bool(snap.fish[0].broodstock), "broodstock state is saved")
	var old_diamond_broodstock: Dictionary = snap.duplicate(true)
	old_diamond_broodstock.fish[0].stage = 4
	check(SaveMigration.upgrade(old_diamond_broodstock).fish[0].stage == 3, "older Diamond broodstock saves normalize to Royal")
	var before_fry: int = get_nodes_in_group("fish").size()
	adult.brood_left = 0.0
	tank.advance_broodstock(0.1)
	var fry: AquariumFish = get_nodes_in_group("fish")[-1]
	fry.set_process(false)
	check(get_nodes_in_group("fish").size() == before_fry + 1 and fry.profile.species_id == "feeder_guppy" and fry.sex == AquariumFish.Sex.ASEXUAL and adult.life.id in fry.life.parent_ids, "one broodstock produces sterile feeder fry alone")
	check(fry.sell_value() == 3 and fry.profile.produces_only_waste and fry.profile.max_growth_stage == 1, "feeder fry have no coin path and low sale value")
	check(fry.profile.growth_sizes[1] == adult.profile.growth_sizes[1] and fry.profile.body_color != adult.profile.body_color, "feeder fry reach normal Teen size with a distinct base color")
	check(FishRevealPanel.capture(adult, "TEST").guppy_role == "broodstock" and FishRevealPanel.capture(fry, "TEST").color == fry.profile.body_color, "fish reveal keeps the flower mark and pale feeder color")
	var breeding := FishBreeding.new()
	breeding.chance = 1.0
	breeding.check_left = 0.0
	adult.breeding_left = 0.0
	for fish in get_nodes_in_group("fish"):
		if fish != adult:
			fish.growth.stage = 0
	breeding.advance(0.1, get_nodes_in_group("fish"))
	check(adult.breeding_left == 0.0, "broodstock cannot also enter ordinary pair breeding")
	adult.brood_left = 0.0
	tank.advance_broodstock(0.1)
	check(FishBroodstock.live_fry_for(adult.life.id, get_nodes_in_group("fish")) == 2, "second feeder fry can be born")
	adult.brood_left = 0.0
	tank.advance_broodstock(0.1)
	check(FishBroodstock.live_fry_for(adult.life.id, get_nodes_in_group("fish")) == 2, "live feeder fry are capped per broodstock")
	var hunter := AquariumFish.new()
	hunter.profile = FishProfile.for_species("piranha")
	hunter.growth.stage = 2
	hunter.hunger = 0.9
	hunter.position = fry.position + Vector2(5, 0)
	hunter.bounds = tank.swim_bounds
	tank.add_child(hunter)
	hunter.set_process(false)
	hunter.hunger = 0.9
	check(FishPredation.eligible(hunter, fry) and FishPredation.nearest(hunter, [fry]) == fry, "Adult piranha hunts feeder fry")
	var saved: Dictionary = tank.snapshot()
	check(not BackupValidation.parse(JSON.stringify(saved)).is_empty(), "backup with broodstock and feeder fry validates")
	var offline_source: Dictionary = saved.duplicate(true)
	offline_source.fish = offline_source.fish.filter(func(item: Dictionary) -> bool: return bool(item.get("broodstock", false)) or str(item.get("species_id", "")) == "piranha")
	for item in offline_source.fish:
		if bool(item.get("broodstock", false)):
			item.brood_left = 0.0
			item.hunger = 0.5
			item.stage = 3
			item.meals = 74
			item.credit = 74.0
			item.diamond_trial_done = false
		else:
			item.hunger = 0.9
		item.coin_left = 1000.0
	offline_source.food = [{"x": 500.0, "y": 640.0, "tier": 0, "life": 14.0, "settled": true}]
	offline_source.asset_levels.idle_duration = 4
	offline_source.saved_at = 1000.0
	var offline_result: Dictionary = OfflineProgress.advance(offline_source, 1100.0)
	check(offline_result.report.brood_fry >= 1 and offline_result.report.preyed >= 1, "away estimate produces feeder fry and lets Adult piranhas eat them")
	check(offline_result.data.fish.any(func(item: Dictionary) -> bool: return bool(item.get("broodstock", false)) and int(item.stage) == 3 and int(item.meals) >= 75 and not bool(item.diamond_trial_done)), "offline meals do not promote broodstock to Diamond")
	var reloaded = load("res://scenes/aquarium.tscn").instantiate()
	root.add_child(reloaded)
	reloaded.set_process(false)
	for fish in reloaded.get_tree().get_nodes_in_group("fish"):
		if fish.get_parent() == reloaded:
			fish.set_process(false)
	reloaded.clear_tank()
	reloaded.restore(saved)
	var restored_brood: int = 0
	var restored_fry: int = 0
	for fish in get_nodes_in_group("fish"):
		if fish.get_parent() != reloaded:
			continue
		if fish.broodstock:
			restored_brood += 1
		if fish.profile.species_id == "feeder_guppy":
			restored_fry += 1
	check(restored_brood == 1 and restored_fry == 2, "save and restore keep broodstock and feeder fry")
	print("Broodstock failures: ", failures)
	quit(1 if failures else 0)
