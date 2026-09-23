class_name BubblePufferPet
extends Node2D
const VectorArt = preload("res://scripts/art/aquarium_vector_art.gd")
## Active-play pet: wanders freely, then chases bubbles accepted by a curiosity roll.
@export var move_speed: float = 45.0
@export var curiosity: float = 0.30
var bounds := Rect2(110, 220, 932, 370)
var destination := Vector2(760, 420)
var wander_left: float = 0.0
var puff_left: float = 0.0
var target_bubble: IncomeBubble
var seen_bubbles: Dictionary = {}
var phase: float = 0.0
var rng := RandomNumberGenerator.new()
var presentation_scale: float = 1.0
const CONTACT_RADIUS: float = 22.0
const PUFF_DURATION: float = 0.7

func _ready() -> void:
	add_to_group("pets")
	scale = Vector2.ONE * presentation_scale
	rng.randomize()
	destination = position
	z_index = 4

func apply_upgrades(speed_level: int, curiosity_level: int) -> void:
	move_speed = IdleAssets.PUFFER_SPEEDS[clampi(speed_level, 0, IdleAssets.MAX_UPGRADE_LEVEL)]
	curiosity = IdleAssets.PUFFER_CURIOSITIES[clampi(curiosity_level, 0, IdleAssets.MAX_UPGRADE_LEVEL)]

func _process(delta: float) -> void:
	if ActivityPace.multiplier < 1.0:
		return
	phase += delta
	puff_left = maxf(0.0, puff_left - delta)
	consider_new_bubbles()
	if is_instance_valid(target_bubble) and not target_bubble.claimed and not target_bubble.is_queued_for_deletion():
		destination = target_bubble.position
		move_toward_point(destination, delta)
		if position.distance_to(target_bubble.position) <= CONTACT_RADIUS * presentation_scale + target_bubble.RADIUS * absf(target_bubble.scale.x):
			target_bubble.pop()
			target_bubble = null
			puff_left = PUFF_DURATION
	else:
		target_bubble = null
		wander_left -= delta
		if wander_left <= 0.0 or position.distance_to(destination) < 8.0:
			wander_left = rng.randf_range(1.5, 4.0)
			destination = Vector2(rng.randf_range(bounds.position.x, bounds.end.x), rng.randf_range(bounds.position.y, bounds.end.y))
		move_toward_point(destination, delta)
	queue_redraw()

func consider_new_bubbles() -> void:
	var live: Dictionary = {}
	for bubble in get_tree().get_nodes_in_group("income_bubbles"):
		var bubble_id: int = bubble.get_instance_id()
		live[bubble_id] = true
		if target_bubble == null and not seen_bubbles.has(bubble_id):
			seen_bubbles[bubble_id] = true
			if rng.randf() <= curiosity:
				target_bubble = bubble
	for bubble_id in seen_bubbles.keys():
		if not live.has(bubble_id):
			seen_bubbles.erase(bubble_id)

func move_toward_point(point: Vector2, delta: float) -> void:
	var direction: Vector2 = point - position
	if absf(direction.x) > 1.0:
		scale.x = signf(direction.x) * presentation_scale
	position = position.move_toward(point.clamp(bounds.position, bounds.end), move_speed * delta)

func _draw() -> void:
	VectorArt.draw_puffer(self, Vector2.ZERO, 1.0, puff_left > 0.0, phase)
