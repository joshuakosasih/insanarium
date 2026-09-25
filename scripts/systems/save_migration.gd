class_name SaveMigration
extends RefCounted
## Version 1 has no reliable ages or ancestry; never invent these facts.
static func upgrade(source: Dictionary) -> Dictionary:
	var data: Dictionary = source.duplicate(true)
	var source_version: int = int(data.get("version", 1))
	var registry := LifeRegistry.new()
	registry.next_id = maxi(1, int(data.get("next_fish_id", 1)))
	for item in data.get("fish", []):
		if source_version < 3:
			var old_stage: int = clampi(int(item.get("stage", 0)), 0, 3)
			# Insert Teen while preserving the equivalent maturity of existing fish.
			item["stage"] = old_stage + 1 if old_stage > 0 or float(item.get("credit", 0)) >= 2.0 else 0
		var life: Dictionary = item.get("life", {})
		var genome := FishGenome.new()
		genome.from_data(item.get("genome", {}))
		item["genome"] = genome.to_data()
		item["health"] = clampf(float(item.get("health", FishHealth.MAX_HEALTH)), 0.0, genome.max_health())
		registry.reserve(str(life.get("id", "")))
		for parent in life.get("parents", []):
			registry.reserve(str(parent))
	var seen: Dictionary = {}
	for item in data.get("fish", []):
		var life := FishLife.new()
		life.from_data(item.get("life", {}))
		if life.id.is_empty() or seen.has(life.id):
			registry.allocate(life, "Legacy")
			life.birth_sim_time = -1
			life.age_known = false
		seen[life.id] = true
		item["life"] = life.to_data()
	data["next_fish_id"] = registry.next_id
	data["simulation_elapsed"] = maxf(0.0, float(data.get("simulation_elapsed", 0)))
	data["cleanliness"] = clampf(float(data.get("cleanliness", TankEnvironment.MAX_CLEANLINESS)), 0.0, TankEnvironment.MAX_CLEANLINESS)
	if not data.has("waste") or not data.waste is Array:
		data["waste"] = []
	var owned: Dictionary = data.get("owned", {}).duplicate(true)
	# The early bubble collector was a sea urchin. Preserve that purchase as the replacement puffer.
	owned["puffer"] = bool(owned.get("puffer", false)) or bool(owned.get("urchin", false))
	owned["shrimp"] = bool(owned.get("shrimp", false))
	owned.erase("urchin")
	data["owned"] = owned
	if not data.has("puffer_x") and data.has("urchin_x"):
		data["puffer_x"] = clampf(float(data.get("urchin_x", 760)), 110, 1042)
		data["puffer_y"] = 540.0
	var levels: Dictionary = data.get("asset_levels", {}).duplicate(true)
	if not levels.has("snail_speed"):
		var legacy_snail: int = clampi(int(levels.get("snail", 1 if owned.get("snail", false) else 0)), 0, 3)
		levels["snail_speed"] = 3 if legacy_snail >= 2 else 0
		levels["snail_stamina"] = 2 if legacy_snail >= 3 else 0
	levels.erase("snail")
	levels["snail_speed"] = clampi(int(levels.get("snail_speed", 0)), 0, 4)
	levels["snail_stamina"] = clampi(int(levels.get("snail_stamina", 0)), 0, 4)
	levels["snail_sleep"] = clampi(int(levels.get("snail_sleep", 0)), 0, 4)
	levels["puffer_speed"] = clampi(int(levels.get("puffer_speed", 0)), 0, 4)
	levels["puffer_curiosity"] = clampi(int(levels.get("puffer_curiosity", 0)), 0, 4)
	levels["shrimp_speed"] = clampi(int(levels.get("shrimp_speed", 0)), 0, 4)
	levels["shrimp_digestion"] = clampi(int(levels.get("shrimp_digestion", 0)), 0, 4)
	levels["seahorse_interval"] = clampi(int(levels.get("seahorse_interval", 0)), 0, 4)
	levels["seahorse_feed"] = clampi(int(levels.get("seahorse_feed", 0)), 0, 2)
	levels["coin_lifetime"] = clampi(int(levels.get("coin_lifetime", 0)), 0, 4)
	levels["coin_value"] = clampi(int(levels.get("coin_value", 0)), 0, 4)
	levels["diamond_value"] = clampi(int(levels.get("diamond_value", 0)), 0, 4)
	levels["idle_duration"] = clampi(int(levels.get("idle_duration", 0)), 0, 4)
	levels["bubble_capacity"] = clampi(int(levels.get("bubble_capacity", 0)), 0, 4)
	levels["bubble_value"] = clampi(int(levels.get("bubble_value", 0)), 0, 4)
	if not owned.get("snail", false):
		levels.snail_speed = 0
		levels.snail_stamina = 0
		levels.snail_sleep = 0
	if not owned.get("puffer", false):
		levels.puffer_speed = 0
		levels.puffer_curiosity = 0
	if not owned.get("shrimp", false):
		levels.shrimp_speed = 0
		levels.shrimp_digestion = 0
	if not owned.get("seahorse", false):
		levels.seahorse_interval = 0
		levels.seahorse_feed = 0
	data["asset_levels"] = levels
	data["version"] = 3
	return data
