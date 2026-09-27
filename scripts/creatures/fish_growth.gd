class_name FishGrowth
extends RefCounted
## Per-creature progression. Profiles supply cumulative meal thresholds.
signal stage_changed(stage: int)
var meals: int = 0
var stage: int = 0
var growth_credit: float = 0.0
var diamond_trial_done: bool = false
var diamond_bag: FishDiamondBag

func record_meal(profile: FishProfile, credit: int = 1, multiplier: float = 1.0) -> void:
	meals += 1
	growth_credit += maxi(0, credit) * maxf(0.0, multiplier)
	var next_stage: int = stage
	for i in range(profile.growth_meals.size()):
		if growth_credit >= profile.growth_meals[i] and meals >= profile.minimum_meals[i]:
			if i == profile.diamond_stage and stage < i:
				if not diamond_trial_done:
					diamond_trial_done = true
					var awarded: bool = diamond_bag.draw() if diamond_bag != null else randf() < profile.diamond_growth_chance
					if not awarded:
						continue
				else:
					continue
			next_stage = maxi(next_stage, i)
	if next_stage != stage:
		stage = next_stage
		stage_changed.emit(stage)
