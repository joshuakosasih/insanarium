class_name IncomeBubble
extends Node2D
signal popped(value: float)
var value: float = 1
var lifetime: float = 30.0
var claimed: bool = false
var phase: float = 0.0
const SURFACE_Y: float = 179.0
const HIT_RADIUS: float = 22.0
const RADIUS: float = 11.0

func _ready() -> void:
	add_to_group("income_bubbles")
	z_index = 5

func _process(delta: float) -> void:
	if ActivityPace.multiplier < 1.0:
		return
	lifetime -= delta
	phase += delta
	position.y -= 20.0 * delta
	position.x += sin(phase * 2.0) * 5.0 * delta
	modulate.a = minf(1.0, lifetime)
	if lifetime <= 0.0 or position.y <= SURFACE_Y:
		queue_free()

func pop() -> void:
	if claimed or lifetime <= 0.0 or position.y <= SURFACE_Y or is_queued_for_deletion():
		return
	claimed = true
	remove_from_group("income_bubbles")
	popped.emit(value)
	queue_free()

func _draw() -> void:
	draw_circle(Vector2.ZERO, RADIUS, Color(0.35, 0.8, 0.9, 0.14))
	draw_arc(Vector2.ZERO, RADIUS, 0, TAU, 48, Color("8edfe9"), 2.0, true)
	draw_arc(Vector2(-1, -1), 7, PI, PI * 1.5, 16, Color("e0ffff"), 2.0, true)
