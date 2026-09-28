extends SceneTree
var failures: int = 0

func check(ok: bool, description: String) -> void:
	if not ok:
		failures += 1
		push_error(description)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var habitat := Node2D.new()
	root.add_child(habitat)
	var piranha := AquariumFish.new()
	piranha.profile = FishProfile.for_species("piranha")
	piranha.growth.stage = 2
	piranha.bounds = Rect2(100, 100, 600, 400)
	piranha.position = Vector2(420, 300)
	habitat.add_child(piranha)
	piranha.set_process(false)
	var hunter := TankAlien.new()
	hunter.threatens_piranhas = true
	hunter.bounds = piranha.bounds
	hunter.position = Vector2(350, 300)
	habitat.add_child(hunter)
	hunter.set_process(false)
	var before: Vector2 = piranha.position
	piranha._process(0.1)
	check(piranha.position.x > before.x and hunter.health == hunter.max_health, "adult piranha flees the Tank 2 hunter instead of biting it")
	hunter.position = piranha.position + Vector2(-20, 0)
	hunter._process(0.1)
	check(piranha.dead, "Tank 2 hunter can kill an adult piranha")
	print("Tank 2 hunter failures: ", failures)
	quit(1 if failures else 0)
