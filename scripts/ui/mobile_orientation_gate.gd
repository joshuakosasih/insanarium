class_name MobileOrientationGate
extends Control
## Blocks the cramped portrait layout and asks phone/tablet players to rotate.

var message: VBoxContainer

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_index = 100

	var shade := ColorRect.new()
	shade.color = Color("06121b")
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)

	message = VBoxContainer.new()
	message.set_anchors_preset(Control.PRESET_CENTER)
	message.position = Vector2(-260, -110)
	message.size = Vector2(520, 220)
	message.alignment = BoxContainer.ALIGNMENT_CENTER
	message.add_theme_constant_override("separation", 18)
	add_child(message)

	var icon := Label.new()
	icon.text = "↻"
	icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon.add_theme_font_size_override("font_size", 72)
	icon.add_theme_color_override("font_color", Color("8edfe9"))
	message.add_child(icon)

	var title := Label.new()
	title.text = "ROTATE YOUR PHONE"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", Color("e8f2ed"))
	message.add_child(title)

	var detail := Label.new()
	detail.text = "Insanarium plays in landscape so the fish and controls stay easy to see and tap."
	detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail.add_theme_font_size_override("font_size", 20)
	detail.add_theme_color_override("font_color", Color("83a9b7"))
	message.add_child(detail)

	update_orientation()

func _process(_delta: float) -> void:
	update_orientation()

func update_orientation() -> void:
	var pixels := DisplayServer.window_get_size()
	visible = pixels.y > pixels.x and pixels.x < 1000
