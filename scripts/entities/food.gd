class_name FishFood
extends Node2D
const VectorArt = preload("res://scripts/art/aquarium_vector_art.gd")
signal expired(at: Vector2)
@export var lifetime: float = 14.0
const FALL_SPEED: float = 25.0
const MAX_LIFETIME: float = 14.0
var floor_y: float = 640.0
var settled: bool = false
var consumed: bool = false
var profile: FeedProfile = FeedProfile.new()

func _ready() -> void:
	add_to_group("food")

func _process(delta: float) -> void:
	delta *= ActivityPace.multiplier
	if settled:
		lifetime -= delta
	else:
		var fall_time: float = maxf(0.0, floor_y - position.y) / FALL_SPEED
		position.y = minf(position.y + FALL_SPEED * delta, floor_y)
		if position.y >= floor_y:
			settled = true
			lifetime -= maxf(0.0, delta - fall_time)
	modulate.a = clampf(lifetime / 2.0, 0.0, 1.0)
	if lifetime <= 0.0:
		remove_from_group("food")
		expired.emit(position)
		queue_free()

func consume() -> bool:
	if consumed or is_queued_for_deletion():
		return false
	consumed = true
	remove_from_group("food")
	queue_free()
	return true

func _draw() -> void:
	VectorArt.draw_pellet(self, Vector2.ZERO, profile.growth_credit, profile.color)
