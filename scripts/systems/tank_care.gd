class_name TankCare
extends RefCounted
## Read-only forecast using the same bounded care model as actual offline progress.
static func assess(data: Dictionary) -> Dictionary:
	var checkpoint: Dictionary = data.duplicate(true)
	checkpoint.saved_at = 0.0
	var limit: float = IdleAssets.idle_limit_for(int(data.get("asset_levels", {}).get("idle_duration", 0)))
	var result := OfflineProgress.advance(checkpoint, limit)
	# Fish eat at the hunger threshold; early meals cannot use all pellet nutrition.
	var demand: float = 0.0
	for fish in data.fish:
		var fish_profile := FishProfile.for_species(str(fish.get("species_id", "starter_fish")))
		var metabolism: float = FishGenome.phenotype_from_data(fish.get("genome", {}), "metabolism")
		demand += fish_profile.hunger_rate * FishGenome.hunger_multiplier_for(metabolism) / minf(fish_profile.hungry_threshold, FeedProfile.new().nutrition)
	var seahorse_level: int = clampi(int(data.get("asset_levels", {}).get("seahorse_interval", 0)), 0, IdleAssets.MAX_UPGRADE_LEVEL)
	var seahorse_supply: float = 1.0 / IdleAssets.SEAHORSE_INTERVALS[seahorse_level] if data.owned.seahorse else 0.0
	var supply: float = (0.5 if data.owned.feeder and not data.reserve.is_empty() else 0.0) + seahorse_supply
	return {"count": data.fish.size(), "stock": data.reserve.size(),
		"demand": demand * 60.0, "supply": supply * 60.0,
		"adequate": supply >= demand, "report": result.report, "away_limit": limit}

static func forecast_text(care: Dictionary) -> String:
	if care.count == 0:
		return "No fish to care for. Pop income bubbles to rebuild your tank."
	var report: Dictionary = care.report
	var away_limit: float = float(care.get("away_limit", 0.0))
	if away_limit <= 0.0:
		return "Offline simulation is locked. Upgrade Away Time in the shop before leaving this tank unattended."
	var horizon: String = duration(away_limit)
	var coverage: String = "No starvation predicted within %s away." % horizon
	if report.first_loss_at >= 0.0:
		coverage = "First starvation risk in about %s away." % duration(report.first_loss_at / ActivityPace.IDLE_RATE)
	var stock: String = "Reserve lasts beyond this %s forecast." % horizon
	if care.stock == 0:
		stock = "No stocked pellets available."
	elif report.stock_empty_at >= 0.0:
		stock = "Reserve runs out in about %s away (%s active)." % [duration(report.stock_empty_at / ActivityPace.IDLE_RATE), duration(report.stock_empty_at)]
	var water: String = "No water-quality deaths predicted within %s away." % horizon
	if report.first_water_loss_at >= 0.0:
		water = "First water-quality loss in about %s away." % duration(report.first_water_loss_at / ActivityPace.IDLE_RATE)
	var aging: String = "No old-age deaths predicted within %s away." % horizon
	if report.first_old_age_loss_at >= 0.0:
		aging = "First old-age loss in about %s away." % duration(report.first_old_age_loss_at / ActivityPace.IDLE_RATE)
	return "%s\n%s\n%s\n%s\n%s estimate: %d meals, %d pellets used, %d fish lost." % [coverage, stock, water, aging, horizon, report.fed, report.stock_used, report.lost]

static func duration(seconds: float) -> String:
	if seconds < 60.0:
		return "%ds" % int(ceil(seconds))
	if seconds < 3600.0:
		return "%dm" % int(ceil(seconds / 60.0))
	return "%.1fh" % (seconds / 3600.0)

static func warnings(fish: Array, stock: int, feeder: bool, cleanliness: float = 100.0) -> String:
	var hungry: int = 0
	var starving: int = 0
	var injured: int = 0
	for animal in fish:
		if animal.health.current < animal.health.maximum:
			injured += 1
		if animal.hunger >= 1.0:
			starving += 1
		elif animal.hunger >= animal.profile.hungry_threshold:
			hungry += 1
	var messages: Array[String] = []
	if starving > 0:
		messages.append("FEED NOW: %d starving" % starving)
	if hungry > 0:
		messages.append("%d hungry" % hungry)
	if cleanliness < 20.0:
		messages.append("TOXIC WATER: health collapse accelerating")
	elif cleanliness < 40.0:
		messages.append("Dirty water: health falling")
	elif cleanliness < 65.0:
		messages.append("Cloudy water: health beginning to fall")
	if feeder and stock <= 20:
		messages.append("Feeder empty" if stock == 0 else "Low stock: %d pellets" % stock)
	if fish.size() >= FishBreeding.CAPACITY:
		messages.append("Tank full: purchases blocked")
	elif fish.size() >= FishBreeding.COMFORT_WARNING:
		messages.append("Population high: tank nearing capacity")
	return " · ".join(messages) if not messages.is_empty() else "No immediate care warnings."
