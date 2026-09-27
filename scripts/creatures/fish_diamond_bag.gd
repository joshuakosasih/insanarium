class_name FishDiamondBag
extends RefCounted
## One Diamond outcome per four eligible guppies; unspent draws persist.
const CONTENTS := [0, 0, 0, 1]
var remaining: Array[int] = []
var rng := RandomNumberGenerator.new()

func _init() -> void:
	rng.randomize()

func draw() -> bool:
	return draw_with_rng(rng)

func draw_with_rng(source: RandomNumberGenerator) -> bool:
	if remaining.is_empty():
		remaining.assign(CONTENTS)
	var index: int = source.randi_range(0, remaining.size() - 1)
	return remaining.pop_at(index) == 1

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
