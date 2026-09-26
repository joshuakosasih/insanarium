class_name FishSexBag
extends RefCounted
## Purchases and births draw without replacement; a new bag starts after nine guppies.
const CONTENTS := [0, 0, 0, 1, 1, 1, 2, 2, 2]
var remaining: Array[int] = []
var rng := RandomNumberGenerator.new()

func _init() -> void:
	rng.randomize()

func draw() -> AquariumFish.Sex:
	if remaining.is_empty():
		remaining.assign(CONTENTS)
	var index: int = rng.randi_range(0, remaining.size() - 1)
	return remaining.pop_at(index) as AquariumFish.Sex

func to_data() -> Array[int]:
	return remaining.duplicate()

func from_data(value: Variant) -> void:
	remaining.clear()
	if not value is Array or value.size() > CONTENTS.size():
		return
	var available: Array[int] = []
	available.assign(CONTENTS)
	for item in value:
		if not (item is int or item is float) or float(item) != floorf(float(item)) or not available.has(int(item)):
			remaining.clear()
			return
		available.erase(int(item))
		remaining.append(int(item))
