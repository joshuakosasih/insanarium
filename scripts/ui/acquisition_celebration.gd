class_name AcquisitionCelebration
extends Panel
## Short, reusable acquisition reveal shown before details or returning to play.
const VectorArt = preload("res://scripts/art/aquarium_vector_art.gd")
signal finished
const DURATION := 1.25
var elapsed: float = 0.0
var icon_kind: String = "fish"
var icon_color: Color = Color("f6be73")
var crowned: bool = false
var title_label: Label
var subtitle_label: Label

func _ready() -> void:
	size = Vector2(552, 590)
	z_index = 35
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_STOP
	var style := StyleBoxFlat.new()
	style.bg_color = Color("081c29")
	style.border_color = Color("ffdb80")
	style.set_border_width_all(2)
	style.set_corner_radius_all(18)
	add_theme_stylebox_override("panel", style)
	title_label = make_label("", Vector2(24, 65), Vector2(504, 50), 29, Color("ffdb80"))
	subtitle_label = make_label("", Vector2(38, 430), Vector2(476, 65), 18, Color("d7ebe6"))
	subtitle_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hide()
	set_process(false)

func present(data: Dictionary) -> void:
	icon_kind = str(data.get("icon", "fish"))
	icon_color = data.get("color", Color("f6be73"))
	crowned = bool(data.get("crowned", false))
	title_label.text = str(data.get("title", "NEW FRIEND!"))
	subtitle_label.text = str(data.get("subtitle", "Welcome to the aquarium."))
	elapsed = 0.0
	show()
	move_to_front()
	set_process(true)
	queue_redraw()

func finish_now() -> void:
	if visible:
		complete()

func _process(delta: float) -> void:
	elapsed += delta
	queue_redraw()
	if elapsed >= DURATION:
		complete()

func complete() -> void:
	set_process(false)
	hide()
	finished.emit()

func _draw() -> void:
	var center := Vector2(size.x * 0.5, 278)
	var progress: float = clampf(elapsed / DURATION, 0.0, 1.0)
	var entrance: float = 1.0 - pow(1.0 - minf(progress * 2.8, 1.0), 3.0)
	var pulse: float = 1.0 + sin(elapsed * 9.0) * 0.035 * (1.0 - progress)
	for i in range(18):
		var angle: float = i * TAU / 18.0 + elapsed * 0.7
		var inner: Vector2 = center + Vector2.from_angle(angle) * 92.0
		var outer: Vector2 = center + Vector2.from_angle(angle) * (132.0 + 8.0 * sin(elapsed * 6.0 + i))
		draw_line(inner, outer, Color(1.0, 0.84, 0.42, 0.22 + 0.22 * sin(progress * PI)), 3.0, true)
	for i in range(12):
		var angle: float = i * 2.39996 + elapsed * (0.4 if i % 2 == 0 else -0.3)
		var distance: float = 115.0 + (i % 4) * 18.0
		var sparkle := center + Vector2.from_angle(angle) * distance
		var radius: float = 2.0 + 3.0 * absf(sin(elapsed * 7.0 + i))
		draw_line(sparkle - Vector2(radius, 0), sparkle + Vector2(radius, 0), Color("fff0a8"), 2.0, true)
		draw_line(sparkle - Vector2(0, radius), sparkle + Vector2(0, radius), Color("fff0a8"), 2.0, true)
	draw_circle(center, 88.0 * entrance, Color(0.39, 0.79, 0.82, 0.08))
	var icon_scale: float = (0.25 + entrance * 1.75) * pulse
	match icon_kind:
		"snail": VectorArt.draw_snail(self, center + Vector2(0, 20), icon_scale, false)
		"seahorse": VectorArt.draw_seahorse(self, center + Vector2(0, 12), icon_scale, elapsed)
		"puffer": VectorArt.draw_puffer(self, center, icon_scale, elapsed < 0.55, elapsed)
		_: VectorArt.draw_fish(self, center, icon_scale, icon_color, sin(elapsed * 10.0) * 3.0, false, crowned)
	draw_string(ThemeDB.fallback_font, Vector2(40, 527), "A NEW DISCOVERY", HORIZONTAL_ALIGNMENT_CENTER, size.x - 80, 12, Color("83a9b7"))

func make_label(value: String, at: Vector2, dimensions: Vector2, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = value
	label.position = at
	label.size = dimensions
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)
	return label
