class_name SeahorsePet
extends Node2D
const VectorArt = preload("res://scripts/art/aquarium_vector_art.gd")
## Supplies food through a signal; does not own food spawning or the wallet.
signal feed_produced(at: Vector2)
@export var feed_interval: float = 8.0
var feed_left: float = 8.0
var phase: float = 0.0
var anchor := Vector2(180, 320)
var presentation_scale: float = 1.0

func _ready() -> void:
	add_to_group("pets")
	scale = Vector2.ONE * presentation_scale
	position = anchor

func _process(delta: float) -> void:
	delta *= ActivityPace.multiplier
	phase += delta
	position = anchor + Vector2(sin(phase * 0.4) * 35, sin(phase * 1.4) * 12)
	feed_left -= delta
	if feed_left <= 0.0:
		feed_left = feed_interval
		for fish in get_tree().get_nodes_in_group("fish"):
			if fish.hunger >= fish.profile.hungry_threshold:
				feed_produced.emit(position + Vector2(34, -22))
				break
	queue_redraw()

func _draw() -> void:
	VectorArt.draw_seahorse(self, Vector2.ZERO, 1.0, phase)
