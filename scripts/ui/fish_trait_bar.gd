class_name FishTraitBar
extends Control
## Compact phenotype row. Values are direct gameplay outcomes, never hidden alleles.
var title: String = ""
var display_value: String = ""
var progress: float = 0.5
var comparison: String = ""

func _init() -> void:
	custom_minimum_size = Vector2(316, 25)
	size = custom_minimum_size
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func configure(row: Dictionary) -> void:
	title = str(row.get("title", ""))
	display_value = str(row.get("value", ""))
	comparison = str(row.get("comparison", ""))
	progress = clampf(float(row.get("progress", 0.5)), 0.0, 1.0)
	queue_redraw()

func _draw() -> void:
	var font := ThemeDB.fallback_font
	draw_string(font, Vector2(0, 17), title, HORIZONTAL_ALIGNMENT_LEFT, 104, 12, Color("c7dfdb"))
	var track := Rect2(106, 7, 105, 10)
	draw_rect(track, Color("243d48"))
	var fill_color := Color("8edfe9").lerp(Color("79d68a"), progress)
	draw_rect(Rect2(track.position, Vector2(track.size.x * progress, track.size.y)), fill_color)
	var shown_value: String = display_value + (" " + comparison if not comparison.is_empty() else "")
	draw_string(font, Vector2(219, 17), shown_value, HORIZONTAL_ALIGNMENT_RIGHT, 97, 12, Color("e8f2ed"))
