class_name CleanupShrimpPet
extends Node2D
const VectorArt = preload("res://scripts/art/aquarium_vector_art.gd")
## Bottom-dwelling helper that intercepts settled waste and expiring pellets.
signal waste_eaten(waste: FishWaste)
signal pellet_eaten(at: Vector2)
const CONTACT_DISTANCE: float = 18.0
const PELLET_RESCUE_TIME: float = 6.0
@export var move_speed: float = 30.0
@export var digestion_duration: float = 12.0
var digestion_left: float = 0.0
var horizontal_bounds := Vector2(85, 1067)
var floor_y: float = 635.0
var destination_x: float = 550.0
var wander_left: float = 0.0
var target: Node2D
var phase: float = 0.0
var presentation_scale: float = 1.0
var rng := RandomNumberGenerator.new()

func _ready() -> void:
	add_to_group("pets")
	rng.randomize()
	scale = Vector2(-presentation_scale, presentation_scale)
	position.y = floor_y
	destination_x = position.x
	z_index = 4

func apply_upgrades(speed_level: int, digestion_level: int) -> void:
	move_speed = IdleAssets.SHRIMP_SPEEDS[clampi(speed_level, 0, IdleAssets.MAX_UPGRADE_LEVEL)]
	digestion_duration = IdleAssets.SHRIMP_DIGESTION[clampi(digestion_level, 0, IdleAssets.MAX_UPGRADE_LEVEL)]
	digestion_left = minf(digestion_left, digestion_duration)

func _process(delta: float) -> void:
	delta *= ActivityPace.multiplier
	phase += delta
	position.y = floor_y
	if digestion_left > 0.0:
		digestion_left = maxf(0.0, digestion_left - delta)
		queue_redraw()
		return
	if not valid_target():
		target = nearest_cleanup_target()
	if target != null:
		destination_x = target.position.x
		move_horizontally(delta)
		if absf(position.x - target.position.x) <= CONTACT_DISTANCE:
			consume_target()
	else:
		wander_left -= delta
		if wander_left <= 0.0 or absf(position.x - destination_x) < 3.0:
			wander_left = rng.randf_range(2.0, 5.0)
			destination_x = rng.randf_range(horizontal_bounds.x, horizontal_bounds.y)
		move_horizontally(delta * 0.35)
	queue_redraw()

func valid_target() -> bool:
	if not is_instance_valid(target) or target.is_queued_for_deletion():
		return false
	if target is FishWaste:
		return target.settled
	if target is FishFood:
		return not target.consumed and target.lifetime <= PELLET_RESCUE_TIME and target.position.y >= target.floor_y - 2.0
	return false

func nearest_cleanup_target() -> Node2D:
	var nearest: Node2D
	var nearest_distance: float = INF
	for waste in get_tree().get_nodes_in_group("waste"):
		if waste.settled and not waste.is_queued_for_deletion():
			var distance: float = absf(waste.position.x - position.x)
			if distance < nearest_distance:
				nearest = waste
				nearest_distance = distance
	for food in get_tree().get_nodes_in_group("food"):
		if not food.consumed and food.lifetime <= PELLET_RESCUE_TIME and food.position.y >= food.floor_y - 2.0:
			var distance: float = absf(food.position.x - position.x)
			if distance < nearest_distance:
				nearest = food
				nearest_distance = distance
	return nearest

func move_horizontally(delta: float) -> void:
	var direction: float = destination_x - position.x
	if absf(direction) > 1.0:
		scale.x = -signf(direction) * presentation_scale
	position.x = clampf(move_toward(position.x, destination_x, move_speed * delta), horizontal_bounds.x, horizontal_bounds.y)

func consume_target() -> void:
	var meal := target
	target = null
	if meal is FishWaste:
		waste_eaten.emit(meal)
	elif meal is FishFood and meal.consume():
		pellet_eaten.emit(meal.position)
	digestion_left = digestion_duration

func _draw() -> void:
	# Deliberately much smaller than the snail: this helper is a shrimp, not a lobster.
	VectorArt.draw_shrimp(self, Vector2.ZERO, 0.58, phase)
	if digestion_left > 0.0:
		draw_circle(Vector2(1, -23), 2.0, Color("d5ebef"))
		draw_circle(Vector2(9, -29), 1.3, Color("83a9b7"))
