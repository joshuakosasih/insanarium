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
var threatens_piranhas: bool = false
var wander_destination := Vector2.ZERO
var wander_left: float = 0.0

func _ready() -> void:
	if threatens_piranhas:
		max_health = 16
		chase_speed = 112.0
	health = max_health
	z_index = 10
	add_to_group("invaders")
	choose_wander_destination()

func choose_wander_destination() -> void:
	wander_destination = Vector2(randf_range(bounds.position.x, bounds.end.x), randf_range(bounds.position.y, bounds.end.y))
	wander_left = randf_range(2.0, 4.0)

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
	return (Rect2(-69, -78, 138, 132) if threatens_piranhas else Rect2(-52, -64, 104, 108)).has_point(local_point)

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
		if fish.dead or fish.is_queued_for_deletion() or (fish.can_fight_alien() and not threatens_piranhas):
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
	else:
		wander_left -= delta
		if wander_left <= 0.0 or position.distance_to(wander_destination) < 15.0:
			choose_wander_destination()
		position = position.move_toward(wander_destination, chase_speed * 0.55 * delta).clamp(bounds.position, bounds.end)
	queue_redraw()

func _draw() -> void:
	if threatens_piranhas:
		draw_hunter()
		return
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

func draw_hunter() -> void:
	var shell := Color("476f9d") if hit_flash <= 0.0 else Color("d8efff")
	var outline := Color("182d47")
	var shadow := Color("294b72")
	# The same broad head, two ears, and side arms as its smaller blue sibling,
	# exaggerated into horns, heavy claws, and an angular jaw.
	for side in [-1.0, 1.0]:
		draw_colored_polygon(PackedVector2Array([Vector2(side * 43, -11), Vector2(side * 57, -24), Vector2(side * 54, 7), Vector2(side * 65, 19), Vector2(side * 57, 35), Vector2(side * 42, 27)]), outline)
		draw_colored_polygon(PackedVector2Array([Vector2(side * 50, 14), Vector2(side * 63, 14), Vector2(side * 58, 22)]), Color("df7483"))
	var head_outline := PackedVector2Array([Vector2(-48, -25), Vector2(-42, -49), Vector2(-29, -39), Vector2(-19, -62), Vector2(-6, -45), Vector2(6, -45), Vector2(19, -62), Vector2(29, -39), Vector2(42, -49), Vector2(48, -25), Vector2(48, 29), Vector2(33, 46), Vector2(-33, 46), Vector2(-48, 29)])
	draw_colored_polygon(head_outline, outline)
	var head := PackedVector2Array([Vector2(-43, -23), Vector2(-37, -42), Vector2(-27, -33), Vector2(-18, -52), Vector2(-5, -40), Vector2(5, -40), Vector2(18, -52), Vector2(27, -33), Vector2(37, -42), Vector2(43, -23), Vector2(43, 27), Vector2(30, 41), Vector2(-30, 41), Vector2(-43, 27)])
	draw_colored_polygon(head, shell)
	draw_colored_polygon(PackedVector2Array([Vector2(-39, -24), Vector2(-27, -33), Vector2(-18, -52), Vector2(-5, -40), Vector2(5, -40), Vector2(18, -52), Vector2(27, -33), Vector2(39, -24), Vector2(28, -27), Vector2(0, -19), Vector2(-28, -27)]), shadow)
	for x in [-21.0, 21.0]:
		draw_circle(Vector2(x, -7), 13, Color("eff8ff"))
		draw_circle(Vector2(x, -6), 7, Color("e46c79"))
		draw_circle(Vector2(x, -5), 3, outline)
	# Slanted brows and a toothy squared mouth make its threat readable at game scale.
	draw_line(Vector2(-37, -23), Vector2(-9, -15), outline, 5, true)
	draw_line(Vector2(37, -23), Vector2(9, -15), outline, 5, true)
	draw_colored_polygon(PackedVector2Array([Vector2(-30, 14), Vector2(-22, 20), Vector2(22, 20), Vector2(30, 14), Vector2(28, 33), Vector2(-28, 33)]), outline)
	for x in [-21.0, -9.0, 3.0, 15.0]:
		draw_colored_polygon(PackedVector2Array([Vector2(x, 20), Vector2(x + 8, 20), Vector2(x + 4, 28)]), Color("f0f8fb"))
	for i in range(max_health):
		draw_rect(Rect2(-40 + i * 5, -73, 4, 5), Color("e97889") if i < health else Color("344958"))
