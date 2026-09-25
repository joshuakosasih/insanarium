extends SceneTree
var failures: int = 0
func check(ok: bool, message: String) -> void:
	if ok:
		print("PASS: ", message)
	else:
		failures += 1
		push_error(message)
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var tank = load("res://scenes/aquarium.tscn").instantiate()
	root.add_child(tank)
	while get_nodes_in_group("fish").size() < 20:
		tank.spawn_fish()
	tank.set_process(false)
	var data: Dictionary = tank.snapshot()
	check(TankCare.forecast_text(TankCare.assess(data)).contains("locked"), "new tank care explains locked offline simulation")
	data.asset_levels.idle_duration = 4
	for fish in data.fish:
		fish.hunger = 0.0
		fish.starving = 0.0
	var original := JSON.stringify(data)
	var care := TankCare.assess(data)
	check(JSON.stringify(data) == original, "forecast cannot change the real tank")
	check(not care.adequate and care.report.lost == 20, "unautomated tank warns about insufficient care")
	var profile := FishProfile.new()
	var expected_first_loss: float = INF
	for fish in data.fish:
		var metabolism: float = FishGenome.phenotype_from_data(fish.genome, "metabolism")
		var hunger_time: float = 1.0 / (profile.hunger_rate * FishGenome.hunger_multiplier_for(metabolism))
		expected_first_loss = minf(expected_first_loss, hunger_time + profile.starvation_grace)
	check(absf(care.report.first_loss_at - expected_first_loss) <= 2.0, "first starvation forecast follows inherited metabolism timing")
	data.owned = {"feeder": true, "seahorse": true, "snail": true}
	data.reserve = []
	for i in range(200):
		data.reserve.append(0)
	care = TankCare.assess(data)
	check(care.adequate, "combined automation can match twenty fish while stocked")
	var stock_case: Dictionary = data.duplicate(true)
	stock_case.fish = stock_case.fish.slice(0, 5)
	stock_case.owned.seahorse = false
	care = TankCare.assess(stock_case)
	check(care.report.stock_empty_at > 0 and care.report.stock_used == 200, "forecast reports finite stock exhaustion")
	check(care.report.first_loss_at < 0 or care.report.first_loss_at > care.report.stock_empty_at, "food exhaustion precedes any later starvation")
	data.fish = [data.fish[0]]
	data.owned.feeder = false
	data.reserve = []
	care = TankCare.assess(data)
	check(care.adequate and care.report.lost == 0, "seahorse sustains one fish without feeder stock")
	data.fish = []
	check(TankCare.forecast_text(TankCare.assess(data)).contains("bubbles"), "empty tank explains recovery")
	var fish = get_nodes_in_group("fish")[0]
	fish.hunger = 1.0
	check(TankCare.warnings(get_nodes_in_group("fish"), 0, true).contains("FEED NOW"), "urgent starvation warning")
	check(TankCare.warnings(get_nodes_in_group("fish"), 0, true).contains("Feeder empty"), "empty stock warning")
	while get_nodes_in_group("fish").size() < 20:
		tank.spawn_fish()
	check(TankCare.warnings(get_nodes_in_group("fish"), 200, true).contains("Tank full"), "capacity warning")
	tank.refresh_care()
	check(tank.care_details.text.contains("Approximate"), "panel explains forecast uncertainty")
	print("Tank care failures: ", failures)
	quit(1 if failures else 0)
