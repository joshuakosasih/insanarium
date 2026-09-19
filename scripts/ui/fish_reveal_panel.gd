class_name FishRevealPanel
extends Panel
## Reusable, non-pausing reveal card for purchased fish and newborn offspring.
const VectorArt = preload("res://scripts/art/aquarium_vector_art.gd")
const TraitBarScript = preload("res://scripts/ui/fish_trait_bar.gd")
signal dismissed
signal inspect_requested(fish_id: String)
var heading_label: Label
var identity_label: Label
var details_label: Label
var comparison_label: Label
var dismiss_button: Button
var inspect_button: Button
var trait_bars: Array[FishTraitBar] = []
var fish_id: String = ""
var fish_color: Color = Color("f6be73")

func _ready() -> void:
	size = Vector2(552, 590)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("0b2230")
	style.border_color = Color("8edfe9")
	style.set_border_width_all(2)
	style.set_corner_radius_all(16)
	add_theme_stylebox_override("panel", style)
	heading_label = make_label("", Vector2(24, 18), 13, Color("8edfe9"))
	identity_label = make_label("", Vector2(24, 45), 20, Color("e8f2ed"))
	identity_label.size = Vector2(504, 52)
	identity_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	for index in range(6):
		var bar: FishTraitBar = TraitBarScript.new()
		bar.position = Vector2(118, 205 + index * 31)
		add_child(bar)
		trait_bars.append(bar)
	details_label = make_label("", Vector2(38, 402), 14, Color("c7dfdb"))
	details_label.size = Vector2(476, 48)
	details_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	comparison_label = make_label("", Vector2(38, 455), 13, Color("ffdb80"))
	comparison_label.size = Vector2(476, 50)
	comparison_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	comparison_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	inspect_button = make_button("Inspect fish", Vector2(38, 525), Vector2(220, 44))
	inspect_button.pressed.connect(func() -> void: inspect_requested.emit(fish_id))
	dismiss_button = make_button("Dismiss", Vector2(294, 525), Vector2(220, 44))
	dismiss_button.pressed.connect(func() -> void: dismissed.emit())
	hide()

func present(data: Dictionary) -> void:
	fish_id = str(data.id)
	fish_color = data.color
	heading_label.text = str(data.heading)
	identity_label.text = str(data.identity)
	details_label.text = str(data.details)
	comparison_label.text = str(data.comparison)
	var rows: Array = data.rows
	for index in range(trait_bars.size()):
		trait_bars[index].configure(rows[index])
	show()
	queue_redraw()

func set_pending_count(count: int) -> void:
	dismiss_button.text = "Next (%d waiting)" % count if count > 0 else "Dismiss"

static func capture(fish: AquariumFish, heading: String, parents: Array = []) -> Dictionary:
	var rows: Array[Dictionary] = FishInspector.trait_rows(fish)
	var parent_ids: Array[String] = []
	if not parents.is_empty():
		var parent_rows: Array = []
		for parent in parents:
			if is_instance_valid(parent):
				parent_ids.append(parent.life.id)
				parent_rows.append(FishInspector.trait_rows(parent))
		if not parent_rows.is_empty():
			for index in range(rows.size()):
				var parent_average: float = 0.0
				for comparison_rows in parent_rows:
					parent_average += float(comparison_rows[index].progress)
				parent_average /= parent_rows.size()
				var difference: float = float(rows[index].progress) - parent_average
				rows[index] = rows[index].duplicate()
				rows[index].comparison = "↑" if difference > 0.035 else ("↓" if difference < -0.035 else "≈")
	var comparison: String = "A new bloodline for your aquarium."
	if not parent_ids.is_empty():
		comparison = "Parents: %s\n↑ above parents · ↓ below parents · ≈ similar" % " + ".join(parent_ids)
	var lifespan: float = FishAging.lifespan_for(fish.genome)
	return {"heading": heading, "id": fish.life.id,
		"identity": "%s · %s\n%s · %s · %s" % [fish.life.id, fish.profile.species_name, AquariumFish.SEX_NAMES[fish.sex], fish.profile.growth_names[fish.growth.stage], FishMutation.NAMES[fish.mutation.variant]],
		"details": "Output interval %.1fs · Expected lifespan %s" % [fish.genome.output_interval(fish.profile.coin_interval), FishInspector.duration(lifespan)],
		"comparison": comparison, "rows": rows, "color": FishMutation.COLORS[fish.mutation.variant]}

func _draw() -> void:
	VectorArt.draw_fish(self, Vector2(size.x * 0.5, 142), 1.7, fish_color)
	draw_string(ThemeDB.fallback_font, Vector2(24, 188), "DIRECT TRAITS", HORIZONTAL_ALIGNMENT_CENTER, size.x - 48, 12, Color("83a9b7"))

func make_label(value: String, at: Vector2, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = value
	label.position = at
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)
	return label

func make_button(value: String, at: Vector2, dimensions: Vector2) -> Button:
	var button := Button.new()
	button.text = value
	button.position = at
	button.size = dimensions
	button.add_theme_font_size_override("font_size", 15)
	add_child(button)
	return button
