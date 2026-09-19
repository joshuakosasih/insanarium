class_name BackupValidation
extends RefCounted
const MAX_BYTES: int = 2000000

static func parse(text: String) -> Dictionary:
	if text.to_utf8_buffer().size() > MAX_BYTES:
		return {}
	var data = JSON.parse_string(text)
	if not data is Dictionary:
		return {}
	if not number(data.get("version"), 1, 2) or float(data.version) != floorf(float(data.version)):
		return {}
	for key in ["money", "tier"]:
		if not number(data.get(key), 0, 1000000000000):
			return {}
	if data.tier > 2:
		return {}
	for key in ["fish", "food", "coins", "reserve"]:
		if not data.get(key) is Array:
			return {}
	if data.fish.size() > 50 or data.food.size() > 80 or data.coins.size() > 150 or data.reserve.size() > 200:
		return {}
	if data.has("waste"):
		if not data.waste is Array or data.waste.size() > 100:
			return {}
		for item in data.waste:
			if not item is Dictionary or not number(item.get("x", 0), 0, 1152) or not number(item.get("y", 0), 0, 1010) or not item.get("settled", false) is bool:
				return {}
			if not number(item.get("life", FishWaste.FLOOR_LIFETIME), 0, FishWaste.FLOOR_LIFETIME):
				return {}
	if not number(data.get("cleanliness", 100), 0, 100):
		return {}
	if not data.get("owned") is Dictionary:
		return {}
	for key in ["snail", "seahorse", "feeder"]:
		if not data.owned.get(key) is bool:
			return {}
	for optional_pet in ["urchin", "puffer"]:
		if data.owned.has(optional_pet) and not data.owned[optional_pet] is bool:
			return {}
	if data.has("asset_levels"):
		if not data.asset_levels is Dictionary:
			return {}
		if data.asset_levels.has("snail") and not data.asset_levels.has("snail_speed"):
			if not integer_in_range(data.asset_levels.snail, 0, 3) or bool(data.owned.snail) != (int(data.asset_levels.snail) > 0):
				return {}
		else:
			for track in ["snail_speed", "snail_stamina", "snail_sleep", "puffer_speed", "puffer_curiosity", "coin_lifetime"]:
				if not integer_in_range(data.asset_levels.get(track, 0), 0, 4):
					return {}
			if not data.owned.snail and (int(data.asset_levels.get("snail_speed", 0)) > 0 or int(data.asset_levels.get("snail_stamina", 0)) > 0 or int(data.asset_levels.get("snail_sleep", 0)) > 0):
				return {}
			if not bool(data.owned.get("puffer", data.owned.get("urchin", false))) and (int(data.asset_levels.get("puffer_speed", 0)) > 0 or int(data.asset_levels.get("puffer_curiosity", 0)) > 0):
				return {}
	for tier in data.reserve:
		if not number(tier, 0, 2):
			return {}
	for fish in data.fish:
		if not fish is Dictionary:
			return {}
		for key in ["x", "y", "hunger", "stage", "meals", "credit", "mutation", "starving", "coin_left", "sex", "breeding_left"]:
			if not number(fish.get(key, 0), 0, 1000000000000):
				return {}
		if fish.get("stage", 0) > 3 or fish.get("mutation", 0) > 3 or fish.get("sex", 0) > 2 or fish.get("hunger", 0) > 1:
			return {}
		if not number(fish.get("health", 100), 0, FishHealth.MAX_POSSIBLE_HEALTH):
			return {}
		if fish.has("genome"):
			if not fish.genome is Dictionary:
				return {}
			for trait_name in ["metabolism", "allocation"]:
				if not fish.genome.get(trait_name, []) is Array or fish.genome.get(trait_name, []).size() != 2:
					return {}
				for allele in fish.genome[trait_name]:
					if not number(allele, 0, 1):
						return {}
			for trait_name in ["vitality", "speed"]:
				if fish.genome.has(trait_name):
					if not fish.genome[trait_name] is Array or fish.genome[trait_name].size() != 2:
						return {}
					for allele in fish.genome[trait_name]:
						if not number(allele, 0, 1):
							return {}
		if not fish.get("life", {}) is Dictionary:
			return {}
		var life: Dictionary = fish.get("life", {})
		if not life.get("parents", []) is Array or life.get("parents", []).size() > 2:
			return {}
		for parent in life.get("parents", []):
			if not parent is String or parent.length() > 128:
				return {}
		if not life.get("id", "") is String or not life.get("origin", "") is String:
			return {}
		for key in ["age", "born_at"]:
			if not number(life.get(key, 0), -1, 1000000000000):
				return {}
	for key in ["food", "coins"]:
		for item in data[key]:
			if not item is Dictionary:
				return {}
			for field in ["x", "y", "value", "tier", "life"]:
				if not number(item.get(field, 0), 0, 1000000000000):
					return {}
	for coin in data.coins:
		if coin.has("grounded") and not coin.grounded is bool:
			return {}
	for key in ["saved_at", "simulation_elapsed", "next_fish_id", "breeding_check", "feeder_left", "seahorse_left", "snail_x", "snail_stamina", "snail_sleep", "snail_collection_progress", "urchin_x", "urchin_path", "urchin_decision", "urchin_pause", "puffer_x", "puffer_y", "puffer_destination_x", "puffer_destination_y", "puffer_wander", "puffer_puff"]:
		if not number(data.get(key, 0), 0, 1000000000000):
			return {}
	if not number(data.get("urchin_direction", 1), -1, 1):
		return {}
	return data

static func number(value: Variant, low: float, high: float) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and float(value) >= low and float(value) <= high

static func integer_in_range(value: Variant, low: int, high: int) -> bool:
	return number(value, low, high) and float(value) == floorf(float(value))
