class_name FishSurvival
extends RefCounted
## Tracks consecutive time at maximum hunger, independently of growth.
var starving_for: float = 0.0

func advance(hunger: float, delta: float, grace: float) -> bool:
	if hunger >= 1.0:
		starving_for += delta
	else:
		starving_for = 0.0
	return starving_for >= grace

func fed() -> void:
	starving_for = 0.0
