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
	tank.assets.feeder_left = -100.0
	check(not BackupValidation.parse(JSON.stringify(tank.snapshot())).is_empty(), "backup stays valid before feeder purchase")
	var data: Dictionary = tank.snapshot()
	data.saved_at = 1000.0
	var locked := OfflineProgress.advance(data, 1200.0)
	check(locked.report.simulated == 0.0 and locked.report.away_limit == 0.0 and locked.report.capped, "new tanks begin with offline simulation locked")
	data.asset_levels.idle_duration = 4
	for fish in data.fish:
		fish.hunger = 0.0
		fish.coin_left = 20.0
		fish.stage = 1
	var original: String = JSON.stringify(data)
	var result := OfflineProgress.advance(data, 1200.0)
	check(JSON.stringify(data) == original, "calculation does not mutate source checkpoint")
	check(result.report.simulated == 20.0 and result.report.earned + result.report.waste == 5, "ten-percent elapsed time and deterministic fish output")
	check(result.data.money == data.money and result.data.coins.size() + result.data.waste.size() == 5, "outputs become collectible coins or visible waste")
	check(result.data.cleanliness < data.cleanliness, "offline population and waste reduce cleanliness")
	check(is_equal_approx(result.data.fish[0].life.age, data.fish[0].life.age + 20.0), "offline age uses simulation time")
	var aging: Dictionary = data.duplicate(true)
	aging.fish = [aging.fish[0]]
	aging.fish[0].life.age = FishAging.lifespan_from_data(aging.fish[0].genome) - 5.0
	var aging_result := OfflineProgress.advance(aging, 1100.0)
	check(aging_result.data.fish.is_empty() and aging_result.report.old_age_lost == 1, "old age is resolved during offline catch-up")
	var expiring: Dictionary = data.duplicate(true)
	expiring.coins = [{"x": 500, "y": 650, "value": 3, "diamond": false, "life": 5.0}]
	check(OfflineProgress.advance(expiring, 1100.0).data.coins.is_empty(), "uncollected coin can expire during away calculation")
	var again := OfflineProgress.advance(result.data, 1200.0)
	check(again.report.earned == 0 and again.report.simulated == 0, "consumed timestamp prevents duplicate progress")
	var backward := OfflineProgress.advance(data, 900.0)
	check(backward.report.simulated == 0, "negative elapsed time gives no progress")
	check(OfflineProgress.advance(backward.data, 1000).report.simulated == 0, "clock rollback does not reopen consumed time")
	check(BackupValidation.parse('{"version":{}}').is_empty(), "malformed version is rejected safely")
	var capped := OfflineProgress.advance(data, 1000000.0)
	check(capped.report.simulated == 2880.0 and capped.report.capped, "away time capped at eight hours")
	check(capped.report.lost == 5 and capped.data.fish.is_empty(), "unfed fish can die offline")
	var toxic: Dictionary = data.duplicate(true)
	toxic.cleanliness = 0.0
	for fish in toxic.fish:
		fish.health = 1.0
		fish.hunger = 0.0
		fish.coin_left = 20.0
	var toxic_result := OfflineProgress.advance(toxic, 1300.0)
	check(toxic_result.report.water_lost == 5 and toxic_result.data.fish.is_empty(), "toxic water can kill weakened fish offline")
	var legacy: Dictionary = data.duplicate(true)
	legacy.erase("saved_at")
	check(OfflineProgress.advance(legacy, 5000).report.simulated == 0, "legacy saves receive no invented offline time")
	data.owned = {"snail": true, "seahorse": true, "feeder": true}
	data.asset_levels.snail_speed = 0
	data.asset_levels.snail_stamina = 0
	data.asset_levels.snail_sleep = 0
	data.reserve = []
	for i in range(200):
		data.reserve.append(0)
	result = OfflineProgress.advance(data, 8200)
	check(result.data.fish.size() == 5 and result.report.stock_used > 0, "stocked automation keeps five fish alive for two hours away")
	check(result.data.money == data.money + result.report.collected and result.report.collected > 0, "snail collection credits wallet")
	var base_snail: Dictionary = data.duplicate(true)
	base_snail.fish = []
	base_snail.food = []
	base_snail.reserve = []
	base_snail.coins = []
	base_snail.waste = []
	base_snail.cleanliness = 100.0
	for i in range(30):
		base_snail.coins.append({"x": 100 + i * 20, "y": 650, "value": 1, "diamond": false, "life": 75.0})
	var fast_snail: Dictionary = base_snail.duplicate(true)
	fast_snail.asset_levels.snail_speed = 4
	fast_snail.asset_levels.snail_stamina = 4
	fast_snail.asset_levels.snail_sleep = 4
	var base_collection: int = OfflineProgress.advance(base_snail, 1750).report.collected
	var fast_collection: int = OfflineProgress.advance(fast_snail, 1750).report.collected
	check(base_collection > 0 and fast_collection > base_collection, "offline estimate uses snail speed stamina and sleep capacity")
	check(result.report.fed > 0 and result.report.growth > 0, "offline feeding advances growth")
	check(result.data.fish.size() == 5, "offline breeding produces no extra fish")
	check(JSON.stringify(result) == JSON.stringify(OfflineProgress.advance(data, 8200)), "same checkpoint produces deterministic results")
	check(not BackupValidation.parse(JSON.stringify(data)).is_empty(), "valid backup passes validation")
	var earlier_genetics: Dictionary = data.duplicate(true)
	for fish in earlier_genetics.fish:
		fish.genome.erase("vitality")
		fish.genome.erase("speed")
	var parsed_earlier: Dictionary = BackupValidation.parse(JSON.stringify(earlier_genetics))
	var migrated_earlier: Dictionary = SaveMigration.upgrade(parsed_earlier)
	check(not parsed_earlier.is_empty() and migrated_earlier.fish[0].genome.vitality == [0.5, 0.5] and migrated_earlier.fish[0].genome.speed == [0.5, 0.5], "earlier backups gain neutral vitality and speed")
	var old_save: Dictionary = data.duplicate(true)
	old_save.asset_levels = {"snail": 3}
	var migrated_old: Dictionary = SaveMigration.upgrade(old_save)
	check(migrated_old.asset_levels.snail_speed == 3 and migrated_old.asset_levels.snail_stamina == 2 and migrated_old.asset_levels.snail_sleep == 0, "old maximum snail maps to compensated stat upgrades and the new base sleep track")
	var old_urchin: Dictionary = data.duplicate(true)
	old_urchin.owned["urchin"] = true
	old_urchin.owned.erase("puffer")
	var migrated_urchin: Dictionary = SaveMigration.upgrade(old_urchin)
	check(migrated_urchin.owned.puffer and not migrated_urchin.owned.has("urchin") and migrated_urchin.asset_levels.puffer_speed == 0 and migrated_urchin.asset_levels.puffer_curiosity == 0, "old sea urchin purchase migrates to a base bubble puffer")
	var invalid_level: Dictionary = data.duplicate(true)
	invalid_level.asset_levels.snail_speed = 9
	invalid_level.asset_levels.snail_sleep = 9
	check(BackupValidation.parse(JSON.stringify(invalid_level)).is_empty(), "out-of-range pet level is rejected")
	check(BackupValidation.parse('{"version":2,"money":5}').is_empty(), "incomplete backup is rejected")
	var invalid: Dictionary = data.duplicate(true)
	invalid.fish[0].stage = 99
	check(BackupValidation.parse(JSON.stringify(invalid)).is_empty(), "out-of-range growth stage is rejected")
	invalid = data.duplicate(true)
	invalid.fish[0].life.parents = [1, 2]
	check(BackupValidation.parse(JSON.stringify(invalid)).is_empty(), "invalid parent structure is rejected")
	tank.pending_import = result.data
	tank.finish_import()
	check(get_nodes_in_group("fish").size() == 5 and tank.economy.money == result.data.money, "import restores checkpoint without duplicate offline earnings")
	print("Offline failures: ", failures)
	quit(1 if failures else 0)
