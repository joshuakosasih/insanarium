class_name TankEnvironment
extends RefCounted
## Small data-only water-quality model shared by active and offline simulation.
const MAX_CLEANLINESS: float = 100.0
const BIOLOAD_PER_CREATURE: float = 0.0003
const WASTE_PER_SECOND: float = 0.0005
const WASTE_OUTPUT_POLLUTION: float = 0.35
const SPOILED_PELLET_POLLUTION: float = 1.5
const CLEANED_WASTE_RECOVERY: float = 0.75
const SHRIMP_WASTE_RECOVERY: float = 0.35
const FULL_CLEAN_COST: float = 25.0
const FULL_CLEAN_THRESHOLD: float = 99.0
var cleanliness: float = MAX_CLEANLINESS

func advance(delta: float, creature_count: int, waste_count: int) -> void:
	pollute(delta * (maxi(0, creature_count) * BIOLOAD_PER_CREATURE + maxi(0, waste_count) * WASTE_PER_SECOND))

func pollute(amount: float) -> void:
	cleanliness = clampf(cleanliness - maxf(0.0, amount), 0.0, MAX_CLEANLINESS)

func clean(amount: float) -> void:
	cleanliness = clampf(cleanliness + maxf(0.0, amount), 0.0, MAX_CLEANLINESS)

func full_clean() -> void:
	cleanliness = MAX_CLEANLINESS

func condition() -> String:
	if cleanliness >= 85.0:
		return "PRISTINE"
	if cleanliness >= 65.0:
		return "CLEAR"
	if cleanliness >= 40.0:
		return "CLOUDY"
	if cleanliness >= 20.0:
		return "DIRTY"
	return "TOXIC"

func color() -> Color:
	if cleanliness >= 65.0:
		return Color("8edfe9")
	if cleanliness >= 40.0:
		return Color("ffdb80")
	return Color("ffa86b") if cleanliness >= 20.0 else Color("ff657f")
