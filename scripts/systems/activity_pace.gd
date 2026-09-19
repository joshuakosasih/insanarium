class_name ActivityPace
extends RefCounted
## Shared simulation clock. Focus changes never reset biological timers.
const IDLE_RATE: float = 0.1
static var multiplier: float = 1.0

static func set_idle(idle: bool) -> void:
	multiplier = IDLE_RATE if idle else 1.0
