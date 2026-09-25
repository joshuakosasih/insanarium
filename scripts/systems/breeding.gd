class_name FishBreeding
extends RefCounted
## One offspring maximum per check; both parents share a cooldown.
signal offspring_requested(at: Vector2, father_id: String, mother_id: String)
const CAPACITY: int = 20
const BREEDING_LIMIT: int = CAPACITY
const COMFORT_WARNING: int = 16
const POPULATION_GOAL: int = 15
const INTERVAL: float = 30.0
const COOLDOWN: float = 300.0 # Neutral reference; genomes set the actual cooldown.
var enabled: bool = true
var check_left: float = INTERVAL
var chance: float = 0.25

func advance(delta: float, fish_list: Array) -> void:
	for fish in fish_list:
		fish.breeding_left = maxf(0.0, fish.breeding_left - delta)
	check_left -= delta
	if check_left > 0.0:
		return
	check_left = INTERVAL
	if not enabled or fish_list.size() >= BREEDING_LIMIT:
		return
	var males: Array = []
	var females: Array = []
	for fish in fish_list:
		if fish.dead or fish.is_queued_for_deletion() or fish.growth.stage < 2 or fish.hunger >= fish.profile.hungry_threshold or fish.breeding_left > 0.0:
			continue
		if fish.sex == AquariumFish.Sex.MALE:
			males.append(fish)
		elif fish.sex == AquariumFish.Sex.FEMALE:
			females.append(fish)
	if males.is_empty() or females.is_empty() or randf() >= chance:
		return
	var male = males.pick_random()
	var female = females.pick_random()
	male.breeding_left = male.genome.breeding_cooldown()
	female.breeding_left = female.genome.breeding_cooldown()
	offspring_requested.emit((male.position + female.position) * 0.5, male.life.id, female.life.id)
