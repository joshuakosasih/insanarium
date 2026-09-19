extends SceneTree
## Ten minutes of deterministic attentive care, separate from movement accuracy.
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var profile := FishProfile.new()
	var growth := FishGrowth.new()
	var hunger: float = 0.0
	var first_adult: int = -1
	var meals: int = 0
	for second in range(600):
		hunger += profile.hunger_rate
		if hunger >= profile.hungry_threshold:
			hunger = maxf(0.0, hunger - FeedProfile.new().nutrition)
			growth.record_meal(profile)
			meals += 1
			if growth.stage == 1 and first_adult < 0:
				first_adult = second + 1
	assert(first_adult >= 480 and first_adult <= 540)
	assert(growth.stage == 1 and meals >= 10 and meals <= 12)
	assert(100 - meals * 2 * 2 >= 50, "starting wallet can feed two fish for ten minutes without bubbles or coins")
	print("PASS: ten-minute opening; adult at ", first_adult, "s; meals/fish=", meals, "; base food expense=$", meals * 4)
	quit()
