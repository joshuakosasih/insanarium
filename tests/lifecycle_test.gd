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
	var parents = get_nodes_in_group("fish")
	var seen: Dictionary = {}
	for fish in parents:
		fish.set_process(false)
		seen[fish.life.id] = true
		fish.sex = AquariumFish.Sex.ASEXUAL
	check(seen.size() == 5 and not seen.has(""), "starting fish have distinct nonempty IDs")
	var father = parents[0]
	var mother = parents[1]
	father.sex = AquariumFish.Sex.MALE
	mother.sex = AquariumFish.Sex.FEMALE
	for fish in [father, mother]:
		fish.growth.stage = 2
		fish.hunger = 0.0
	tank.breeding.chance = 1.0
	tank.breeding.advance(30, parents)
	var child = get_nodes_in_group("fish")[-1]
	child.set_process(false)
	var parent_ids := PackedStringArray([father.life.id, mother.life.id])
	check(child.life.parent_ids == parent_ids and child.life.origin == "Born in tank", "birth records actual selected parents")
	check(child.life.age_seconds == 0 and child.life.age_known, "newborn age starts at zero")
	child._process(1.0)
	tank.set_idle(true)
	child._process(10.0)
	check(is_equal_approx(child.life.age_seconds, 2.0), "age follows active and idle simulation time")
	tank.set_idle(false)
	tank.selected_fish = father
	tank.sell_selected()
	mother.die("Test")
	check(child.life.parent_ids == parent_ids, "ancestry survives parent sale and death")
	var data: Dictionary = tank.snapshot()
	check(data.version == 3 and data.next_fish_id > get_nodes_in_group("fish").size(), "save persists non-reusable ID sequence")
	check(LocalSave.write(data, "/tmp/insanarium-life-test.json"), "version three writes successfully")
	var child_id: String = child.life.id
	var age: float = child.life.age_seconds
	var genome_data: Dictionary = child.genome.to_data()
	tank.queue_free()
	await process_frame
	var restored = load("res://scenes/aquarium.tscn").instantiate()
	root.add_child(restored)
	restored.set_process(false)
	for fish in get_nodes_in_group("fish"):
		fish.free()
	restored.restore(LocalSave.read("/tmp/insanarium-life-test.json"))
	var found: AquariumFish
	for fish in get_nodes_in_group("fish"):
		if fish.life.id == child_id:
			found = fish
	check(found != null and found.life.parent_ids == parent_ids and is_equal_approx(found.life.age_seconds, age) and found.genome.to_data() == genome_data, "child identity ancestry age and genome survive JSON round-trip")
	var neutral_genome := FishGenome.new()
	var neutral_lifespan: float = FishAging.lifespan_for(neutral_genome)
	var fast_genome := FishGenome.new()
	fast_genome.metabolism = PackedFloat32Array([1.0, 1.0])
	fast_genome.allocation = PackedFloat32Array([1.0, 1.0])
	check(FishAging.lifespan_for(fast_genome) < neutral_lifespan and FishAging.phase(neutral_lifespan * 0.85, neutral_lifespan) == "Senior", "fast productive fish age sooner and late life is identified as senior")
	var elder = restored.spawn_fish()
	elder.life.age_seconds = FishAging.lifespan_for(elder.genome) - 0.1
	elder._process(0.2)
	check(elder.dead, "fish eventually die from old age during active simulation")
	var purchased = restored.spawn_fish()
	check(not seen.has(purchased.life.id) and purchased.life.id != child_id, "new purchases never reuse dead or sold IDs")
	var legacy := {"version": 1, "money": 77, "fish": [{"stage": 2, "meals": 9}]}
	var migrated: Dictionary = SaveMigration.upgrade(legacy)
	check(migrated.version == 3 and migrated.money == 77 and migrated.fish[0].stage == 3, "legacy migration preserves equivalent economy and maturity")
	check(not migrated.fish[0].life.age_known and migrated.fish[0].life.parents.is_empty(), "legacy ages and parents stay explicitly unknown")
	var repeated: Dictionary = SaveMigration.upgrade(migrated)
	check(repeated.fish[0].life.id == migrated.fish[0].life.id, "migration is idempotent")
	restored.selected_fish = found
	restored.update_inspection()
	check(restored.inspector_detail.text.contains(child_id) and restored.inspector_detail.text.contains(parent_ids[0]), "inspector exposes individual and parent IDs")
	var end_age: float = found.life.age_seconds
	found.die("Test")
	found._process(10)
	check(found.life.age_seconds == end_age, "dead fish no longer age")
	print("Lifecycle failures: ", failures)
	quit(1 if failures else 0)
