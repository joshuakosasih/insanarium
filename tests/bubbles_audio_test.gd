extends SceneTree
var failures: int = 0
func check(ok: bool, text: String) -> void:
	if ok:
		print("PASS: ", text)
	else:
		failures += 1
		push_error(text)
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var tank = load("res://scenes/aquarium.tscn").instantiate()
	root.add_child(tank)
	tank.set_process(false)
	check(tank.economy.money == 100 and get_nodes_in_group("fish").size() == 2, "opening has two fish and 100 cash")
	var fish = get_nodes_in_group("fish")[0]
	check(fish.hunger == 0.0 and is_equal_approx(fish.profile.hunger_rate * 120, 1.0) and fish.profile.starvation_grace == 45, "fed opening and relaxed hunger timings")
	var growth := FishGrowth.new()
	for i in range(9):
		growth.record_meal(fish.profile)
	check(growth.stage == 0, "nine basic meals remain baby")
	growth.record_meal(fish.profile)
	check(growth.stage == 1, "ten basic meals become adult")
	for i in range(20):
		growth.record_meal(fish.profile)
	check(growth.stage == 2, "thirty basic meals become royal")
	for i in range(44):
		growth.record_meal(fish.profile, 3)
	check(growth.stage == 2, "upgraded feed cannot bypass diamond meal minimum")
	growth.record_meal(fish.profile)
	check(growth.stage == 3, "seventy-five meals become diamond")
	growth.stage = 2
	growth.meals = 7
	growth.growth_credit = 7
	growth.record_meal(fish.profile)
	check(growth.stage == 2, "existing grown fish never regress with new thresholds")
	var data: Dictionary = tank.snapshot()
	data.fish[0].stage = 2
	data.fish[0].hunger = 1.0
	data.food = [{"tier":0,"life":14,"x":400,"y":300}]
	data.saved_at = 0.0
	check(OfflineProgress.advance(data, 10).data.fish[0].stage == 2, "offline feeding also preserves existing stage")
	for living in get_nodes_in_group("fish"):
		living.free()
	tank.economy.money = 0
	tank.bubble_left = 0.0
	tank._process(0.1)
	check(get_nodes_in_group("income_bubbles").size() == 1, "bubbles spawn even with zero fish and cash")
	var bubble = get_nodes_in_group("income_bubbles")[0]
	check(bubble.position.y >= 615 and IncomeBubble.RADIUS == 11.0, "small bubbles begin near the bottom")
	var value: float = bubble.value
	check(value in [0.5, 1.0, 2.0, 3.0], "bubble rewards include half-dollar rewards")
	tank.handle_tank_click(bubble.position)
	bubble.pop()
	check(tank.economy.money == value and get_nodes_in_group("food").is_empty(), "pop pays once without buying feed underneath")
	var half = tank.spawn_income_bubble()
	half.value = 0.5
	tank.economy.money = 0.0
	half.pop()
	check(tank.economy.money_cents == 50 and tank.money_label.text == "$ 0.50", "fractional reward reaches wallet and HUD exactly")
	check(not tank.economy.spend(1), "half dollar cannot buy a dollar item")
	tank.economy.credit(1.0)
	check(tank.economy.spend(1) and tank.economy.money_cents == 50, "spending preserves fractional remainder")
	var fractional: Dictionary = tank.snapshot()
	fractional.saved_at = 0.0
	check(LocalSave.write(fractional, "/tmp/insanarium-fraction-test.json"), "fractional save writes")
	var roundtrip := LocalSave.read("/tmp/insanarium-fraction-test.json")
	check(roundtrip.money == 0.5 and OfflineProgress.advance(roundtrip, 60).data.money == 0.5, "save and offline catch-up retain cents")
	tank.restore(roundtrip)
	check(tank.economy.money_cents == 50, "restore retains fractional wallet")
	value = tank.economy.money
	var surface = tank.spawn_income_bubble()
	surface.position.y = IncomeBubble.SURFACE_Y + 2.0
	surface._process(0.2)
	surface.pop()
	check(surface.is_queued_for_deletion() and tank.economy.money == value, "surface bubbles disappear without paying")
	surface.free()
	for i in range(5):
		tank.spawn_income_bubble()
	check(get_nodes_in_group("income_bubbles").size() == 3, "bubble count is capped")
	var expired = get_nodes_in_group("income_bubbles")[0]
	expired._process(31.0)
	expired.pop()
	check(tank.economy.money == value, "expired bubbles cannot pay")
	check(not tank.snapshot().has("bubbles"), "bubbles generate no saved or offline income")
	tank.audio.set_muted(true)
	tank.audio.play("bubble")
	check(tank.audio.voices.all(func(v: AudioStreamPlayer) -> bool: return not v.playing), "mute stops all voices and prevents new sound")
	tank.audio.set_muted(false)
	tank.audio.last_played.clear()
	tank.audio.play("bubble")
	check(tank.audio.voices.any(func(v: AudioStreamPlayer) -> bool: return v.playing), "unmuting allows effect playback")
	check(tank.audio.effects.size() == 8 and tank.audio.effects.bubble.data.size() > 0, "all original effects contain PCM audio")
	tank.audio.set_muted(true)
	await create_timer(0.1).timeout
	print("Bubble/audio failures: ", failures)
	quit(1 if failures else 0)
