class_name ShopCard
extends Button
## Reusable visual selector for purchasable creatures, equipment, and upgrades.
signal scroll_dragged(relative_y: float)
const ShopIconScript = preload("res://scripts/ui/shop_icon.gd")
var item_id: String
var display_title: String
var category: String
var icon_kind: String
var status: String = ""
var selected: bool = false
var discovered: bool = true
var pellet_color: Color = Color("ffa86b")
var pellet_growth: int = 1
var icon_preview: ShopIcon

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
	icon_preview = ShopIconScript.new()
	icon_preview.position = Vector2(71, 56)
	icon_preview.icon_kind = icon_kind
	add_child(icon_preview)
	queue_redraw()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenDrag:
		scroll_dragged.emit(event.relative.y)
		accept_event()
	elif event is InputEventMouseMotion and event.button_mask & MOUSE_BUTTON_MASK_LEFT:
		scroll_dragged.emit(event.relative.y)
		accept_event()

func set_status(value: String) -> void:
	status = value
	queue_redraw()

func set_selected(value: bool) -> void:
	selected = value
	queue_redraw()

func set_discovered(value: bool) -> void:
	discovered = value
	if is_instance_valid(icon_preview):
		icon_preview.set_discovered(value)
	queue_redraw()

func set_pellet_preview(color: Color, growth_credit: int) -> void:
	pellet_color = color
	pellet_growth = growth_credit
	if is_instance_valid(icon_preview):
		icon_preview.set_pellet_preview(color, growth_credit)
	queue_redraw()

func _draw() -> void:
	if selected:
		draw_style_box(selection_style(), Rect2(Vector2(2, 2), size - Vector2(4, 4)))
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
