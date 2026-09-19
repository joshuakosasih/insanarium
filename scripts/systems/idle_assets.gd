class_name IdleAssets
extends RefCounted
## Owned automation and stocked pellet tiers. Purchases are once per tank.
const PRICES := {"snail": 150, "seahorse": 250, "puffer": 300, "feeder": 200}
const UPGRADE_PRICES := [100, 190, 360, 690]
const SNAIL_SPEEDS := [16.0, 22.0, 30.0, 41.0, 55.0]
const SNAIL_STAMINAS := [10.0, 16.0, 25.0, 40.0, 60.0]
const SNAIL_SLEEPS := [20.0, 15.0, 11.0, 8.0, 5.0]
const PUFFER_SPEEDS := [45.0, 60.0, 78.0, 100.0, 125.0]
const PUFFER_CURIOSITIES := [0.30, 0.45, 0.60, 0.80, 1.0]
const COIN_LIFETIMES := [8.0, 15.0, 25.0, 45.0, 75.0]
const MAX_UPGRADE_LEVEL: int = 4
var owned: Dictionary = {"snail": false, "seahorse": false, "puffer": false, "feeder": false}
var levels: Dictionary = {"snail_speed": 0, "snail_stamina": 0, "snail_sleep": 0, "puffer_speed": 0, "puffer_curiosity": 0, "coin_lifetime": 0}
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
	var level: int = int(levels[track])
	return UPGRADE_PRICES[level] if level < MAX_UPGRADE_LEVEL else 0

func upgrade(track: String, economy: Economy) -> bool:
	var price := upgrade_price(track)
	if price == 0 or not economy.spend(price):
		return false
	levels[track] = int(levels[track]) + 1
	return true

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

func coin_lifetime() -> float:
	return coin_lifetime_for(int(levels.coin_lifetime))

static func coin_lifetime_for(level: int) -> float:
	return COIN_LIFETIMES[clampi(level, 0, MAX_UPGRADE_LEVEL)]

func restock(tier: int, feeds: Array[FeedProfile], economy: Economy) -> bool:
	if not owned.feeder or tier < 0 or tier >= feeds.size():
		return false
	var count: int = mini(20, CAPACITY - reserve.size())
	if count <= 0 or not economy.spend(count * feeds[tier].price):
		return false
	for i in range(count):
		reserve.append(tier)
	return true
