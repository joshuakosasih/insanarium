class_name SeahorsePet
extends Node2D
const VectorArt = preload("res://scripts/art/aquarium_vector_art.gd")
## Supplies food through a signal; does not own food spawning or the wallet.
signal feed_produced(at: Vector2, tier: int)
@export var feed_interval: float = 18.0
var feed_left: float = 18.0
var feed_tier: int = 0
var phase: float = 0.0
var anchor := Vector2(570, 320)
var roam_width: float = 245.0
var served_hungry_ids: Array[String] = []
var presentation_scale: float = 1.0

func _ready() -> void:
	add_to_group("pets")
	scale = Vector2.ONE * presentation_scale
	position = anchor
	apply_upgrades(0, 0)

func apply_upgrades(interval_level: int, quality_level: int) -> void:
	var old_interval := feed_interval
	feed_interval = IdleAssets.SEAHORSE_INTERVALS[clampi(interval_level, 0, IdleAssets.SEAHORSE_INTERVALS.size() - 1)]
	feed_tier = IdleAssets.SEAHORSE_FEED_TIERS[clampi(quality_level, 0, IdleAssets.SEAHORSE_FEED_TIERS.size() - 1)]
	feed_left = minf(feed_left * feed_interval / maxf(old_interval, 0.01), feed_interval)
	queue_redraw()

func charge_progress() -> float:
	return 1.0 - clampf(feed_left / maxf(feed_interval, 0.01), 0.0, 1.0)

func _process(delta: float) -> void:
	delta *= ActivityPace.multiplier
	phase += delta
	position = anchor + Vector2(sin(phase * 0.16) * roam_width, sin(phase * 0.58) * 22)
	feed_left = maxf(0.0, feed_left - delta)
	var hungry_ids: Array[String] = []
	var candidate: AquariumFish
	for fish in get_tree().get_nodes_in_group("fish"):
		if fish.profile.eats_pellets_at(fish.growth.stage) and fish.hunger >= fish.profile.hungry_threshold and fish.health.current > 0.0:
			hungry_ids.append(fish.life.id)
			if candidate == null and not fish.life.id in served_hungry_ids:
				candidate = fish
	for i in range(served_hungry_ids.size() - 1, -1, -1):
		if not served_hungry_ids[i] in hungry_ids:
			served_hungry_ids.remove_at(i)
	if feed_left <= 0.0 and candidate != null and get_tree().get_nodes_in_group("food").size() < 80:
		feed_produced.emit(position + Vector2(34, -22), feed_tier)
		served_hungry_ids.append(candidate.life.id)
		feed_left = feed_interval
	queue_redraw()

func _draw() -> void:
	VectorArt.draw_seahorse(self, Vector2.ZERO, 1.0, phase, charge_progress())
