class_name DebugControls
extends HBoxContainer
## Visible in debug builds or via ?admin=1 on web. Frontend-only test controls.
signal hunger_requested
signal money_requested
signal invasion_requested
signal reset_requested
signal autoplay_toggled(enabled: bool)
var speed_button: Button
var autoplay_button: Button
var autoplay_enabled: bool = false

func _ready() -> void:
	visible = OS.is_debug_build() or (OS.has_feature("web") and bool(JavaScriptBridge.eval("new URLSearchParams(location.search).get('admin') === '1'", true)))
	add_theme_constant_override("separation", 6)
	var caption := Label.new()
	caption.text = "ADMIN"
	caption.add_theme_font_size_override("font_size", 11)
	add_child(caption)
	speed_button = make_debug_button("Speed 1×", func() -> void:
		Engine.time_scale = 10.0 if Engine.time_scale == 1.0 else 1.0
		speed_button.text = "Speed %d×" % int(Engine.time_scale))
	autoplay_button = make_debug_button("Auto: off", func() -> void:
		autoplay_enabled = not autoplay_enabled
		autoplay_button.text = "Auto: on" if autoplay_enabled else "Auto: off"
		autoplay_toggled.emit(autoplay_enabled))
	make_debug_button("Hungry", func() -> void: hunger_requested.emit())
	make_debug_button("+$10k", func() -> void: money_requested.emit())
	make_debug_button("Alien now", func() -> void: invasion_requested.emit())
	make_debug_button("Reset", func() -> void: reset_requested.emit())

func make_debug_button(label: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = label
	button.custom_minimum_size = Vector2(82, 32)
	button.add_theme_font_size_override("font_size", 11)
	button.pressed.connect(action)
	add_child(button)
	return button

func reset_state() -> void:
	autoplay_enabled = false
	Engine.time_scale = 1.0
	if is_instance_valid(speed_button):
		speed_button.text = "Speed 1×"
	if is_instance_valid(autoplay_button):
		autoplay_button.text = "Auto: off"

func _exit_tree() -> void:
	Engine.time_scale = 1.0
