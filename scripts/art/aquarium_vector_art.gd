class_name AquariumVectorArt
extends RefCounted
## Shared procedural silhouettes used by both live entities and shop previews.

static func draw_fish(canvas: CanvasItem, at: Vector2, size: float, color: Color, tail: float = 0.0, dead: bool = false, crowned: bool = false) -> void:
	canvas.draw_set_transform(at, 0.0, Vector2.ONE * size)
	canvas.draw_colored_polygon(PackedVector2Array([Vector2(-20, 0), Vector2(-41, -17 + tail), Vector2(-38, 18 + tail)]), color.darkened(0.16))
	canvas.draw_colored_polygon(PackedVector2Array([Vector2(-10, -12), Vector2(-6, -25), Vector2(12, -12)]), color.darkened(0.12))
	canvas.draw_set_transform(at, 0.0, Vector2(1.45, 0.85) * size)
	canvas.draw_circle(Vector2.ZERO, 19, color)
	canvas.draw_set_transform(at, 0.0, Vector2.ONE * size)
	canvas.draw_arc(Vector2(-2, 0), 10, -1.1, 1.1, 16, color.darkened(0.28), 2, true)
	canvas.draw_circle(Vector2(16, -5), 6, Color("fff9e8"))
	if dead:
		canvas.draw_line(Vector2(13, -8), Vector2(20, -1), Color("173348"), 2, true)
		canvas.draw_line(Vector2(13, -1), Vector2(20, -8), Color("173348"), 2, true)
	else:
		canvas.draw_circle(Vector2(18, -5), 3, Color("173348"))
	if crowned:
		# A compact crown sits on the head instead of floating above the body.
		var crown := PackedVector2Array([Vector2(7, -14), Vector2(6, -22), Vector2(10, -18), Vector2(13, -25), Vector2(16, -18), Vector2(20, -22), Vector2(19, -14)])
		canvas.draw_colored_polygon(crown, Color("57b9ec"))
		canvas.draw_polyline(PackedVector2Array([crown[0], crown[1], crown[2], crown[3], crown[4], crown[5], crown[6], crown[0]]), Color("1f6f9d"), 1.0, true)
		canvas.draw_circle(Vector2(13, -16), 1.3, Color("d5f5ff"))
	canvas.draw_set_transform(Vector2.ZERO)

static func draw_snail(canvas: CanvasItem, at: Vector2, size: float = 1.0, retracted: bool = false) -> void:
	canvas.draw_set_transform(at, 0.0, Vector2.ONE * size)
	if retracted:
		# A small tucked-in foot keeps the shell grounded while the head and feelers disappear.
		canvas.draw_style_box(snail_body_style(), Rect2(-24, -3, 46, 9))
		canvas.draw_circle(Vector2(-3, -17), 24, Color("cb9786"))
		var sleeping_spiral := PackedVector2Array()
		for i in range(60):
			var sleeping_angle: float = i * 0.18
			sleeping_spiral.append(Vector2(-3, -17) + Vector2(cos(sleeping_angle), sin(sleeping_angle)) * (1.0 + i * 0.3))
		canvas.draw_polyline(sleeping_spiral, Color("775970"), 2.5, true)
		canvas.draw_arc(Vector2(-3, -17), 24, 0, TAU, 32, Color("e2b09b"), 1.5, true)
		canvas.draw_set_transform(Vector2.ZERO)
		return
	canvas.draw_style_box(snail_body_style(), Rect2(-26, -8, 58, 14))
	canvas.draw_circle(Vector2(-5, -19), 22, Color("cb9786"))
	var spiral := PackedVector2Array()
	for i in range(60):
		var angle: float = i * 0.18
		spiral.append(Vector2(-5, -19) + Vector2(cos(angle), sin(angle)) * (1.0 + i * 0.28))
	canvas.draw_polyline(spiral, Color("775970"), 2.5, true)
	for x in [20.0, 30.0]:
		canvas.draw_line(Vector2(x - 4, -3), Vector2(x, -23), Color("a7c99d"), 3, true)
		canvas.draw_circle(Vector2(x, -23), 4, Color("d5ebc6"))
		canvas.draw_circle(Vector2(x + 1, -23), 1.8, Color("203748"))
	canvas.draw_set_transform(Vector2.ZERO)

static func draw_seahorse(canvas: CanvasItem, at: Vector2, size: float = 1.0, phase: float = 0.0) -> void:
	var color := Color("aa9de0")
	canvas.draw_set_transform(at, 0.0, Vector2.ONE * size)
	var tail := PackedVector2Array()
	for i in range(40):
		var angle: float = i * 0.14
		tail.append(Vector2(-4, 25) + Vector2(sin(angle), -cos(angle)) * (18.0 - i * 0.32))
	canvas.draw_polyline(tail, color, 7, true)
	canvas.draw_colored_polygon(PackedVector2Array([Vector2(-9, -3), Vector2(-27, -10 + sin(phase * 8) * 3), Vector2(-23, 15), Vector2(-6, 15)]), Color("72c7c0"))
	canvas.draw_set_transform(at, -0.15, Vector2(0.7, 1.25) * size)
	canvas.draw_circle(Vector2.ZERO, 17, color)
	canvas.draw_set_transform(at, 0.0, Vector2.ONE * size)
	canvas.draw_line(Vector2(2, -8), Vector2(4, -29), color, 15, true)
	canvas.draw_circle(Vector2(9, -29), 14, color)
	canvas.draw_line(Vector2(14, -25), Vector2(33, -22), color, 9, true)
	canvas.draw_circle(Vector2(14, -33), 5, Color("f2f7ee"))
	canvas.draw_circle(Vector2(16, -33), 2.5, Color("203748"))
	for i in range(3):
		canvas.draw_line(Vector2(-4, i * 7 - 5), Vector2(8, i * 7 - 5), Color("ddd0f3"), 2, true)
	canvas.draw_set_transform(Vector2.ZERO)

static func draw_urchin(canvas: CanvasItem, at: Vector2, size: float = 1.0, phase: float = 0.0) -> void:
	canvas.draw_set_transform(at, 0.0, Vector2.ONE * size)
	var body_color := Color("070b0d")
	var spine_color := Color("172126")
	for i in range(18):
		var angle: float = i * TAU / 18.0
		var sway: float = sin(phase * 3.0 + i * 1.7) * 1.5
		var inner := Vector2(cos(angle), sin(angle)) * 15.0
		var outer := Vector2(cos(angle), sin(angle)) * (27.0 + sway)
		canvas.draw_line(inner, outer, spine_color, 3.5, true)
	canvas.draw_circle(Vector2.ZERO, 18.0, Color("020405"))
	canvas.draw_circle(Vector2(0, -2), 16.0, body_color)
	canvas.draw_arc(Vector2(0, -2), 16.0, 0, TAU, 32, Color("35454d"), 1.2, true)
	canvas.draw_set_transform(Vector2.ZERO)

static func draw_puffer(canvas: CanvasItem, at: Vector2, size: float = 1.0, inflated: bool = false, phase: float = 0.0) -> void:
	var color := Color("d8c16c")
	var radius: float = 24.0 if inflated else 18.0
	canvas.draw_set_transform(at, 0.0, Vector2.ONE * size)
	canvas.draw_colored_polygon(PackedVector2Array([Vector2(-14, 0), Vector2(-34, -14), Vector2(-32, 15)]), color.darkened(0.2))
	for i in range(12):
		var angle: float = i * TAU / 12.0
		var root := Vector2(cos(angle), sin(angle)) * (radius - 2.0)
		var tip := Vector2(cos(angle), sin(angle)) * (radius + 5.0 + sin(phase * 5.0 + i) * 0.7)
		canvas.draw_line(root, tip, color.lightened(0.18), 2.0, true)
	canvas.draw_set_transform(at, 0.0, (Vector2.ONE if inflated else Vector2(1.25, 0.9)) * size)
	canvas.draw_circle(Vector2.ZERO, radius, color.darkened(0.18))
	canvas.draw_circle(Vector2(0, -2), radius - 2.0, color)
	canvas.draw_set_transform(at, 0.0, Vector2.ONE * size)
	canvas.draw_circle(Vector2(13 if inflated else 17, -7), 5.0, Color("f5f3dc"))
	canvas.draw_circle(Vector2(15 if inflated else 19, -7), 2.2, Color("172934"))
	canvas.draw_colored_polygon(PackedVector2Array([Vector2(radius - 1, 1), Vector2(radius + 8, -2), Vector2(radius + 8, 5)]), Color("785d45"))
	canvas.draw_circle(Vector2(-5, 4), 2.2, color.darkened(0.25))
	canvas.draw_circle(Vector2(5, 9), 1.8, color.darkened(0.25))
	canvas.draw_set_transform(Vector2.ZERO)

static func draw_shrimp(canvas: CanvasItem, at: Vector2, size: float = 1.0, phase: float = 0.0) -> void:
	canvas.draw_set_transform(at, 0.0, Vector2.ONE * size)
	var shell := Color("f29b82")
	var shell_dark := Color("b85f63")
	var shell_light := Color("ffc2ad")
	# A soft comma-shaped body and oversized head keep the helper playful.
	canvas.draw_colored_polygon(PackedVector2Array([Vector2(-25, 4), Vector2(-42, -4), Vector2(-37, 7), Vector2(-43, 17), Vector2(-23, 12)]), shell_dark)
	canvas.draw_colored_polygon(PackedVector2Array([
		Vector2(-27, 3), Vector2(-22, -7), Vector2(-12, -14), Vector2(1, -16),
		Vector2(14, -12), Vector2(18, -2), Vector2(11, 6), Vector2(-3, 10), Vector2(-18, 11)
	]), shell)
	canvas.draw_polyline(PackedVector2Array([Vector2(-25, 2), Vector2(-20, -7), Vector2(-10, -13), Vector2(2, -15), Vector2(12, -11)]), shell_light, 2.2, true)
	for i in range(4):
		var stripe_x: float = -18.0 + i * 7.0
		canvas.draw_line(Vector2(stripe_x, -8 - i * 1.2), Vector2(stripe_x + 2, 7), shell_dark, 1.3, true)
	canvas.draw_circle(Vector2(19, -8), 14.0, shell)
	canvas.draw_circle(Vector2(24, -13), 4.2, Color("fff4e9"))
	canvas.draw_circle(Vector2(25, -13), 2.1, Color("24343b"))
	canvas.draw_circle(Vector2(17, -3), 2.4, Color("ef796f"))
	canvas.draw_arc(Vector2(22, -7), 6.0, 0.35, 1.25, 8, shell_dark, 1.4, true)
	# Short, buoyant feelers replace the previous sharp realistic antennae.
	canvas.draw_polyline(PackedVector2Array([Vector2(27, -17), Vector2(37, -25), Vector2(48, -23 + sin(phase * 2.5))]), shell_light, 1.8, true)
	canvas.draw_polyline(PackedVector2Array([Vector2(29, -13), Vector2(40, -18), Vector2(50, -15 + sin(phase * 2.5 + 1.0))]), shell_dark, 1.5, true)
	# Five tiny feet paddle as a friendly wave instead of a dense realistic cluster.
	for i in range(5):
		var foot_root := Vector2(-13 + i * 7.0, 8 - absf(float(i) - 2.0) * 0.7)
		var foot_swing: float = sin(phase * 8.0 + float(i) * 0.9)
		canvas.draw_polyline(PackedVector2Array([foot_root, foot_root + Vector2(1, 5), foot_root + Vector2(4 + foot_swing * 1.8, 9)]), shell_dark, 1.5, true)
	canvas.draw_set_transform(Vector2.ZERO)

static func draw_feeder(canvas: CanvasItem, at: Vector2, size: float = 1.0, label: bool = false) -> void:
	canvas.draw_set_transform(at, 0.0, Vector2.ONE * size)
	canvas.draw_rect(Rect2(0, 0, 110, 34), Color("779caa"))
	canvas.draw_rect(Rect2(37, 29, 35, 12), Color("b0cbd1"))
	if label:
		canvas.draw_string(ThemeDB.fallback_font, Vector2(9, 22), "AUTO FEED", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("102e3c"))
	canvas.draw_set_transform(Vector2.ZERO)

static func draw_pellet(canvas: CanvasItem, at: Vector2, growth_credit: int = 1, color: Color = Color("ffa86b"), size: float = 1.0) -> void:
	canvas.draw_circle(at, 7.0 * size, Color("513c31"))
	canvas.draw_circle(at + Vector2(-1, -2) * size, (4.5 + growth_credit - 1) * size, color)

static func draw_coin(canvas: CanvasItem, at: Vector2, size: float, value: int = 1, diamond: bool = false, grade: int = -1) -> void:
	canvas.draw_set_transform(at, 0.0, Vector2.ONE * size)
	if diamond:
		var outline := PackedVector2Array([Vector2(-19, -7), Vector2(-10, -19), Vector2(10, -19), Vector2(19, -7), Vector2(0, 20)])
		canvas.draw_colored_polygon(outline, Color("2599ed"))
		canvas.draw_colored_polygon(PackedVector2Array([Vector2(-19, -7), Vector2(0, -12), Vector2(0, 20)]), Color("83e4ff"))
		canvas.draw_colored_polygon(PackedVector2Array([Vector2(-10, -19), Vector2(10, -19), Vector2(0, -7)]), Color("d1f7ff"))
		outline.append(outline[0])
		canvas.draw_polyline(outline, Color("bceeff"), 1.5, true)
		canvas.draw_string(ThemeDB.fallback_font, Vector2(-13, 4), str(value), HORIZONTAL_ALIGNMENT_CENTER, 26, 11, Color("143e66"))
	else:
		var color := coin_color(value, grade)
		canvas.draw_circle(Vector2.ZERO, 16, color.darkened(0.4))
		canvas.draw_circle(Vector2(0, -2), 14, color)
		canvas.draw_arc(Vector2(0, -2), 10, 0, TAU, 32, color.darkened(0.3), 1.5, true)
		canvas.draw_string(ThemeDB.fallback_font, Vector2(-9, 3), str(value), HORIZONTAL_ALIGNMENT_CENTER, 18, 12, Color("493d35"))
	canvas.draw_set_transform(Vector2.ZERO)

static func coin_color(value: int, grade: int = -1) -> Color:
	if grade >= 3 or (grade < 0 and value >= 3):
		return Color("ffdb80")
	if grade >= 2 or (grade < 0 and value >= 2):
		return Color("d4e3ed")
	return Color("d79b69")

static func snail_body_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("a7c99d")
	style.set_corner_radius_all(7)
	return style
