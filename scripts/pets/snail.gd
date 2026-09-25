class_name SnailPet
extends Node2D
const VectorArt = preload("res://scripts/art/aquarium_vector_art.gd")
## Collects eligible rewards through their normal single-claim path.
@export var crawl_speed: float = 16.0
@export var max_stamina: float = 10.0
var stamina_left: float = 10.0
var sleep_left: float = 0.0
var sleep_duration: float = 20.0
var horizontal_bounds := Vector2(85, 1067)
var presentation_scale: float = 1.0
const HIT_RADIUS: float = 40.0

func _ready() -> void:
	add_to_group("pets")
	scale = Vector2.ONE * presentation_scale
	apply_upgrades(0, 0, 0)

func apply_upgrades(speed_level: int, stamina_level: int, sleep_level: int) -> void:
	crawl_speed = IdleAssets.SNAIL_SPEEDS[clampi(speed_level, 0, IdleAssets.MAX_UPGRADE_LEVEL)]
	max_stamina = IdleAssets.SNAIL_STAMINAS[clampi(stamina_level, 0, IdleAssets.MAX_UPGRADE_LEVEL)]
	sleep_duration = IdleAssets.SNAIL_SLEEPS[clampi(sleep_level, 0, IdleAssets.MAX_UPGRADE_LEVEL)]
	stamina_left = max_stamina
	sleep_left = 0.0

func _process(delta: float) -> void:
	delta *= ActivityPace.multiplier
	if sleep_left > 0.0:
		sleep_left = maxf(0.0, sleep_left - delta)
		if sleep_left <= 0.0:
			stamina_left = max_stamina
		queue_redraw()
		return
	var target: TankCoin
	var nearest: float = INF
	for coin in get_tree().get_nodes_in_group("coins"):
		if coin.claimed or coin.is_queued_for_deletion() or coin.position.y < coin.floor_y - 1.0:
			continue
		var distance: float = absf(coin.position.x - position.x)
		if distance < nearest:
			nearest = distance
			target = coin
	if target == null:
		return
	var direction: float = target.position.x - position.x
	if absf(direction) > 2.0:
		scale.x = signf(direction) * presentation_scale
		position.x = clampf(move_toward(position.x, target.position.x, crawl_speed * delta), horizontal_bounds.x, horizontal_bounds.y)
		stamina_left = maxf(0.0, stamina_left - delta)
	if absf(position.x - target.position.x) <= 20.0:
		target.collect()
	elif stamina_left <= 0.0:
		sleep_left = sleep_duration
	queue_redraw()

func wake_up() -> bool:
	if sleep_left <= 0.0:
		return false
	sleep_left = 0.0
	stamina_left = max_stamina
	queue_redraw()
	return true

func _draw() -> void:
	VectorArt.draw_snail(self, Vector2.ZERO, 1.0, sleep_left > 0.0)
	if sleep_left > 0.0:
		draw_string(ThemeDB.fallback_font, Vector2(-4, -48), "Z", HORIZONTAL_ALIGNMENT_CENTER, 20, 14, Color("d5ebef"))
		draw_string(ThemeDB.fallback_font, Vector2(12, -59), "z", HORIZONTAL_ALIGNMENT_CENTER, 16, 11, Color("83a9b7"))
