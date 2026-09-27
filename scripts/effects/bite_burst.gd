class_name BiteBurst
extends Node2D
## Brief stylized crimson splash when a piranha catches prey.
const DURATION: float = 0.38
var elapsed: float = 0.0

func _process(delta: float) -> void:
	elapsed += delta * ActivityPace.multiplier
	if elapsed >= DURATION:
		queue_free()
	else:
		queue_redraw()

func _draw() -> void:
	var progress: float = clampf(elapsed / DURATION, 0.0, 1.0)
	var fade: float = 1.0 - progress
	draw_arc(Vector2.ZERO, 6.0 + progress * 24.0, 0.0, TAU, 24, Color(1.0, 0.85, 0.8, fade * 0.75), 2.0, true)
	for index in range(7):
		var angle: float = index * TAU / 7.0 + 0.3
		var direction := Vector2.from_angle(angle)
		var travel: float = (10.0 + float(index % 3) * 4.0) * progress
		draw_circle(direction * travel, (2.8 - progress * 1.6) * (0.8 + float(index % 2) * 0.2), Color(0.83, 0.21, 0.28, fade * 0.85))
