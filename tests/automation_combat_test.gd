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
	tank.economy.credit(100000)
	var catalog_ids: Array[String] = []
	for item in ShopItemDefinition.catalog():
		catalog_ids.append(item.id)
	check(catalog_ids.slice(0, 4) == ["fish", "feed", "bubbles", "idle_duration"] and catalog_ids.find("piranha") > catalog_ids.find("diamond_value") and catalog_ids[-1] == "serum", "shop starts with everyday progression and places predators later")
	check(not tank.shop_cards.has("stock"), "pellet stock is no longer a separate shop card")
	tank.select_shop_item("feeder")
	tank.activate_shop_item()
	check(tank.assets.owned.feeder and tank.shop_secondary_button.visible and tank.assets.capacity() == 50, "owned feeder starts with a 50-pellet reserve")
	tank.activate_shop_item()
	check(tank.assets.capacity() == 100 and int(tank.assets.levels.feeder_capacity) == 1, "first feeder upgrade expands reserve to 100")
	tank.activate_shop_secondary()
	check(tank.assets.reserve.size() == 20 and tank.shop_secondary_button.text.contains("20"), "same feeder card buys stock")
	for level in range(2):
		tank.activate_shop_item()
	check(tank.assets.capacity() == 200 and tank.assets.upgrade_price("feeder_capacity") == 0, "feeder capacity tops out at 200")
	tank.assets.reserve.resize(200)
	var save: Dictionary = tank.snapshot()
	check(not BackupValidation.parse(JSON.stringify(save)).is_empty() and SaveMigration.upgrade(save).asset_levels.feeder_capacity == 3, "expanded feeder stock and level survive backup validation")
	var older_save: Dictionary = save.duplicate(true)
	older_save.asset_levels.feeder_capacity = 4
	older_save.reserve.resize(250)
	var upgraded_save: Dictionary = SaveMigration.upgrade(older_save)
	check(not BackupValidation.parse(JSON.stringify(older_save)).is_empty() and upgraded_save.asset_levels.feeder_capacity == 3 and upgraded_save.reserve.size() == 250, "old paid pellets remain available above the new capacity")
	tank.assets.reserve.resize(250)
	tank.refresh_shop()
	check(tank.shop_secondary_button.disabled and tank.shop_secondary_button.text == "Stock full", "legacy overstock cannot buy more pellets until it is used")
	var hungry: AquariumFish = get_nodes_in_group("fish")[0]
	hungry.position = Vector2(500, 480)
	var pellet: FishFood = tank.spawn_feeder_food(hungry, 0)
	pellet.set_process(false)
	var fall_time: float = (pellet.floor_y - pellet.position.y) / FishFood.FALL_SPEED
	check(is_equal_approx(pellet.position.x, hungry.position.x) and pellet.position.y < hungry.position.y and pellet.lifetime > fall_time + 13.9, "auto-feeder drops above fish with enough time to reach the floor")
	pellet._process(fall_time)
	check(is_equal_approx(pellet.position.y, pellet.floor_y) and pellet.lifetime >= 13.9 and not pellet.is_queued_for_deletion(), "feeder pellet reaches the floor with its full shelf life")
	var seahorse := IdleAssets.new()
	seahorse.owned.seahorse = true
	for level in range(8):
		check(seahorse.upgrade_price("seahorse_interval") > 0, "Seahorse rate has upgrade %d" % (level + 1))
		seahorse.levels.seahorse_interval = level + 1
	check(seahorse.seahorse_interval() == 1.0 and seahorse.upgrade_price("seahorse_interval") == 0, "maximum Seahorse rate is one pellet per second")
	var charged := SeahorsePet.new()
	tank.add_child(charged)
	charged.set_process(false)
	charged.apply_upgrades(8, 0)
	check(charged.feed_interval == 1.0, "live Seahorse accepts the extended rate track")
	var shrimp := IdleAssets.new()
	shrimp.owned.shrimp = true
	shrimp.levels.shrimp_digestion = shrimp.track_max_level("shrimp_digestion")
	check(is_equal_approx(shrimp.shrimp_digestion(), 0.5), "maximum shrimp digestion takes half a second")
	var prey: AquariumFish = hungry
	prey.growth.stage = 0
	prey.position = Vector2(480, 360)
	var other: AquariumFish = get_nodes_in_group("fish")[1]
	other.position = Vector2(800, 500)
	var predator: AquariumFish = tank.spawn_fish(false, "Test", "piranha")
	predator.set_process(false)
	predator.growth.stage = 2
	predator.position = Vector2(485, 360)
	predator.hunger = 0.8
	predator._process(0.1)
	var effects: Array = tank.get_children().filter(func(node: Node) -> bool: return node is BiteBurst)
	check(prey.dead and effects.size() == 1, "piranha catch creates one short bite burst")
	var before: float = tank.economy.money
	tank.debug_controls.money_requested.emit()
	check(tank.economy.money == before + 10000.0, "ADMIN button credits $10,000")
	tank.debug_controls.invasion_requested.emit()
	check(is_instance_valid(tank.invasions.active) and tank.invasions.warning_left == 0.0, "ADMIN button spawns an alien immediately")
	tank.clear_tank()
	tank.restore(upgraded_save)
	check(tank.assets.capacity() == 200 and tank.assets.reserve.size() == 250 and not tank.assets.restock(0, tank.feeds, tank.economy), "restoring an old save keeps paid overstock and blocks new refills")
	print("Automation and combat failures: ", failures)
	quit(1 if failures else 0)
