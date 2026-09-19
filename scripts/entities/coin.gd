class_name TankCoin
extends Node2D
const VectorArt = preload("res://scripts/art/aquarium_vector_art.gd")
signal collected(value: int)
const BASE_LIFETIME: float = 8.0
const MAX_LIFETIME: float = 75.0
const FADE_DURATION: float = 2.0
var value: int = 1
var diamond: bool = false
var floor_y: float = 650.0
var claimed: bool = false
var lifetime: float = BASE_LIFETIME
var grounded: bool = false
var collection_target := Vector2(825, 68)

func _ready() -> void:
	add_to_group("coins")

func _process(delta: float) -> void:
	delta *= ActivityPace.multiplier
	if claimed:
		return
	if not grounded:
		position.y = minf(position.y + 34.0 * delta, floor_y)
		if position.y >= floor_y:
			grounded = true
		modulate.a = 1.0
		return
	lifetime -= delta
	if lifetime <= 0.0:
		remove_from_group("coins")
		queue_free()
		return
	modulate.a = 1.0 if lifetime > FADE_DURATION else pow(clampf(lifetime / FADE_DURATION, 0.0, 1.0), 2.0)

func collect() -> void:
	if claimed or lifetime <= 0.0 or is_queued_for_deletion():
		return
	claimed = true
	collected.emit(value)
	remove_from_group("coins")
	var tween := create_tween().set_parallel(true)
	tween.tween_property(self, "position", collection_target, 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(self, "scale", Vector2.ONE * 0.3, 0.45)
	tween.tween_property(self, "modulate:a", 0.0, 0.15).set_delay(0.3)
	tween.chain().tween_callback(queue_free)

func coin_color() -> Color:
	if diamond:
		return Color("67ccff")
	if value >= 3:
		return Color("ffdb80")
	if value >= 2:
		return Color("d4e3ed")
	return Color("d79b69")

func _draw() -> void:
	VectorArt.draw_coin(self, Vector2.ZERO, 1.0, value, diamond)
