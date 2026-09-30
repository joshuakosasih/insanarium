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
	var bag := FishSexBag.new()
	var draws: Array[int] = []
	for i in range(4):
		draws.append(int(bag.draw()))
	var saved: Array[int] = bag.to_data()
	var restored_bag := FishSexBag.new()
	restored_bag.from_data(saved)
	check(restored_bag.to_data() == saved and saved.size() == 5, "remaining marbles survive a save and reload")
	for i in range(5):
		draws.append(int(restored_bag.draw()))
	check(draws.count(0) == 3 and draws.count(1) == 3 and draws.count(2) == 3 and restored_bag.to_data().is_empty(), "each nine-draw bag contains exactly three of each guppy sex")
	var diamond_bag := FishDiamondBag.new()
	var diamond_results: Array[bool] = []
	for i in range(2):
		diamond_results.append(diamond_bag.draw())
	var saved_diamonds: Array[int] = diamond_bag.to_data()
	var restored_diamonds := FishDiamondBag.new()
	restored_diamonds.from_data(saved_diamonds)
	for i in range(2):
		diamond_results.append(restored_diamonds.draw())
	check(diamond_results.count(true) == 1 and restored_diamonds.to_data().is_empty(), "four eligible guppies produce one Diamond even across a save")
	var growth_bag := FishDiamondBag.new()
	var grown_diamonds: int = 0
	for fish_index in range(4):
		var candidate := FishGrowth.new()
		candidate.diamond_bag = growth_bag
		for meal in range(75):
			candidate.record_meal(FishProfile.new())
		if candidate.stage == 4:
			grown_diamonds += 1
	check(grown_diamonds == 1, "four Diamond growth milestones share one bag outcome")
	var no_diamond := FishProfile.new()
	no_diamond.diamond_growth_chance = 0.0
	var royal_growth := FishGrowth.new()
	for i in range(75):
		royal_growth.record_meal(no_diamond)
	check(royal_growth.stage == 3 and royal_growth.diamond_trial_done, "guppy can remain Royal after its diamond chance")
	no_diamond.diamond_growth_chance = 1.0
	royal_growth.record_meal(no_diamond)
	check(royal_growth.stage == 3, "a failed diamond chance is not retried on later meals")
	var guaranteed_diamond := FishGrowth.new()
	for i in range(75):
		guaranteed_diamond.record_meal(no_diamond)
	check(guaranteed_diamond.stage == 4, "a successful diamond chance advances growth")
	var tank = load("res://scenes/aquarium.tscn").instantiate()
	root.add_child(tank)
	tank.set_process(false)
	var starters: Array = get_nodes_in_group("fish")
	for fish in starters:
		fish.set_process(false)
	check(starters.size() == 2 and starters[0].sex == AquariumFish.Sex.MALE and starters[1].sex == AquariumFish.Sex.FEMALE, "the starter guppies form a breeding pair")
	tank.economy.credit(1000)
	var balance: float = tank.economy.money
	tank.purchase_piranha()
	check(not tank.piranha_unlocked and tank.economy.money == balance and get_nodes_in_group("fish").size() == 2, "piranha purchase is locked before the ten-fish milestone")
	var purchased_sexes: Array[int] = []
	while get_nodes_in_group("fish").size() < 10:
		var guppy: AquariumFish = tank.spawn_fish()
		guppy.set_process(false)
		purchased_sexes.append(int(guppy.sex))
	check(tank.piranha_unlocked and tank.shop_cards.piranha.discovered, "ten fish permanently unlock the Piranha card")
	var ninth_guppy: AquariumFish = tank.spawn_fish()
	ninth_guppy.set_process(false)
	purchased_sexes.append(int(ninth_guppy.sex))
	check(purchased_sexes.count(0) == 3 and purchased_sexes.count(1) == 3 and purchased_sexes.count(2) == 3 and tank.guppy_sex_bag.to_data().is_empty(), "nine actual guppy additions follow the three-three-three marble bag")
	var first_piranha_price: int = Economy.piranha_price(0)
	balance = tank.economy.money
	tank.purchase_piranha()
	var predator: AquariumFish = get_nodes_in_group("fish")[-1]
	predator.set_process(false)
	check(predator.profile.species_id == "piranha" and predator.growth.stage == 0 and tank.economy.money == balance - first_piranha_price and Economy.piranha_price(1) > first_piranha_price, "the shop buys a baby piranha at a species price that rises")
	check(predator.profile.body_color != starters[0].profile.body_color and tank.acquisition_celebration.icon_kind == "piranha", "piranha has its own vector appearance and reveal")
	check(predator.profile.growth_sizes[2] > starters[0].profile.growth_sizes[2] and predator.swim_speed() > 0.0, "adult piranha is larger than an adult guppy")
	predator.hunger = 0.8
	predator.position = Vector2(500, 350)
	var baby: AquariumFish = starters[0]
	baby.position = Vector2(513, 350)
	for fish in get_nodes_in_group("fish"):
		if fish != predator and fish != baby:
			fish.position = Vector2(850, 520)
	predator._process(0.1)
	check(not baby.dead and predator.growth.meals == 0, "baby piranhas cannot hunt guppies")
	var pellet: FishFood = tank.spawn_food(Vector2(520, 350), tank.feeds[0])
	predator.hunger = 0.8
	predator._process(0.1)
	check(pellet.consumed and not baby.dead and predator.growth.meals == 1, "baby piranhas grow by eating ordinary pellets")
	predator.growth.stage = 2
	predator.hunger = 0.9
	baby.growth.stage = 1
	var decoy: FishFood = tank.spawn_food(Vector2(590, 350), tank.feeds[0])
	predator._process(0.1)
	check(baby.dead and not decoy.consumed and predator.food_target == null and predator.growth.meals == 2, "adult piranha ignores pellets and hunts a young guppy")
	decoy.free()
	check(baby.is_queued_for_deletion() and predator.hunger < 0.9, "hunting feeds the adult piranha")
	check(predator.profile.reward_grade(1) == 3 and not predator.profile.reward_is_diamond(1) and predator.profile.reward_is_diamond(2) and predator.profile.growth_rewards[2] * predator.profile.coin_value > FishProfile.new().growth_rewards[4], "teen piranhas make gold and adults make a stronger diamond")
	var adult: AquariumFish = starters[1]
	adult.growth.stage = 2
	adult.position = predator.position + Vector2(10, 0)
	predator.hunger = 0.8
	predator._process(0.1)
	check(not adult.dead, "adult guppies are too large for piranhas to eat")
	predator.growth.stage = 1
	check(not predator.can_fight_alien(), "Teen piranhas cannot defend against aliens")
	predator.growth.stage = 2
	check(predator.can_fight_alien(), "Adult piranhas can defend against aliens")
	var defending_alien := TankAlien.new()
	defending_alien.bounds = tank.swim_bounds
	tank.add_child(defending_alien)
	defending_alien.set_process(false)
	defending_alien.position = predator.position
	var alien_health: int = defending_alien.health
	defending_alien._process(0.1)
	check(not predator.dead and adult.dead and defending_alien.health == alien_health, "alien ignores an Adult piranha and attacks a vulnerable guppy")
	predator.alien_attack_left = 0.0
	predator._process(0.1)
	check(defending_alien.health == alien_health - 1 and predator.position.distance_to(defending_alien.position) > 0.0 and is_equal_approx(predator.alien_attack_left, predator.alien_bite_interval()), "Adult piranha bites from outside the alien center with an Agility-based cooldown")
	predator.growth.stage = 4
	predator.alien_attack_left = 0.0
	predator.attack_alien(defending_alien)
	check(is_equal_approx(predator.alien_attack_left, predator.alien_bite_interval()) and predator.alien_attack_left > 0.0, "older piranhas bite aliens faster")
	while not defending_alien.dead:
		predator.alien_attack_left = 0.0
		predator.attack_alien(defending_alien)
	check(defending_alien.dead, "repeated piranha bites can defeat an alien")
	defending_alien.free()
	var neutral_metabolism: float = FishGenome.hunger_multiplier_for(0.5)
	var prey_interval: float = predator.profile.prey_nutrition / (predator.profile.hunger_rate_at(2) * neutral_metabolism)
	check(prey_interval > 220.0 and prey_interval < 260.0 and predator.profile.hunger_rate_at(1) > predator.profile.hunger_rate_at(2), "Adult piranhas need roughly one prey every four minutes while juveniles grow at normal feeding pace")
	predator.hunger = 1.0
	check("prey" in FishInspector.trait_rows(predator)[1].value and "PIRANHA NEEDS PREY" in TankCare.warnings([predator], 0, false), "Adult piranha care and traits clearly show its prey-only diet")
	var mixed := FishBreeding.new()
	mixed.chance = 1.0
	var births := {"count": 0}
	mixed.offspring_requested.connect(func(_at: Vector2, _father: String, _mother: String) -> void: births.count += 1)
	predator.sex = AquariumFish.Sex.MALE
	adult.sex = AquariumFish.Sex.FEMALE
	adult.hunger = 0.0
	predator.hunger = 0.0
	mixed.advance(30.0, [predator, adult])
	check(births.count == 0, "piranhas and guppies never crossbreed")
	var piranha_mother: AquariumFish = tank.spawn_fish(false, "Test", "piranha")
	piranha_mother.set_process(false)
	piranha_mother.sex = AquariumFish.Sex.FEMALE
	piranha_mother.growth.stage = 2
	piranha_mother.hunger = 0.0
	mixed.advance(30.0, [predator, piranha_mother])
	check(births.count == 1, "two eligible piranhas can form a same-species pair")
	tank.birth(Vector2(500, 350), predator.life.id, piranha_mother.life.id)
	var offspring: AquariumFish = get_nodes_in_group("fish")[-1]
	check(offspring.profile.species_id == "piranha" and offspring.growth.stage == 0 and offspring.life.parent_ids == PackedStringArray([predator.life.id, piranha_mother.life.id]), "piranha offspring inherits its species and parent identities")
	tank.guppy_diamond_bag.draw()
	var data: Dictionary = tank.snapshot()
	check(data.piranha_unlocked and data.has("guppy_sex_bag") and data.has("guppy_diamond_bag") and data.fish.any(func(fish: Dictionary) -> bool: return fish.species_id == "piranha") and data.fish.all(func(fish: Dictionary) -> bool: return fish.has("diamond_trial_done")), "save includes species and growth-roll state")
	check(not BackupValidation.parse(JSON.stringify(data)).is_empty(), "mixed-species backup validates")
	var impossible_bag: Dictionary = data.duplicate(true)
	impossible_bag.guppy_diamond_bag = [1, 1]
	check(BackupValidation.parse(JSON.stringify(impossible_bag)).is_empty(), "backup rejects impossible Diamond bag contents")
	var diamond_away: Dictionary = data.duplicate(true)
	diamond_away.fish = data.fish.filter(func(fish: Dictionary) -> bool: return fish.species_id == "starter_fish").slice(0, 4)
	for fish in diamond_away.fish:
		fish.stage = 3
		fish.meals = 74
		fish.credit = 75.0
		fish.hunger = 0.9
		fish.starving = 0.0
		fish.coin_left = 100.0
		fish.diamond_trial_done = false
	diamond_away.guppy_diamond_bag = []
	diamond_away.food = [{"tier": 0, "life": 14.0, "x": 550, "y": 350}, {"tier": 0, "life": 14.0, "x": 550, "y": 350}, {"tier": 0, "life": 14.0, "x": 550, "y": 350}, {"tier": 0, "life": 14.0, "x": 550, "y": 350}]
	diamond_away.saved_at = 0.0
	diamond_away.asset_levels.idle_duration = 4
	var diamond_result: Dictionary = OfflineProgress.advance(diamond_away, 10.0)
	check(diamond_result.data.fish.filter(func(fish: Dictionary) -> bool: return int(fish.stage) == 4).size() == 1 and diamond_result.data.guppy_diamond_bag.is_empty(), "offline growth uses the same one-in-four Diamond bag")
	var just_piranha: Dictionary = data.duplicate(true)
	just_piranha.fish = data.fish.filter(func(fish: Dictionary) -> bool: return fish.species_id == "piranha").slice(0, 1)
	just_piranha.fish[0].hunger = 0.0
	just_piranha.fish[0].stage = 0
	just_piranha.fish[0].coin_left = 100.0
	just_piranha.food = []
	just_piranha.reserve = []
	just_piranha.saved_at = 0.0
	just_piranha.asset_levels.idle_duration = 4
	var away: Dictionary = OfflineProgress.advance(just_piranha, 100.0)
	var metabolism: float = FishGenome.phenotype_from_data(just_piranha.fish[0].genome, "metabolism")
	check(away.data.fish.size() == 1 and is_equal_approx(float(away.data.fish[0].hunger), 10.0 / 120.0 * FishGenome.hunger_multiplier_for(metabolism)), "juvenile piranhas keep a normal feeding pace while away")
	just_piranha.fish[0].stage = 2
	just_piranha.fish[0].hunger = 0.75
	just_piranha.food = [{"tier": 0, "life": 14.0, "x": 550, "y": 350}]
	away = OfflineProgress.advance(just_piranha, 100.0)
	check(away.report.fed == 0 and away.data.fish.size() == 1 and away.data.fish[0].hunger > 0.75, "adult piranha does not consume pellets during away calculation")
	tank.queue_free()
	await process_frame
	var restored = load("res://scenes/aquarium.tscn").instantiate()
	root.add_child(restored)
	for fish in get_nodes_in_group("fish"):
		fish.free()
	restored.restore(data)
	check(restored.piranha_unlocked and restored.guppy_sex_bag.to_data() == data.guppy_sex_bag and restored.guppy_diamond_bag.to_data() == data.guppy_diamond_bag and get_nodes_in_group("fish").any(func(fish: AquariumFish) -> bool: return fish.profile.species_id == "piranha"), "mixed species and bag state restore without rerolling")
	print("Piranha failures: ", failures)
	quit(1 if failures else 0)
