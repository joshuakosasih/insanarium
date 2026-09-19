class_name FishLife
extends RefCounted
## Identity and history are independent of appearance, condition, and behavior.
var id: String = ""
var parent_ids: PackedStringArray = PackedStringArray()
var age_seconds: float = 0.0
var birth_sim_time: float = 0.0
var age_known: bool = true
var origin: String = "Purchased"

func to_data() -> Dictionary:
	return {"id": id, "parents": Array(parent_ids), "age": age_seconds,
		"born_at": birth_sim_time, "age_known": age_known, "origin": origin}

func from_data(data: Dictionary) -> void:
	id = str(data.get("id", ""))
	parent_ids = PackedStringArray(data.get("parents", []).slice(0, 2))
	age_seconds = maxf(0.0, float(data.get("age", 0)))
	birth_sim_time = float(data.get("born_at", -1))
	age_known = bool(data.get("age_known", false))
	origin = str(data.get("origin", "Legacy"))
