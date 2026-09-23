class_name WaterQualityOverlay
extends Node2D
## A foreground haze makes declining cleanliness visible across tank inhabitants.
const AREA := Rect2(50, 168, 1052, 480)
var area := AREA
var cleanliness: float = 100.0

func set_area(value: Rect2) -> void:
	area = value
	queue_redraw()

func set_cleanliness(value: float) -> void:
	cleanliness = clampf(value, 0.0, 100.0)
	queue_redraw()

static func murk_strength(value: float) -> float:
	return clampf((85.0 - value) / 85.0, 0.0, 1.0)

func _draw() -> void:
	var murk: float = murk_strength(cleanliness)
	if murk <= 0.0:
		return
	# Green-brown water and pale haze obscure the inhabitants progressively.
	draw_rect(area, Color(0.24, 0.26, 0.10, murk * 0.27))
	draw_rect(area, Color(0.68, 0.72, 0.55, murk * 0.07))
	var particle_count: int = ceili(42.0 * murk)
	for i in range(particle_count):
		var x: float = area.position.x + 14.0 + fmod(i * 193.0, area.size.x - 28.0)
		var y: float = area.position.y + 10.0 + fmod(i * 107.0, area.size.y - 20.0)
		var radius: float = 1.2 + float(i % 4) * 0.55
		draw_circle(Vector2(x, y), radius, Color(0.77, 0.76, 0.50, murk * 0.34))
