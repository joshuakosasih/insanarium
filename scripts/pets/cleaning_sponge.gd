class_name CleaningSpongePet
extends Node2D
const VectorArt = preload("res://scripts/art/aquarium_vector_art.gd")
var phase: float = 0.0
var presentation_scale: float = 1.0

func _ready() -> void:
	add_to_group("pets")
	scale = Vector2.ONE * presentation_scale
	# Its sibling order places it over the painted habitat and behind tank life.
	z_index = 0

func _process(delta: float) -> void:
	phase += delta * ActivityPace.multiplier
	queue_redraw()

func _draw() -> void:
	VectorArt.draw_sponge(self, Vector2.ZERO, 1.0, phase)
