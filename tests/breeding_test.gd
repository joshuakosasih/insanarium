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
	while get_nodes_in_group("fish").size() < 5:
		tank.spawn_fish()
	tank.set_process(false)
	var fish_list = get_nodes_in_group("fish")
	for fish in fish_list:
		fish.set_process(false)
		fish.sex = AquariumFish.Sex.ASEXUAL
		fish.growth.stage = 1
		fish.hunger = 0.0
	tank.breeding.chance = 1.0
	tank.breeding.advance(30, fish_list)
	check(get_nodes_in_group("fish").size() == 5, "asexual fish do not form breeding pairs")
	var male = fish_list[0]
	var female = fish_list[1]
	male.sex = AquariumFish.Sex.MALE
	female.sex = AquariumFish.Sex.FEMALE
	male.genome.metabolism = PackedFloat32Array([0.2, 0.2])
	male.genome.allocation = PackedFloat32Array([0.3, 0.3])
	male.genome.vitality = PackedFloat32Array([0.25, 0.25])
	male.genome.speed = PackedFloat32Array([0.35, 0.35])
	female.genome.metabolism = PackedFloat32Array([0.8, 0.8])
	female.genome.allocation = PackedFloat32Array([0.7, 0.7])
	female.genome.vitality = PackedFloat32Array([0.75, 0.75])
	female.genome.speed = PackedFloat32Array([0.65, 0.65])
	female.hunger = 1.0
	tank.breeding.advance(30, fish_list)
	check(get_nodes_in_group("fish").size() == 5, "hungry parent cannot breed")
	female.hunger = 0.0
	female.growth.stage = 0
	tank.breeding.advance(30, fish_list)
	check(get_nodes_in_group("fish").size() == 5, "baby cannot breed")
	female.growth.stage = 1
	tank.breeding.enabled = false
	tank.breeding.advance(30, fish_list)
	check(get_nodes_in_group("fish").size() == 5, "breeding toggle prevents births")
	tank.breeding.enabled = true
	var balance: int = tank.economy.money
	tank.breeding.advance(30, fish_list)
	check(get_nodes_in_group("fish").size() == 6 and tank.economy.money == balance, "eligible pair produces one free offspring")
	var child = get_nodes_in_group("fish")[-1]
	check(child.growth.stage == 0 and child.growth.meals == 0 and child.mutation.variant == 0 and child.sex >= 0 and child.sex <= 2, "offspring starts normal baby with valid sex")
	check(absf(child.genome.metabolism[0] - 0.2) <= FishGenome.MUTATION_RANGE + 0.001 and absf(child.genome.metabolism[1] - 0.8) <= FishGenome.MUTATION_RANGE + 0.001 and absf(child.genome.allocation[0] - 0.3) <= FishGenome.MUTATION_RANGE + 0.001 and absf(child.genome.allocation[1] - 0.7) <= FishGenome.MUTATION_RANGE + 0.001 and absf(child.genome.vitality[0] - 0.25) <= FishGenome.MUTATION_RANGE + 0.001 and absf(child.genome.vitality[1] - 0.75) <= FishGenome.MUTATION_RANGE + 0.001 and absf(child.genome.speed[0] - 0.35) <= FishGenome.MUTATION_RANGE + 0.001 and absf(child.genome.speed[1] - 0.65) <= FishGenome.MUTATION_RANGE + 0.001, "offspring inherits one hidden allele per trait from each parent")
	check(is_equal_approx(child.health.maximum, child.genome.max_health()) and child.health.current == child.health.maximum, "new offspring applies inherited vitality at full health")
	check(tank.reveal_panel.visible and tank.reveal_panel.heading_label.text == "NEW OFFSPRING" and "Parents:" in tank.reveal_panel.comparison_label.text, "birth opens a reveal card naming both parents")
	var has_comparison: bool = false
	for bar in tank.reveal_panel.trait_bars:
		has_comparison = has_comparison or bar.comparison in ["↑", "↓", "≈"]
	check(has_comparison, "offspring reveal compares every direct trait with its parents")
	tank.advance_fish_reveal()
	check(male.breeding_left == 300 and female.breeding_left == 300, "both parents get five-minute cooldown")
	tank.breeding.advance(30, get_nodes_in_group("fish"))
	check(get_nodes_in_group("fish").size() == 6, "cooldown prevents repeated births")
	while get_nodes_in_group("fish").size() < 15:
		tank.spawn_fish()
	male.breeding_left = 0
	female.breeding_left = 0
	tank.breeding.advance(30, get_nodes_in_group("fish"))
	check(get_nodes_in_group("fish").size() == 16, "last breeding slot allows one offspring")
	male.breeding_left = 0
	female.breeding_left = 0
	tank.breeding.advance(30, get_nodes_in_group("fish"))
	check(get_nodes_in_group("fish").size() == 16, "breeding stops at soft capacity")
	tank.economy.credit(1000000)
	for i in range(4):
		tank.purchase_fish()
	balance = tank.economy.money
	tank.purchase_fish()
	check(get_nodes_in_group("fish").size() == 20 and tank.economy.money == balance and tank.buy_button.disabled, "hard capacity rejects purchases without charging")
	check(tank.spawn_fish() == null, "direct spawning respects hard cap")
	tank.selected_fish = get_nodes_in_group("fish")[-1]
	tank.sell_selected()
	check(not tank.buy_button.disabled, "selling reopens a purchase slot")
	var data: Dictionary = tank.snapshot()
	check(data.fish[0].sex == male.sex and data.has("breeding_enabled") and data.fish[0].has("breeding_left"), "save contains sex and breeding state")
	tank.queue_free()
	await process_frame
	var restored = load("res://scenes/aquarium.tscn").instantiate()
	root.add_child(restored)
	for fish in get_nodes_in_group("fish"):
		fish.free()
	restored.restore(data)
	check(get_nodes_in_group("fish")[0].sex == data.fish[0].sex and restored.breeding.enabled == data.breeding_enabled, "saved breeding state restores")
	print("Breeding failures: ", failures)
	quit(1 if failures else 0)
