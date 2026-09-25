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
	var slow := FishGenome.new()
	slow.metabolism = PackedFloat32Array([0.0, 0.0])
	slow.allocation = PackedFloat32Array([0.0, 0.0])
	slow.vitality = PackedFloat32Array([0.0, 0.0])
	slow.speed = PackedFloat32Array([0.0, 0.0])
	var fast := FishGenome.new()
	fast.metabolism = PackedFloat32Array([1.0, 1.0])
	fast.allocation = PackedFloat32Array([1.0, 1.0])
	fast.vitality = PackedFloat32Array([1.0, 1.0])
	fast.speed = PackedFloat32Array([1.0, 1.0])
	check(fast.speed_multiplier() > slow.speed_multiplier() and fast.max_health() > slow.max_health(), "speed and vitality directly increase swimming and maximum health")
	check(fast.hunger_multiplier() > slow.hunger_multiplier(), "fast metabolism reduces visible food endurance")
	check(fast.growth_multiplier() > slow.growth_multiplier() and fast.output_interval(20.0) < slow.output_interval(20.0), "fast metabolism accelerates growth and output")
	check(fast.coin_chance() > slow.coin_chance() and fast.constitution() > slow.constitution(), "productivity favors coins while vitality independently improves resilience")
	check(fast.breeding_cooldown() < slow.breeding_cooldown(), "fast metabolism shortens the natural breeding cooldown")
	check(FishAging.lifespan_for(fast) > FishAging.lifespan_for(slow), "extreme vitality can outweigh the longevity cost of fast metabolism")
	var encoded: Dictionary = fast.to_data()
	var decoded := FishGenome.new()
	decoded.from_data(encoded)
	check(decoded.metabolism == fast.metabolism and decoded.allocation == fast.allocation and decoded.vitality == fast.vitality and decoded.speed == fast.speed, "four-trait genome data round-trips exactly")
	var legacy_genome := FishGenome.new()
	legacy_genome.from_data({"metabolism": [0.2, 0.8], "allocation": [0.4, 0.6]})
	check(legacy_genome.vitality == PackedFloat32Array([0.5, 0.5]) and legacy_genome.speed == PackedFloat32Array([0.5, 0.5]), "older fish receive neutral vitality and speed")
	var profile := FishProfile.new()
	var slow_growth := FishGrowth.new()
	var fast_growth := FishGrowth.new()
	for i in range(9):
		slow_growth.record_meal(profile, 1, slow.growth_multiplier())
		fast_growth.record_meal(profile, 1, fast.growth_multiplier())
	check(slow_growth.stage == 1 and fast_growth.stage == 2, "metabolism changes growth pace while preserving meal requirements")
	var fish := AquariumFish.new()
	fish.profile = profile
	fish.bounds = Rect2(0, 0, 100, 100)
	fish.genome = fast
	root.add_child(fish)
	var description := FishInspector.describe(fish)
	var rows := FishInspector.trait_rows(fish)
	check(description.contains("Natural breed cycle") and rows.size() == 4 and rows[0].title == "Vitality" and rows[1].title == "Metabolism" and rows[2].title == "Agility" and rows[3].title == "Productivity", "inspector consolidates genetics into four readable gameplay traits")
	check(not fish.wears_crown(), "non-Diamond fish do not wear a crown")
	fish.growth.stage = fish.profile.diamond_stage
	check(fish.wears_crown() and FishRevealPanel.capture(fish, "TEST").crowned, "Diamond fish wear their crown in the tank and reveal card")
	print("Genetics failures: ", failures)
	quit(1 if failures else 0)
