extends SceneTree
func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var tank = load("res://scenes/aquarium.tscn").instantiate()
	root.add_child(tank)
	await process_frame
	var fish = get_nodes_in_group("fish")[0]
	fish.set_process(false)
	fish.hunger = 1.0
	fish.survival.starving_for = 44.0
	fish._process(0.5)
	assert(not fish.dead)
	fish._process(0.6)
	assert(fish.dead)
	await create_timer(0.4).timeout
	assert(fish.scale.y < 0)
	tank.invasions.running = true
	tank.invasions.begin_warning()
	assert(tank.invasions.warning_left > 0)
	tank.invasions._process(5.1)
	var alien = tank.invasions.active
	assert(is_instance_valid(alien))
	alien.hit(alien.position - Vector2(10, 0))
	assert(alien.knockback.x > 0)
	var coins: int = get_nodes_in_group("coins").size()
	while not alien.dead:
		alien.hit(alien.position)
	assert(get_nodes_in_group("coins").size() == coins + 1)
	assert(get_nodes_in_group("coins")[-1].value == 10)
	print("PASS: active starvation, belly-up death, opt-in warning, knockback and reduced alien diamond reward")
	quit()
