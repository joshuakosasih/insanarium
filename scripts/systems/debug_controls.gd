class_name DebugControls
extends HBoxContainer
## Available only in editor/debug builds. Does not participate in game economy.
signal hunger_requested
signal coins_requested
signal invasion_requested

func _ready() -> void:
	visible = OS.is_debug_build()
	position = Vector2(370, 760)
	add_theme_constant_override("separation", 8)
	var caption := Label.new()
	caption.text = "DEBUG"
	add_child(caption)
	var speed := Button.new()
	speed.text = "Speed: 1×"
	speed.pressed.connect(func() -> void:
		Engine.time_scale = 4.0 if Engine.time_scale == 1.0 else 1.0
		speed.text = "Speed: %d×" % int(Engine.time_scale))
	add_child(speed)
	var hungry := Button.new()
	hungry.text = "Make hungry"
	hungry.pressed.connect(func() -> void: hunger_requested.emit())
	add_child(hungry)
	var coins := Button.new()
	coins.text = "Spawn coins"
	coins.pressed.connect(func() -> void: coins_requested.emit())
	add_child(coins)
	var invasion := Button.new()
	invasion.text = "Invader"
	invasion.pressed.connect(func() -> void: invasion_requested.emit())
	add_child(invasion)

func _exit_tree() -> void:
	Engine.time_scale = 1.0
