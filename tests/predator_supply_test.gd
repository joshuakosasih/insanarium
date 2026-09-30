extends SceneTree
## Ideal-care throughput check: three selected breeders should sustain eight predators.
var failures: int = 0

func check(ok: bool, description: String) -> void:
	if not ok:
		failures += 1
		push_error(description)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var tank = load("res://scenes/aquarium.tscn").instantiate()
	root.add_child(tank)
	tank.set_process(false)
	var source: Dictionary = tank.snapshot()
	var template: Dictionary = source.fish[0].duplicate(true)
	source.fish = []
	source.tank_index = 2
	source.saved_at = 1000.0
	source.next_fish_id = 100
	source.cleanliness = 100.0
	source.food = []
	source.coins = []
	source.waste = []
	source.owned.feeder = true
	source.owned.sponge = true
	source.asset_levels.sponge_breath = 4
	source.asset_levels.idle_duration = 4
	source.feeder_left = 0.0
	source.reserve = []
	for i in range(200):
		source.reserve.append(0)
	for i in range(3):
		var brood: Dictionary = template.duplicate(true)
		brood.life.id = "BREEDER%d" % i
		brood.life.parents = []
		brood.life.age = 0.0
		brood.species_id = "starter_fish"
		brood.stage = 2
		brood.meals = 10
		brood.credit = 10.0
		brood.hunger = 0.1
		brood.health = 100.0
		brood.coin_left = 1000.0
		brood.broodstock = true
		brood.brood_boosted = true
		brood.brood_left = i * 22.0
		brood.genome.fertility = [1.0, 1.0]
		source.fish.append(brood)
	for i in range(8):
		var predator: Dictionary = template.duplicate(true)
		predator.life.id = "PIRANHA%d" % i
		predator.life.parents = []
		predator.life.age = 0.0
		predator.species_id = "piranha"
		predator.stage = 2
		predator.meals = 10
		predator.credit = 10.0
		predator.hunger = 0.1 + i * 0.04
		predator.health = 100.0
		predator.coin_left = 1000.0
		predator.broodstock = false
		predator.brood_boosted = false
		predator.brood_left = 0.0
		predator.genome.fertility = [0.5, 0.5]
		source.fish.append(predator)
	var result: Dictionary = OfflineProgress.advance(source, 29800.0)
	var living_predators: int = result.data.fish.filter(func(fish: Dictionary) -> bool: return str(fish.get("species_id", "")) == "piranha").size()
	check(result.report.simulated == 2880.0 and result.report.brood_fry > 40 and result.report.preyed > 40, "selected breeders supply prey through a long bounded away estimate")
	check(living_predators == 8 and result.report.lost == 0, "three max-Fertility boosted breeders sustain eight neutral Adult piranhas under ideal care")
	var average_source: Dictionary = source.duplicate(true)
	average_source.reserve = average_source.reserve.slice(0, 150)
	for i in range(3):
		average_source.fish[i].genome.fertility = [0.5, 0.5]
	var average_result: Dictionary = OfflineProgress.advance(average_source, 29800.0)
	var average_predators: int = average_result.data.fish.filter(func(fish: Dictionary) -> bool: return str(fish.get("species_id", "")) == "piranha").size()
	var remaining_fry: int = average_result.data.fish.filter(func(fish: Dictionary) -> bool: return str(fish.get("species_id", "")) == "feeder_guppy").size()
	check(average_predators == 8 and remaining_fry > 0 and average_result.report.lost == 0 and average_result.report.stock_empty_at < 0.0, "three average-Fertility boosted breeders keep eight predators supplied through an eight-hour away period with 150 pellets")
	var ten_source: Dictionary = source.duplicate(true)
	for i in range(8, 10):
		var extra_predator: Dictionary = ten_source.fish[3].duplicate(true)
		extra_predator.life.id = "PIRANHA%d" % i
		extra_predator.hunger = 0.1 + i * 0.04
		ten_source.fish.append(extra_predator)
	var ten_result: Dictionary = OfflineProgress.advance(ten_source, 29800.0)
	var ten_living: int = ten_result.data.fish.filter(func(fish: Dictionary) -> bool: return str(fish.get("species_id", "")) == "piranha").size()
	check(ten_living == 10 and ten_result.report.lost == 0, "three max-Fertility boosted breeders also sustain ten predators near the 3.5-each throughput target")
	var low_source: Dictionary = source.duplicate(true)
	low_source.fish = [low_source.fish[0], low_source.fish[3]]
	low_source.fish[0].genome.fertility = [0.0, 0.0]
	var low_one: Dictionary = OfflineProgress.advance(low_source, 29800.0)
	check(low_one.data.fish.any(func(fish: Dictionary) -> bool: return str(fish.get("species_id", "")) == "piranha") and low_one.report.lost == 0, "one minimum-Fertility boosted breeder sustains one predator under ideal care")
	var low_two_source: Dictionary = low_source.duplicate(true)
	low_two_source.fish.append(source.fish[4].duplicate(true))
	var low_two: Dictionary = OfflineProgress.advance(low_two_source, 29800.0)
	var low_two_living: int = low_two.data.fish.filter(func(fish: Dictionary) -> bool: return str(fish.get("species_id", "")) == "piranha").size()
	check(low_two_living < 2, "one minimum-Fertility boosted breeder cannot sustain two predators over a long estimate")
	print("Predator supply failures: ", failures)
	quit(1 if failures else 0)
