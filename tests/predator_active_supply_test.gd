extends SceneTree
## Exercise real swimming and hunting with regular food restocks and clean water.
var failures: int = 0

func check(ok: bool, description: String) -> void:
	if not ok:
		failures += 1
		push_error(description)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	seed(27182)
	var tank = load("res://scenes/aquarium.tscn").instantiate()
	root.add_child(tank)
	tank.set_process(false)
	tank.persistence = false
	tank.active_tank = 2
	tank.update_viewport_layout()
	tank.breeding.capacity = 25
	tank.breeding.chance = 0.0
	tank.invasions.running = false
	tank.bubble_left = INF
	for fish in get_nodes_in_group("fish"):
		fish.remove_from_group("fish")
		fish.free()
	tank.assets.owned.feeder = true
	tank.assets.owned.sponge = true
	tank.assets.levels.sponge_breath = 4
	tank.assets.levels.feeder_capacity = 3
	tank.assets.feeder_left = 0.0
	tank.assets.reserve.clear()
	for i in range(tank.assets.capacity()):
		tank.assets.reserve.append(0)
	for i in range(3):
		var breeder: AquariumFish = tank.spawn_fish(false, "Test breeder")
		breeder.set_process(false)
		breeder.broodstock = true
		breeder.brood_boosted = true
		breeder.brood_left = i * 22.0
		breeder.genome.fertility = PackedFloat32Array([1.0, 1.0])
		breeder.growth.stage = 2
		breeder.hunger = 0.1
	for i in range(8):
		var predator: AquariumFish = tank.spawn_fish(false, "Test predator", "piranha")
		predator.set_process(false)
		predator.growth.stage = 2
		predator.hunger = 0.1 + i * 0.04
		predator.sex = AquariumFish.Sex.MALE
	for tick in range(3600):
		tank._process(1.0)
		for fish in get_nodes_in_group("fish"):
			if not fish.dead and not fish.is_queued_for_deletion():
				fish._process(1.0)
		for food in get_nodes_in_group("food"):
			if not food.is_queued_for_deletion():
				food._process(1.0)
		for waste in get_nodes_in_group("waste"):
			if not waste.is_queued_for_deletion():
				waste._process(1.0)
		for coin in get_nodes_in_group("coins"):
			if not coin.is_queued_for_deletion():
				coin._process(1.0)
		if tick % 60 == 0:
			tank.environment.full_clean()
			while tank.assets.reserve.size() < tank.assets.capacity():
				tank.assets.reserve.append(0)
		if tick % 100 == 0:
			await process_frame
	var surviving_predators: int = get_nodes_in_group("fish").filter(func(fish: AquariumFish) -> bool: return fish.profile.species_id == "piranha").size()
	check(surviving_predators == 8, "three max-Fertility boosted breeders sustain eight swimming Adult piranhas for one active hour with proper care")
	print("Active predator supply failures: ", failures)
	quit(1 if failures else 0)
