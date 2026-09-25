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
	assert(tank.invasions.running, "alien encounters default to active")
	tank.invasions.begin_warning()
	assert(tank.invasions.warning_left > 0 and tank.audio.danger_music)
	tank.invasions._process(5.1)
	var alien = tank.invasions.active
	assert(is_instance_valid(alien))
	var food_before: int = get_nodes_in_group("food").size()
	var health_before: int = alien.health
	tank.handle_tank_click(alien.position + Vector2(0, -58) * alien.scale)
	assert(alien.health == health_before - 1 and get_nodes_in_group("food").size() == food_before, "clicking any visible alien part attacks without dropping food")
	alien.hit(alien.position - Vector2(10, 0))
	assert(alien.knockback.x > 0)
	var coins: int = get_nodes_in_group("coins").size()
	while not alien.dead:
		alien.hit(alien.position)
	assert(get_nodes_in_group("coins").size() == coins + 1)
	assert(get_nodes_in_group("coins")[-1].value == 20)
	assert(not tank.audio.danger_music)
	tank.set_challenges_enabled(false)
	assert(not tank.invasions.running)
	tank.set_challenges_enabled(true)
	assert(tank.invasions.running and tank.invasions.wait_left >= 90.0, "challenge control can opt out and restart the active-play schedule")
	print("PASS: starvation, default encounters, click consumption, knockback, alien reward and music restoration")
	quit()
