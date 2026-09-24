class_name TankAlien
extends Node2D
## Original Godot-inspired robot alien. Click impacts apply knockback without a stun.
signal defeated(at: Vector2)
@export var max_health: int = 8
@export var chase_speed: float = 90.0
var health: int = 8
var bounds := Rect2(98, 218, 956, 410)
var knockback := Vector2.ZERO
var hit_flash: float = 0.0
var attack_left: float = 0.0
var dead: bool = false

func _ready() -> void:
	health = max_health
	z_index = 10
	add_to_group("invaders")

func hit(at: Vector2) -> void:
	if dead:
		return
	health -= 1
	if health <= 0:
		dead = true
		remove_from_group("invaders")
		defeated.emit(position)
		queue_free()
		return
	var direction := (position - at).normalized()
	if direction.is_zero_approx():
		direction = Vector2.UP
	knockback = direction * 300.0
	hit_flash = 0.12
	queue_redraw()

func contains_point(tank_point: Vector2) -> bool:
	# Include the health bar and side arms so every visible part consumes the tap.
	var local_point := (tank_point - position) / scale
	return Rect2(-52, -64, 104, 108).has_point(local_point)

func _process(delta: float) -> void:
	delta *= ActivityPace.multiplier
	if dead:
		return
	attack_left = maxf(0.0, attack_left - delta)
	hit_flash = maxf(0.0, hit_flash - delta)
	# Chase remains active while impact velocity decays; no post-hit pause.
	position = (position + knockback * delta).clamp(bounds.position, bounds.end)
	knockback = knockback.move_toward(Vector2.ZERO, 600 * delta)
	var target: AquariumFish
	var nearest: float = INF
	for fish in get_tree().get_nodes_in_group("fish"):
		if fish.dead or fish.is_queued_for_deletion():
			continue
		var distance: float = position.distance_to(fish.position)
		if distance < nearest:
			nearest = distance
			target = fish
	if target != null:
		position = position.move_toward(target.position, chase_speed * delta).clamp(bounds.position, bounds.end)
		if position.distance_to(target.position) < 38.0 and attack_left <= 0.0:
			target.die("Alien attack")
			attack_left = 2.0
	queue_redraw()

func _draw() -> void:
	var blue := Color("76b7e1") if hit_flash <= 0.0 else Color("e0f7ff")
	var head := PackedVector2Array([Vector2(-36, -20), Vector2(-30, -34), Vector2(-18, -29), Vector2(-13, -41), Vector2(-3, -36), Vector2(3, -36), Vector2(13, -41), Vector2(18, -29), Vector2(30, -34), Vector2(36, -20), Vector2(36, 25), Vector2(24, 35), Vector2(-24, 35), Vector2(-36, 25)])
	draw_colored_polygon(head, blue)
	draw_rect(Rect2(-44, -10, 9, 25), blue.darkened(0.25))
	draw_rect(Rect2(35, -10, 9, 25), blue.darkened(0.25))
	for x in [-17.0, 17.0]:
		draw_circle(Vector2(x, -8), 11, Color("f4fbff"))
		draw_circle(Vector2(x, -7), 5, Color("e35b79"))
	draw_polyline(PackedVector2Array([Vector2(-27, 15), Vector2(-14, 15), Vector2(-14, 22), Vector2(14, 22), Vector2(14, 15), Vector2(27, 15)]), Color("f4fbff"), 5, true)
	for i in range(max_health):
		draw_rect(Rect2(-35 + i * 9, -55, 7, 5), Color("f28d9f") if i < health else Color("344958"))
