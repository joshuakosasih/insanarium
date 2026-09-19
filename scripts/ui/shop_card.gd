class_name ShopCard
extends Button
## Reusable visual selector for purchasable creatures, equipment, and upgrades.
const VectorArt = preload("res://scripts/art/aquarium_vector_art.gd")
var item_id: String
var display_title: String
var category: String
var icon_kind: String
var status: String = ""
var selected: bool = false
var pellet_color: Color = Color("ffa86b")
var pellet_growth: int = 1

func configure(item) -> void:
	item_id = item.id
	display_title = item.title
	category = item.category
	icon_kind = item.icon
	text = ""
	custom_minimum_size = Vector2(142, 136)
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	for state in ["normal", "hover", "pressed", "focus"]:
		var style := StyleBoxFlat.new()
		style.bg_color = Color("102f3d") if state == "normal" else Color("174354")
		style.border_color = Color("315b68")
		style.set_border_width_all(1)
		style.set_corner_radius_all(12)
		add_theme_stylebox_override(state, style)
	queue_redraw()

func set_status(value: String) -> void:
	status = value
	queue_redraw()

func set_selected(value: bool) -> void:
	selected = value
	queue_redraw()

func set_pellet_preview(color: Color, growth_credit: int) -> void:
	pellet_color = color
	pellet_growth = growth_credit
	queue_redraw()

func _draw() -> void:
	if selected:
		draw_style_box(selection_style(), Rect2(Vector2(2, 2), size - Vector2(4, 4)))
	var center := Vector2(size.x * 0.5, 56)
	draw_icon(center)
	var font := ThemeDB.fallback_font
	draw_string(font, Vector2(12, 20), category, HORIZONTAL_ALIGNMENT_LEFT, size.x - 24, 11, Color("8edfe9"))
	draw_string(font, Vector2(12, size.y - 34), display_title, HORIZONTAL_ALIGNMENT_LEFT, size.x - 24, 15, Color("e8f2ed"))
	draw_string(font, Vector2(12, size.y - 12), status, HORIZONTAL_ALIGNMENT_LEFT, size.x - 24, 11, Color("ffdb80"))

func selection_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.34, 0.40, 0.35)
	style.border_color = Color("8edfe9")
	style.set_border_width_all(2)
	style.set_corner_radius_all(11)
	return style

func draw_icon(at: Vector2) -> void:
	match icon_kind:
		"fish":
			VectorArt.draw_fish(self, at, 1.25, Color("f6be73"))
		"snail":
			VectorArt.draw_snail(self, at + Vector2(0, 12), 1.25)
		"seahorse":
			VectorArt.draw_seahorse(self, at + Vector2(0, 8), 1.15)
		"puffer":
			VectorArt.draw_puffer(self, at, 1.15, true)
		"feeder":
			VectorArt.draw_feeder(self, at + Vector2(-50, -20), 0.9, true)
		"stock":
			draw_style_box(machine_style(), Rect2(at + Vector2(-45, -28), Vector2(90, 60)))
			for row in range(3):
				for column in range(4):
					VectorArt.draw_pellet(self, at + Vector2(-27 + column * 18, -12 + row * 17), pellet_growth, pellet_color, 0.65)
		"feed":
			for i in range(5):
				var angle: float = i * TAU / 5.0
				VectorArt.draw_pellet(self, at + Vector2(cos(angle), sin(angle)) * 28, pellet_growth, pellet_color, 1.0)
			VectorArt.draw_pellet(self, at, pellet_growth, pellet_color, 1.15)
		"coin":
			VectorArt.draw_coin(self, at, 1.5, 3, false)
		"clock":
			draw_circle(at, 31, Color("d8eef0"))
			draw_circle(at, 27, Color("173847"))
			draw_line(at, at + Vector2(0, -17), Color("8edfe9"), 4, true)
			draw_line(at, at + Vector2(14, 8), Color("8edfe9"), 4, true)
			draw_circle(at, 4, Color("ffdb80"))
		"bubble":
			for bubble in [Vector3(-22, 10, 14), Vector3(8, -8, 20), Vector3(28, 18, 10)]:
				draw_circle(at + Vector2(bubble.x, bubble.y), bubble.z, Color(0.55, 0.88, 0.95, 0.12))
				draw_arc(at + Vector2(bubble.x, bubble.y), bubble.z, 0, TAU, 24, Color("a9edf2"), 3, true)

func machine_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("779caa")
	style.border_color = Color("b0cbd1")
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	return style
