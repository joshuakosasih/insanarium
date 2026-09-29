extends SceneTree
var failures: int = 0

func check(ok: bool, description: String) -> void:
	if not ok:
		failures += 1
		push_error(description)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var tank = load("res://scenes/aquarium.tscn").instantiate()
	root.add_child(tank)
	tank.set_process(false)
	var parent: AquariumFish = get_nodes_in_group("fish")[0]
	parent.set_process(false)
	parent.growth.stage = 2
	parent.hunger = 0.0
	tank.piranha_unlocked = true
	tank.population_goal_complete = true
	tank.economy.credit(15000)
	tank.purchase_serum()
	tank.selected_fish = parent
	tank.inject_selected()
	check(parent.broodstock and not parent.brood_boosted, "Tank 1 serum creates an ordinary broodstock guppy")
	var parent_id: String = parent.life.id
	tank.purchase_second_tank()
	var wallet: float = tank.economy.money
	tank.purchase_booster_serum()
	check(tank.booster_doses == 0 and tank.economy.money == wallet, "booster cannot be bought in Tank 1")
	tank.selected_fish = parent
	tank.move_selected_fish()
	tank.switch_tank(2)
	parent = get_nodes_in_group("fish")[0]
	check(parent.life.id == parent_id and tank.shop_cards.serum.visible and tank.shop_cards.serum.display_title == "Breeder booster", "Tank 2 shows booster serum for transferred broodstock")
	tank.select_shop_item("serum")
	tank.activate_shop_item()
	check(tank.booster_doses == 1 and tank.economy.money == wallet - FishBroodstock.BOOSTER_PRICE, "Tank 2 shop sells one booster dose")
	var fresh: AquariumFish = tank.spawn_fish(false, "Test", "starter_fish")
	fresh.set_process(false)
	tank.selected_fish = fresh
	tank.inject_selected()
	check(not fresh.broodstock and not fresh.brood_boosted and tank.booster_doses == 1, "booster cannot convert a fresh fish")
	tank.selected_fish = parent
	tank.inject_selected()
	check(parent.brood_boosted and tank.booster_doses == 0 and FishBroodstock.interval_for(parent.genome.fertility_value(), true) < FishBroodstock.interval_for(parent.genome.fertility_value()), "booster upgrades only existing broodstock")
	var adult_piranha := FishProfile.for_species("piranha")
	var neutral_prey_interval: float = adult_piranha.prey_nutrition / (adult_piranha.hunger_rate_at(2) * FishGenome.hunger_multiplier_for(0.5))
	var low_support: float = neutral_prey_interval / FishBroodstock.interval_for(0.0, true)
	var high_support: float = neutral_prey_interval / FishBroodstock.interval_for(1.0, true)
	check(absf(low_support - 1.0) < 0.05 and absf(high_support - 3.5) < 0.1, "boosted breeder Fertility spans about one to 3.5 neutral Adult piranhas")
	check(FishBroodstock.interval_for(0.5, true) < 136.5, "midrange breeders improve rather than slowing under the wider Fertility curve")
	for i in range(5):
		parent.brood_left = 0.0
		tank.advance_broodstock(0.1)
	check(FishBroodstock.live_fry_for(parent_id, get_nodes_in_group("fish")) == 4, "boosted breeder supports four live fry, then stops")
	var saved: Dictionary = tank.snapshot()
	check(not BackupValidation.parse(JSON.stringify(saved)).is_empty(), "booster state validates in a two-tank backup")
	var long_clock: Dictionary = saved.duplicate(true)
	for fish in long_clock.fish:
		if bool(fish.get("broodstock", false)):
			fish.brood_left = FishBroodstock.MAX_INTERVAL
	check(not BackupValidation.parse(JSON.stringify(long_clock)).is_empty() and SaveMigration.upgrade(long_clock).fish.any(func(fish: Dictionary) -> bool: return bool(fish.get("broodstock", false)) and is_equal_approx(float(fish.brood_left), FishBroodstock.MAX_INTERVAL)), "longer low-Fertility breeder clocks survive save validation and migration")
	var old_stock: Dictionary = saved.duplicate(true)
	old_stock.booster_doses = 2
	old_stock.other_tank.booster_doses = 1
	tank.queue_free()
	await process_frame
	var restored = load("res://scenes/aquarium.tscn").instantiate()
	root.add_child(restored)
	restored.set_process(false)
	restored.restore(old_stock)
	check(restored.booster_doses == 3 and not restored.other_tank.has("booster_doses"), "older booster stock is preserved as shared inventory")
	check(get_nodes_in_group("fish").any(func(fish: AquariumFish) -> bool: return fish.brood_boosted and fish.life.id == parent_id), "boosted breeder survives save and restore")
	print("Breeder booster failures: ", failures)
	quit(1 if failures else 0)
