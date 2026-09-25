class_name ShopIcon
extends Node2D
## Draws the exact reusable shop artwork, with an optional monochrome discovery mask.
const VectorArt = preload("res://scripts/art/aquarium_vector_art.gd")
var icon_kind: String = "fish"
var pellet_color: Color = Color("ffa86b")
var pellet_growth: int = 1
var discovered: bool = true

func set_discovered(value: bool) -> void:
	discovered = value
	# The grayscale shader keeps the exact contours and shading of the shared
	# artwork while withholding its real colors until discovery.
	material = null if discovered else silhouette_material()
	queue_redraw()

func set_pellet_preview(color: Color, growth_credit: int) -> void:
	pellet_color = color
	pellet_growth = growth_credit
	queue_redraw()

func _draw() -> void:
	match icon_kind:
		"fish":
			VectorArt.draw_fish(self, Vector2.ZERO, 1.25, Color("f6be73"))
		"snail":
			VectorArt.draw_snail(self, Vector2(0, 12), 1.25)
		"shrimp":
			VectorArt.draw_shrimp(self, Vector2(0, 5), 1.25)
		"seahorse":
			VectorArt.draw_seahorse(self, Vector2(0, -3), 1.05)
		"puffer":
			VectorArt.draw_puffer(self, Vector2.ZERO, 1.15, true)
		"feeder":
			VectorArt.draw_feeder(self, Vector2(-50, -20), 0.9, true)
		"stock":
			draw_style_box(machine_style(), Rect2(Vector2(-45, -28), Vector2(90, 60)))
			for row in range(3):
				for column in range(4):
					VectorArt.draw_pellet(self, Vector2(-27 + column * 18, -12 + row * 17), pellet_growth, pellet_color, 0.65)
		"feed":
			for i in range(5):
				var angle: float = i * TAU / 5.0
				VectorArt.draw_pellet(self, Vector2(cos(angle), sin(angle)) * 28, pellet_growth, pellet_color, 1.0)
			VectorArt.draw_pellet(self, Vector2.ZERO, pellet_growth, pellet_color, 1.15)
		"coin":
			VectorArt.draw_coin(self, Vector2.ZERO, 1.5, 3, false)
		"diamond":
			VectorArt.draw_coin(self, Vector2.ZERO, 1.5, 10, true)
		"clock":
			draw_circle(Vector2.ZERO, 31, Color("d8eef0"))
			draw_circle(Vector2.ZERO, 27, Color("173847"))
			draw_line(Vector2.ZERO, Vector2(0, -17), Color("8edfe9"), 4, true)
			draw_line(Vector2.ZERO, Vector2(14, 8), Color("8edfe9"), 4, true)
			draw_circle(Vector2.ZERO, 4, Color("ffdb80"))
		"bubble":
			for bubble in [Vector3(-22, 10, 14), Vector3(8, -8, 20), Vector3(28, 18, 10)]:
				draw_circle(Vector2(bubble.x, bubble.y), bubble.z, Color(0.55, 0.88, 0.95, 0.12))
				draw_arc(Vector2(bubble.x, bubble.y), bubble.z, 0, TAU, 24, Color("a9edf2"), 3, true)

func silhouette_material() -> ShaderMaterial:
	var shader := Shader.new()
	shader.code = """
shader_type canvas_item;
void fragment() {
	float shade = 0.09 + dot(COLOR.rgb, vec3(0.299, 0.587, 0.114)) * 0.18;
	COLOR = vec4(vec3(shade), COLOR.a);
}
"""
	var result := ShaderMaterial.new()
	result.shader = shader
	return result

func machine_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("779caa")
	style.border_color = Color("b0cbd1")
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	return style
