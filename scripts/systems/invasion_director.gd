class_name InvasionDirector
extends Node2D
## Owns randomized scheduling and warning; at most one active invader.
signal warning_started
signal alien_defeated(at: Vector2)
@export var warning_duration: float = 5.0
var wait_left: float
var warning_left: float = 0.0
var spawn_at := Vector2.ZERO
var active: TankAlien
var running: bool = true
var bounds := Rect2(98, 218, 956, 410)
var presentation_scale: float = 1.0
var tank_index: int = 1
@export var hunter_chance: float = 0.5
var upcoming_hunter: bool = false
var last_defeated_hunter: bool = false

func _ready() -> void:
	z_index = 9
	schedule_next()

func schedule_next() -> void:
	wait_left = randf_range(90.0, 150.0)

func draw_next_hunter() -> bool:
	if tank_index != 2:
		return false
	return randf() < clampf(hunter_chance, 0.0, 1.0)

func begin_warning() -> void:
	if not running or warning_left > 0.0 or is_instance_valid(active):
		return
	spawn_at = Vector2(bounds.position.x if randf() < 0.5 else bounds.end.x, randf_range(bounds.position.y + 27, bounds.end.y - 48))
	upcoming_hunter = draw_next_hunter()
	warning_left = warning_duration
	warning_started.emit()
	queue_redraw()

func _process(delta: float) -> void:
	delta *= ActivityPace.multiplier
	if not running or is_instance_valid(active):
		return
	if warning_left > 0.0:
		warning_left = maxf(0.0, warning_left - delta)
		if warning_left <= 0.0:
			spawn_now(true)
	else:
		wait_left -= delta
		if wait_left <= 0.0:
			begin_warning()
	queue_redraw()

func spawn_now(use_warning_location: bool = false) -> void:
	if is_instance_valid(active):
		return
	warning_left = 0.0
	if not use_warning_location:
		spawn_at = Vector2(bounds.position.x if randf() < 0.5 else bounds.end.x, randf_range(bounds.position.y + 27.0, bounds.end.y - 48.0))
		upcoming_hunter = draw_next_hunter()
	active = TankAlien.new()
	active.threatens_piranhas = upcoming_hunter and tank_index == 2
	active.scale = Vector2.ONE * presentation_scale
	active.bounds = bounds
	active.position = spawn_at
	active.defeated.connect(_on_defeated)
	add_child(active)
	queue_redraw()

func _on_defeated(at: Vector2) -> void:
	last_defeated_hunter = is_instance_valid(active) and active.threatens_piranhas
	active = null
	schedule_next()
	alien_defeated.emit(at)

func stop() -> void:
	running = false
	warning_left = 0.0
	if is_instance_valid(active):
		active.set_process(false)
	queue_redraw()

func _draw() -> void:
	if warning_left > 0.0:
		var radius: float = 39.0 + sin(warning_left * 8.0) * 5.0
		var warning_color := Color("df9bff") if upcoming_hunter else Color("ff9ca7")
		draw_arc(spawn_at, radius, 0, TAU, 48, warning_color, 3, true)
		draw_line(spawn_at - Vector2(16, 0), spawn_at + Vector2(16, 0), warning_color, 2)
		draw_line(spawn_at - Vector2(0, 16), spawn_at + Vector2(0, 16), warning_color, 2)
		draw_string(ThemeDB.fallback_font, Vector2(310, 194), ("HUNTER IN %ds — protect your piranhas!" if upcoming_hunter else "INVADER IN %ds — watch the marked entry!") % ceili(warning_left), HORIZONTAL_ALIGNMENT_LEFT, -1, 19, warning_color)
	elif is_instance_valid(active) and running:
		draw_string(ThemeDB.fallback_font, Vector2(305, 194), "Click the hunter! Piranhas flee it." if active.threatens_piranhas else "Click the alien! Piranhas can help defend.", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("ffacb5"))
