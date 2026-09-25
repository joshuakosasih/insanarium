class_name IdleAssets
extends RefCounted
## Owned automation and stocked pellet tiers. Purchases are once per tank.
const PRICES := {"snail": 50, "shrimp": 75, "seahorse": 125, "puffer": 175, "feeder": 100}
const UPGRADE_PRICES := [40, 100, 250, 625]
const SNAIL_UPGRADE_PRICES := [30, 75, 190, 475]
# The snail's largest gains arrive first, then taper toward its practical cap.
const SNAIL_SPEEDS := [16.0, 30.0, 40.0, 47.0, 52.0]
const SNAIL_STAMINAS := [10.0, 28.0, 43.0, 53.0, 60.0]
const SNAIL_SLEEPS := [20.0, 11.0, 7.0, 5.0, 4.0]
const PUFFER_SPEEDS := [45.0, 60.0, 78.0, 100.0, 125.0]
const PUFFER_CURIOSITIES := [0.30, 0.45, 0.60, 0.80, 1.0]
const SHRIMP_SPEEDS := [30.0, 45.0, 62.0, 82.0, 108.0]
const SHRIMP_DIGESTION := [12.0, 8.0, 5.0, 3.5, 2.0]
const SHRIMP_UPGRADE_PRICES := [20, 60, 180, 540]
const SEAHORSE_INTERVALS := [18.0, 14.0, 11.0, 8.0, 6.0]
const SEAHORSE_INTERVAL_PRICES := [60, 150, 375, 940]
const SEAHORSE_FEED_TIERS := [0, 1, 2]
const SEAHORSE_FEED_PRICES := [150, 500]
const COIN_LIFETIMES := [8.0, 15.0, 25.0, 45.0, 75.0]
const DIAMOND_LIFETIMES := [8.0, 15.0, 25.0, 45.0, 75.0]
const IDLE_LIMITS := [0.0, 300.0, 1800.0, 7200.0, 28800.0]
const BUBBLE_CAPACITIES := [1, 2, 3, 5, 8]
const BUBBLE_MULTIPLIERS := [1.0, 1.5, 2.25, 3.5, 5.0]
const COIN_MULTIPLIERS := [1, 2, 3, 5, 8]
const COIN_VALUE_PRICES := [200, 800, 3200, 12800]
const DIAMOND_MULTIPLIERS := [1, 2, 4, 7, 12]
const DIAMOND_VALUE_PRICES := [150, 450, 1350, 4050]
const DIAMOND_LIFETIME_PRICES := [50, 150, 450, 1350]
const IDLE_UPGRADE_PRICES := [50, 150, 450, 1350]
const BUBBLE_UPGRADE_PRICES := [30, 90, 270, 810]
const MAX_UPGRADE_LEVEL: int = 4
var owned: Dictionary = {"snail": false, "shrimp": false, "seahorse": false, "puffer": false, "feeder": false}
var levels: Dictionary = {"snail_speed": 0, "snail_stamina": 0, "snail_sleep": 0, "shrimp_speed": 0, "shrimp_digestion": 0, "seahorse_interval": 0, "seahorse_feed": 0, "puffer_speed": 0, "puffer_curiosity": 0, "coin_lifetime": 0, "coin_value": 0, "diamond_value": 0, "diamond_lifetime": 0, "idle_duration": 0, "bubble_capacity": 0, "bubble_value": 0}
var reserve: Array[int] = []
var feeder_left: float = 2.0
const CAPACITY: int = 200

func purchase(kind: String, economy: Economy) -> bool:
	if not PRICES.has(kind) or owned[kind] or not economy.spend(PRICES[kind]):
		return false
	owned[kind] = true
	return true

func upgrade_price(track: String) -> int:
	if not levels.has(track):
		return 0
	if track.begins_with("snail_") and not owned.snail:
		return 0
	if track.begins_with("puffer_") and not owned.puffer:
		return 0
	if track.begins_with("shrimp_") and not owned.shrimp:
		return 0
	if track.begins_with("seahorse_") and not owned.seahorse:
		return 0
	var level: int = int(levels[track])
	if level >= track_max_level(track):
		return 0
	if track == "idle_duration":
		return IDLE_UPGRADE_PRICES[level]
	if track.begins_with("snail_"):
		return SNAIL_UPGRADE_PRICES[level]
	if track.begins_with("shrimp_"):
		return SHRIMP_UPGRADE_PRICES[level]
	if track == "seahorse_interval":
		return SEAHORSE_INTERVAL_PRICES[level]
	if track == "seahorse_feed":
		return SEAHORSE_FEED_PRICES[level]
	if track.begins_with("bubble_"):
		return BUBBLE_UPGRADE_PRICES[level]
	if track == "coin_value":
		return COIN_VALUE_PRICES[level]
	if track == "diamond_value":
		return DIAMOND_VALUE_PRICES[level]
	if track == "diamond_lifetime":
		return DIAMOND_LIFETIME_PRICES[level]
	return UPGRADE_PRICES[level]

func upgrade(track: String, economy: Economy) -> bool:
	var price := upgrade_price(track)
	if price == 0 or not economy.spend(price):
		return false
	levels[track] = int(levels[track]) + 1
	return true

func track_max_level(track: String) -> int:
	return SEAHORSE_FEED_TIERS.size() - 1 if track == "seahorse_feed" else MAX_UPGRADE_LEVEL

func pet_tracks(kind: String) -> Array[String]:
	var tracks: Dictionary = {
		"snail": ["snail_speed", "snail_stamina", "snail_sleep"],
		"shrimp": ["shrimp_speed", "shrimp_digestion"],
		"seahorse": ["seahorse_interval", "seahorse_feed"],
		"puffer": ["puffer_speed", "puffer_curiosity"]}
	var result: Array[String] = []
	for track in tracks.get(kind, []):
		result.append(track)
	return result

func pet_sell_value(kind: String) -> int:
	if not bool(owned.get(kind, false)):
		return 0
	var invested: int = int(PRICES.get(kind, 0))
	for track in pet_tracks(kind):
		var current_level: int = int(levels[track])
		for purchased_level in range(current_level):
			invested += upgrade_price_at(track, purchased_level)
	return maxi(1, floori(invested * 0.5))

func sell_pet(kind: String, economy: Economy) -> int:
	var value := pet_sell_value(kind)
	if value <= 0:
		return 0
	owned[kind] = false
	for track in pet_tracks(kind):
		levels[track] = 0
	economy.credit(value)
	return value

func upgrade_price_at(track: String, level: int) -> int:
	if track.begins_with("snail_"):
		return SNAIL_UPGRADE_PRICES[level]
	if track.begins_with("shrimp_"):
		return SHRIMP_UPGRADE_PRICES[level]
	if track == "seahorse_interval":
		return SEAHORSE_INTERVAL_PRICES[level]
	if track == "seahorse_feed":
		return SEAHORSE_FEED_PRICES[level]
	return UPGRADE_PRICES[level]

func snail_speed() -> float:
	return SNAIL_SPEEDS[clampi(int(levels.snail_speed), 0, MAX_UPGRADE_LEVEL)]

func snail_stamina() -> float:
	return SNAIL_STAMINAS[clampi(int(levels.snail_stamina), 0, MAX_UPGRADE_LEVEL)]

func snail_sleep() -> float:
	return SNAIL_SLEEPS[clampi(int(levels.snail_sleep), 0, MAX_UPGRADE_LEVEL)]

func puffer_speed() -> float:
	return PUFFER_SPEEDS[clampi(int(levels.puffer_speed), 0, MAX_UPGRADE_LEVEL)]

func puffer_curiosity() -> float:
	return PUFFER_CURIOSITIES[clampi(int(levels.puffer_curiosity), 0, MAX_UPGRADE_LEVEL)]

func shrimp_speed() -> float:
	return SHRIMP_SPEEDS[clampi(int(levels.shrimp_speed), 0, MAX_UPGRADE_LEVEL)]

func shrimp_digestion() -> float:
	return SHRIMP_DIGESTION[clampi(int(levels.shrimp_digestion), 0, MAX_UPGRADE_LEVEL)]

func seahorse_interval() -> float:
	return SEAHORSE_INTERVALS[clampi(int(levels.seahorse_interval), 0, MAX_UPGRADE_LEVEL)]

func seahorse_feed_tier() -> int:
	return SEAHORSE_FEED_TIERS[clampi(int(levels.seahorse_feed), 0, SEAHORSE_FEED_TIERS.size() - 1)]

func coin_lifetime() -> float:
	return coin_lifetime_for(int(levels.coin_lifetime))

static func coin_lifetime_for(level: int) -> float:
	return COIN_LIFETIMES[clampi(level, 0, MAX_UPGRADE_LEVEL)]

func coin_multiplier() -> int:
	return COIN_MULTIPLIERS[clampi(int(levels.coin_value), 0, MAX_UPGRADE_LEVEL)]

func diamond_multiplier() -> int:
	return DIAMOND_MULTIPLIERS[clampi(int(levels.diamond_value), 0, MAX_UPGRADE_LEVEL)]

func diamond_lifetime() -> float:
	return diamond_lifetime_for(int(levels.diamond_lifetime))

static func diamond_lifetime_for(level: int) -> float:
	return DIAMOND_LIFETIMES[clampi(level, 0, MAX_UPGRADE_LEVEL)]

func reward_value(base_value: int, diamond: bool) -> int:
	return base_value * (diamond_multiplier() if diamond else coin_multiplier())

func idle_limit() -> float:
	return idle_limit_for(int(levels.idle_duration))

static func idle_limit_for(level: int) -> float:
	return IDLE_LIMITS[clampi(level, 0, MAX_UPGRADE_LEVEL)]

func bubble_capacity() -> int:
	return BUBBLE_CAPACITIES[clampi(int(levels.bubble_capacity), 0, MAX_UPGRADE_LEVEL)]

func bubble_multiplier() -> float:
	return BUBBLE_MULTIPLIERS[clampi(int(levels.bubble_value), 0, MAX_UPGRADE_LEVEL)]

func restock(tier: int, feeds: Array[FeedProfile], economy: Economy) -> bool:
	if not owned.feeder or tier < 0 or tier >= feeds.size():
		return false
	var count: int = mini(20, CAPACITY - reserve.size())
	if count <= 0 or not economy.spend(count * feeds[tier].price):
		return false
	for i in range(count):
		reserve.append(tier)
	return true
