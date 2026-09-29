extends SceneTree
var failures: int = 0

func check(ok: bool, description: String) -> void:
	if not ok:
		failures += 1
		push_error(description)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var director := InvasionDirector.new()
	director.tank_index = 2
	root.add_child(director)
	director.set_process(false)
	check(is_equal_approx(director.hunter_chance, 1.0 / 3.0), "Tank 2 draws blue and hunter aliens at a two-to-one ratio")
	director.hunter_chance = 0.0
	check(not director.draw_next_hunter(), "zero hunter chance always selects the blue alien")
	director.hunter_chance = 1.0
	check(director.draw_next_hunter(), "full hunter chance always selects the hunter")
	director.tank_index = 1
	check(not director.draw_next_hunter(), "Tank 1 only draws the original blue alien")
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
	hunter.free()
	var blue := TankAlien.new()
	blue.bounds = piranha.bounds
	blue.position = Vector2(350, 300)
	habitat.add_child(blue)
	blue.set_process(false)
	var guppy := AquariumFish.new()
	guppy.profile = FishProfile.new()
	guppy.bounds = piranha.bounds
	guppy.position = Vector2(420, 300)
	habitat.add_child(guppy)
	guppy.set_process(false)
	guppy.genome.speed = PackedFloat32Array([0.0, 0.0])
	guppy._process(0.1)
	var slow_escape: float = guppy.position.x - 420.0
	guppy.position = Vector2(420, 300)
	guppy.genome.speed = PackedFloat32Array([1.0, 1.0])
	guppy._process(0.1)
	check(slow_escape > 0.0 and guppy.position.x - 420.0 > slow_escape * 2.0, "guppies flee nearby blue aliens and high Agility makes escape substantially faster")
	guppy.genome.speed = PackedFloat32Array([0.0, 0.0])
	var low_pursuit: float = guppy.pursuit_multiplier()
	guppy.genome.speed = PackedFloat32Array([1.0, 1.0])
	check(guppy.pursuit_multiplier() > low_pursuit, "Agility improves active food and prey pursuit")
	piranha.genome.speed = PackedFloat32Array([0.0, 0.0])
	var slow_bite: float = piranha.alien_bite_interval()
	piranha.genome.speed = PackedFloat32Array([1.0, 1.0])
	check(piranha.alien_bite_interval() < slow_bite * 0.6, "high-Agility piranhas bite blue aliens much more often")
	print("Tank 2 hunter failures: ", failures)
	quit(1 if failures else 0)
