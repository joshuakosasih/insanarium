class_name FloatingText
extends Node2D
## Short-lived world-space feedback; never intercepts input.
var text: String = ""
var color: Color = Color("ffdb80")

func _ready() -> void:
	z_index = 20
	var label := Label.new()
	label.text = text
	label.position = Vector2(-40, -25)
	label.add_theme_font_size_override("font_size", 19)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)
	var tween := create_tween().set_parallel(true)
	tween.tween_property(self, "position:y", position.y - 42, 0.9).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 0.0, 0.5).set_delay(0.4)
	tween.chain().tween_callback(queue_free)
