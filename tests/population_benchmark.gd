extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	seed(12)
	ActivityPace.set_idle(false)
	for population in [20, 50, 100, 250]:
		var habitat := Node2D.new()
		root.add_child(habitat)
		var fish_list: Array[AquariumFish] = []
		for i in range(population):
			var fish := AquariumFish.new()
			fish.profile = FishProfile.new()
			fish.bounds = Rect2(85, 197, 982, 443)
			fish.position = Vector2(randf_range(100, 1000), 500)
			habitat.add_child(fish)
			fish.set_process(false)
			fish_list.append(fish)
		for i in range(80):
			var food := FishFood.new()
			food.position = Vector2(randf_range(100, 1000), 210)
			habitat.add_child(food)
			food.set_process(false)
		var timings: Array[float] = []
		for frame in range(180):
			var start: int = Time.get_ticks_usec()
			for fish in fish_list:
				# Force repeated searches: deliberately expensive decision workload.
				fish.position.y = 500 # Keep all 80 food candidates out of eating range.
				fish.food_target = null
				fish.hunger = 0.8
				fish._process(1.0 / 60.0)
			timings.append((Time.get_ticks_usec() - start) / 1000.0)
			await process_frame
			if frame == 179:
				timings.sort()
				print("POPULATION=", population, " CPU median_ms=", timings[90], " p95_ms=", timings[171], " (headless behavior only, 80 food)")
		habitat.queue_free()
		await process_frame
	quit()
