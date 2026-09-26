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
	predator.hunger = 0.8
	baby.growth.stage = 1
	var decoy: FishFood = tank.spawn_food(Vector2(590, 350), tank.feeds[0])
	predator._process(0.1)
	check(not baby.dead and predator.food_target == decoy and predator.prey_target == null, "available pellets distract a hungry adult from young guppies")
	decoy.free()
	predator.food_target = null
	predator._process(0.1)
	check(baby.dead and baby.is_queued_for_deletion() and predator.hunger < 0.8 and predator.growth.meals == 2, "hungry adult piranha eats a Teen guppy and gains nutrition")
	var adult: AquariumFish = starters[1]
	adult.growth.stage = 2
	adult.position = predator.position + Vector2(10, 0)
	predator.hunger = 0.8
	predator._process(0.1)
	check(not adult.dead, "adult guppies are too large for piranhas to eat")
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
	var data: Dictionary = tank.snapshot()
	check(data.piranha_unlocked and data.has("guppy_sex_bag") and data.fish.any(func(fish: Dictionary) -> bool: return fish.species_id == "piranha"), "save includes the permanent unlock, marble bag, and piranha species")
	check(not BackupValidation.parse(JSON.stringify(data)).is_empty(), "mixed-species backup validates")
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
	check(away.data.fish.size() == 1 and is_equal_approx(float(away.data.fish[0].hunger), 10.0 / 105.0 * FishGenome.hunger_multiplier_for(metabolism)), "away care uses piranha hunger rate and does not simulate hunting")
	tank.queue_free()
	await process_frame
	var restored = load("res://scenes/aquarium.tscn").instantiate()
	root.add_child(restored)
	for fish in get_nodes_in_group("fish"):
		fish.free()
	restored.restore(data)
	check(restored.piranha_unlocked and restored.guppy_sex_bag.to_data() == data.guppy_sex_bag and get_nodes_in_group("fish").any(func(fish: AquariumFish) -> bool: return fish.profile.species_id == "piranha"), "mixed species and bag state restore without rerolling")
	print("Piranha failures: ", failures)
	quit(1 if failures else 0)
