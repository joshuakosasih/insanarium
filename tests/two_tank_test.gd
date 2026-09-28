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
	for fish in get_nodes_in_group("fish"):
		fish.set_process(false)
	check(tank.active_tank == 1 and not tank.tank2_owned and tank.shop_action_button != null, "existing saves start in Tank 1")
	tank.economy.credit(15000)
	tank.select_shop_item("tank2")
	tank.activate_shop_item()
	check(not tank.tank2_owned, "Tank 2 is locked before the population goal")
	tank.population_goal_complete = true
	tank.select_shop_item("tank2")
	var wallet: float = tank.economy.money
	tank.activate_shop_item()
	check(tank.tank2_owned and tank.economy.money == wallet - 10000 and tank.other_tank.fish.is_empty(), "Tank 2 costs $10,000 and begins empty")
	var guppy: AquariumFish = get_nodes_in_group("fish")[0]
	guppy.broodstock = true
	guppy.brood_boosted = true
	guppy.mutation.variant = 2
	guppy.growth.stage = 2
	guppy.genome.speed = PackedFloat32Array([0.9, 0.8])
	var fish_id: String = guppy.life.id
	tank.selected_fish = guppy
	wallet = tank.economy.money
	tank.move_selected_fish()
	check(tank.other_tank.fish.size() == 1 and tank.other_tank.fish[0].life.id == fish_id and tank.other_tank.fish[0].broodstock and tank.other_tank.fish[0].brood_boosted and tank.other_tank.fish[0].mutation == 2 and tank.economy.money == wallet and tank.fish_transfers_used == 1, "first fish transfer is free and preserves identity, boosted broodstock, and mutation")
	tank.switch_tank(2)
	check(tank.active_tank == 2 and tank.tank_capacity() == 25 and tank.tank_rect.size.x > tank.STARTER_TANK_WIDTH, "Tank 2 has a larger habitat and 25-fish cap")
	check(get_nodes_in_group("fish").size() == 1 and get_nodes_in_group("fish")[0].life.id == fish_id and get_nodes_in_group("fish")[0].brood_boosted and get_nodes_in_group("fish")[0].genome.speed[0] > 0.8, "transferred genome and breeder booster survive scene restoration")
	check(tank.shop_cards.fish.display_title == "Feeder fry" and not tank.shop_cards.serum.visible and tank.shop_cards.piranha.visible, "Tank 2 replaces guppy and serum sales with feeder fry and piranhas")
	wallet = tank.economy.money
	tank.select_shop_item("fish")
	tank.activate_shop_item()
	check(tank.economy.money == wallet - 20 and get_nodes_in_group("fish").any(func(fish: AquariumFish) -> bool: return fish.profile.species_id == "feeder_guppy") and tank.shop_panel.visible == false and tank.acquisition_queue.is_empty(), "Tank 2 sells feeder fry for $20 without a stat-card reveal")
	wallet = tank.economy.money
	tank.select_shop_item("piranha")
	tank.activate_shop_item()
	check(tank.economy.money == wallet - 250 and tank.total_piranhas() == 1, "Tank 2 sells baby piranhas")
	tank.invasions.spawn_now()
	check(is_instance_valid(tank.invasions.active) and tank.invasions.active.threatens_piranhas and tank.invasions.active.health == 16, "Tank 2 spawns the stronger piranha-hunting alien")
	var hunter: TankAlien = tank.invasions.active
	while not hunter.dead:
		hunter.hit(hunter.position)
	check(get_nodes_in_group("coins").any(func(coin: TankCoin) -> bool: return coin.diamond and coin.value == 40), "Tank 2 hunter drops a stronger diamond")
	tank.environment.cleanliness = 64.0
	tank.switch_tank(1)
	check(tank.active_tank == 1 and tank.shop_cards.fish.display_title == "Baby guppy" and tank.shop_cards.serum.visible and tank.total_piranhas() == 1, "Tank 1 keeps its shop and counts piranhas in both tanks")
	check(tank.environment.cleanliness > 90.0 and absf(float(tank.other_tank.cleanliness) - 64.0) < 1.0, "each tank keeps its own water quality")
	check(Economy.piranha_price(tank.total_piranhas()) == 425, "piranha price rises across the portfolio")
	var new_fish: AquariumFish = tank.spawn_fish()
	check(new_fish.life.id != fish_id and tank.other_tank.fish.all(func(fish: Dictionary) -> bool: return fish.life.id != new_fish.life.id), "new fish IDs stay unique across tanks")
	var checkpoint: Dictionary = tank.snapshot()
	check(not BackupValidation.parse(JSON.stringify(checkpoint)).is_empty(), "two-tank save is valid for backup")
	tank.queue_free()
	await process_frame
	var restored = load("res://scenes/aquarium.tscn").instantiate()
	root.add_child(restored)
	restored.set_process(false)
	for fish in get_nodes_in_group("fish"):
		fish.free()
	restored.restore(checkpoint)
	check(restored.tank2_owned and restored.active_tank == 1 and restored.other_tank.fish.size() == 3 and restored.total_piranhas() == 1, "two tanks survive restore")
	restored.switch_tank(2)
	check(restored.active_tank == 2 and get_nodes_in_group("fish").size() == 3, "switching after restore loads Tank 2 inhabitants")
	while get_nodes_in_group("fish").size() < 20:
		restored.spawn_fish()
	restored.birth(Vector2(400, 350))
	check(get_nodes_in_group("fish").size() == 21, "Tank 2 natural births use the 25-fish cap")
	restored.other_tank.asset_levels.idle_duration = 1
	restored.other_tank.saved_at = Time.get_unix_time_from_system() - 100.0
	var previous_elapsed: float = float(restored.other_tank.simulation_elapsed)
	restored.switch_tank(1)
	check(restored.life_registry.elapsed > previous_elapsed + 5.0, "inactive tank receives bounded data-only idle progress on switch")
	restored.fish_transfers_used = 5
	var balance_before_move: float = restored.economy.money
	restored.selected_fish = get_nodes_in_group("fish")[0]
	restored.move_selected_fish()
	check(restored.fish_transfers_used == 6 and restored.economy.money == balance_before_move - 50.0, "transfers after the first five cost $50")
	check(BackupValidation.parse(JSON.stringify(restored.snapshot())).fish_transfers_used == 6, "transfer count persists in validated backups")
	print("Two-tank failures: ", failures)
	quit(1 if failures else 0)
