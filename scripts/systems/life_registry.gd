class_name LifeRegistry
extends RefCounted
## Monotonic IDs are never recycled, even when an animal is sold or dies.
var next_id: int = 1
var elapsed: float = 0.0

func allocate(life: FishLife, origin: String = "Purchased") -> void:
	life.id = "F%06d" % next_id
	next_id += 1
	life.origin = origin
	life.birth_sim_time = elapsed

func reserve(id: String) -> void:
	if id.begins_with("F") and id.substr(1).is_valid_int():
		next_id = maxi(next_id, int(id.substr(1)) + 1)
