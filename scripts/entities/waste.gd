class_name FishWaste
extends Node2D
## Visible organic waste with a fixed floor lifetime and manual-cleaning opportunity.
const FLOOR_LIFETIME: float = 12.0
const FADE_DURATION: float = 2.0
var floor_y: float = 642.0
var settled: bool = false
var lifetime: float = FLOOR_LIFETIME

func _ready() -> void:
	add_to_group("waste")

func _process(delta: float) -> void:
	delta *= ActivityPace.multiplier
	if settled:
		lifetime -= delta
		if lifetime <= 0.0:
			remove_from_group("waste")
			queue_free()
			return
		modulate.a = 1.0 if lifetime > FADE_DURATION else pow(clampf(lifetime / FADE_DURATION, 0.0, 1.0), 2.0)
		return
	position.y = minf(position.y + 24.0 * delta, floor_y)
	if position.y >= floor_y:
		settled = true
	modulate.a = 1.0
	queue_redraw()

func _draw() -> void:
	var sway: float = sin(position.y * 0.08) * 1.2
	draw_circle(Vector2(-5, 2), 4.5, Color("66513c"))
	draw_circle(Vector2(sway, -1), 5.0, Color("795f43"))
	draw_circle(Vector2(5, 2), 4.0, Color("5b4938"))
	draw_circle(Vector2(-1, -3), 1.3, Color("a1845c"))
