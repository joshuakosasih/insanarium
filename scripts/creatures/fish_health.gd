class_name FishHealth
extends RefCounted
## General condition pool. Water quality is its first damage source; combat and disease can reuse it later.
const MAX_HEALTH: float = 100.0
const MAX_POSSIBLE_HEALTH: float = 160.0
const CLEAR_RECOVERY_RATE: float = 0.05
const PRISTINE_RECOVERY_RATE: float = 0.25
const DAMAGE_THRESHOLD: float = 65.0
const DAMAGE_BASE_RATE: float = 0.015
const DAMAGE_GROWTH_PER_10_POINTS: float = 3.0
var current: float = MAX_HEALTH
var maximum: float = MAX_HEALTH

func configure_maximum(value: float, fill: bool = false) -> void:
	maximum = clampf(value, 1.0, MAX_POSSIBLE_HEALTH)
	current = maximum if fill else clampf(current, 0.0, maximum)

func advance(delta: float, cleanliness: float, constitution: float = 1.0, well_fed: bool = true) -> bool:
	var rate := rate_for_conditions(cleanliness, well_fed)
	constitution = clampf(constitution, 0.5, 2.0)
	rate = rate * constitution if rate >= 0.0 else rate / constitution
	current = clampf(current + rate * maxf(0.0, delta), 0.0, maximum)
	return current <= 0.0

static func rate_for_cleanliness(cleanliness: float) -> float:
	return rate_for_conditions(cleanliness, true)

static func rate_for_conditions(cleanliness: float, well_fed: bool) -> float:
	if cleanliness >= DAMAGE_THRESHOLD:
		if not well_fed:
			return 0.0
		var pristine_progress: float = clampf((cleanliness - DAMAGE_THRESHOLD) / 20.0, 0.0, 1.0)
		return lerpf(CLEAR_RECOVERY_RATE, PRISTINE_RECOVERY_RATE, pristine_progress)
	# Damage rises geometrically for every ten cleanliness points lost. Subtracting
	# one keeps the transition just below 65% continuous instead of applying a sudden hit.
	var depth: float = (DAMAGE_THRESHOLD - clampf(cleanliness, 0.0, DAMAGE_THRESHOLD)) / 10.0
	return -DAMAGE_BASE_RATE * (pow(DAMAGE_GROWTH_PER_10_POINTS, depth) - 1.0)
