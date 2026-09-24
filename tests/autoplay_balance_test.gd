extends SceneTree
## Thirty active minutes from a fresh tank, driven entirely by the debug caretaker.
## The printed checkpoint is intended for comparing economy changes over time.

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	seed(20260924)
	var tank = load("res://scenes/aquarium.tscn").instantiate()
	root.add_child(tank)
	tank.set_process(false)
	tank.debug_autoplay = true
	for child in tank.get_children():
		if child is Node2D:
			child.set_process(false)
	for tick in range(7200):
		tank._process(0.25)
		tank.invasions._process(0.25)
		for group in ["fish", "food", "coins", "waste", "pets", "income_bubbles", "invaders"]:
			for entity in get_nodes_in_group(group):
				entity.set_process(false)
				if not entity.is_queued_for_deletion():
					entity._process(0.25)
		if tick % 100 == 0:
			await process_frame
	var stages := [0, 0, 0, 0, 0]
	for fish in get_nodes_in_group("fish"):
		stages[fish.growth.stage] += 1
	assert(tank.economy.money >= 0.0, "autoplay never creates a negative balance")
	assert(not get_nodes_in_group("fish").is_empty(), "autoplay sustains at least one fish")
	assert(get_nodes_in_group("coins").size() <= 150 and get_nodes_in_group("food").size() <= 80, "autoplay respects entity limits")
	print("PASS: autoplay 30m; wallet=", tank.economy.money,
		" fish=", get_nodes_in_group("fish").size(), " stages=", stages,
		" owned=", tank.assets.owned, " levels=", tank.assets.levels,
		" water=", snappedf(tank.environment.cleanliness, 0.1))
	quit()
