extends SceneTree
func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	seed(9)
	var tank = load("res://scenes/aquarium.tscn").instantiate()
	root.add_child(tank)
	while get_nodes_in_group("fish").size() < 5:
		tank.spawn_fish()
	tank.breeding.enabled = false # Fixed-population automation test.
	tank.economy.credit(2000)
	for kind in ["snail", "shrimp", "seahorse", "puffer", "feeder"]:
		tank.purchase_asset(kind)
	for i in range(10):
		tank.restock()
	for child in tank.get_children():
		if child is Node2D:
			child.set_process(false)
	tank.set_process(false)
	tank.set_idle(true)
	for tick in range(14400):
		tank._process(0.25)
		for group in ["fish", "food", "coins", "waste", "pets"]:
			for entity in get_nodes_in_group(group):
				entity.set_process(false)
				if not entity.is_queued_for_deletion():
					entity._process(0.25)
		if tick % 100 == 0:
			await process_frame
	assert(get_nodes_in_group("fish").size() == 5, "stocked automated tank survives an hour")
	assert(get_nodes_in_group("food").size() <= 80)
	assert(get_nodes_in_group("coins").size() <= 150)
	assert(get_nodes_in_group("waste").size() <= 100)
	print("PASS: one simulated hour; fish=", get_nodes_in_group("fish").size(), " reserve=", tank.assets.reserve.size(), " coins=", get_nodes_in_group("coins").size(), " wallet=", tank.economy.money)
	quit()
