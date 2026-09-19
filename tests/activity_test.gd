extends SceneTree
var failures: int = 0
func check(ok: bool, description: String) -> void:
	if ok:
		print("PASS: ", description)
	else:
		push_error(description)
		failures += 1
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var tank = load("res://scenes/aquarium.tscn").instantiate()
	root.add_child(tank)
	tank.set_process(false)
	for item in get_nodes_in_group("fish"):
		item.set_process(false)
	var fish = get_nodes_in_group("fish")[0]
	fish.hunger = 0.0
	fish.coin_left = 20.0
	var hunger_step: float = fish.profile.hunger_rate * fish.genome.hunger_multiplier()
	tank.set_idle(false)
	fish._process(1.0)
	check(is_equal_approx(fish.hunger, hunger_step), "active hunger applies the inherited metabolism rate")
	check(is_equal_approx(fish.coin_left, 19.0), "active rewards use normal clock")
	tank._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	fish._process(10.0)
	check(is_equal_approx(fish.hunger, hunger_step * 2.0), "focus loss slows inherited hunger tenfold")
	check(is_equal_approx(fish.coin_left, 18.0), "idle rewards also slow tenfold")
	fish.hunger = 1.0
	fish.survival.starving_for = 0.0
	fish._process(100.0)
	check(not fish.dead and is_equal_approx(fish.survival.starving_for, 10.0), "idle starvation uses same slow clock")
	tank._notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN)
	check(is_equal_approx(fish.survival.starving_for, 10.0), "returning preserves starvation progress")
	fish._process(35.1)
	check(fish.dead, "active starvation resumes immediately on return")
	tank.set_idle(true)
	tank.breeding.check_left = 30.0
	tank.assets.feeder_left = 2.0
	tank._process(10.0)
	check(is_equal_approx(tank.breeding.check_left, 29.0) and is_equal_approx(tank.assets.feeder_left, 1.0), "breeding and feeder share idle clock")
	tank.set_idle(false)
	check(tank.pace_label.text.begins_with("ACTIVE"), "HUD reports active mode")
	print("Activity failures: ", failures)
	quit(1 if failures else 0)
