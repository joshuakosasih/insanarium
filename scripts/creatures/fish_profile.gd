class_name FishProfile
extends Resource
## Species data, separate from the creature's runtime state.
@export var species_id: String = "starter_fish"
@export var species_name: String = "Guppy"
@export var swim_speed: float = 55.0
@export var hunger_rate: float = 1.0 / 120.0
@export var hungry_threshold: float = 0.42
@export var detection_radius: float = 1000.0
@export var coin_interval: float = 20.0
@export var coin_value: int = 1
@export var body_color: Color = Color("f6be73")

# Parallel stage arrays: cumulative growth credits, visual size, and reward multiplier.
@export var growth_meals: PackedInt32Array = PackedInt32Array([0, 2, 10, 30, 75])
@export var growth_sizes: PackedFloat32Array = PackedFloat32Array([0.45, 0.70, 1.0, 1.2, 1.35])
@export var growth_rewards: PackedInt32Array = PackedInt32Array([0, 1, 2, 3, 10])
@export var growth_names: PackedStringArray = PackedStringArray(["Baby", "Teen", "Adult", "Royal", "Diamond"])

@export var minimum_meals: PackedInt32Array = PackedInt32Array([0, 0, 0, 0, 75])
@export var diamond_stage: int = 4
@export var diamond_growth_chance: float = 0.25

@export var starvation_grace: float = 45.0

# Empty prey_species_id means this species never hunts other fish.
@export var prey_species_id: String = ""
@export var max_prey_stage: int = -1
@export var hunter_stage: int = 2
@export var predation_hunger: float = 0.62
@export var prey_nutrition: float = 0.78
@export var prey_growth_credit: int = 2
@export var prey_detection_radius: float = 520.0
@export var alien_defense_stage: int = -1
@export var max_growth_stage: int = 4
@export var maximum_lifespan: float = INF
@export var produces_only_waste: bool = false
@export var feeder_for_species_id: String = ""
@export var prey_priority: int = 0

static func for_species(id: String) -> FishProfile:
	var profile := FishProfile.new()
	if id == "piranha":
		profile.species_id = "piranha"
		profile.species_name = "Piranha"
		profile.swim_speed = 78.0
		profile.hunger_rate = 1.0 / 300.0
		profile.starvation_grace = 120.0
		profile.coin_interval = 28.0
		profile.coin_value = 2
		profile.body_color = Color("dd6c63")
		profile.growth_meals = PackedInt32Array([0, 2, 10, 30, 75])
		profile.growth_sizes = PackedFloat32Array([0.65, 0.92, 1.25, 1.45, 1.60])
		profile.growth_rewards = PackedInt32Array([0, 4, 8, 12, 20])
		profile.growth_names = PackedStringArray(["Baby", "Teen", "Adult", "Prime", "Diamond"])
		profile.diamond_growth_chance = 1.0
		profile.prey_species_id = "starter_fish"
		profile.max_prey_stage = 1
		profile.hunter_stage = 2
		profile.prey_nutrition = 0.85
		profile.alien_defense_stage = 2
	elif id == "feeder_guppy":
		profile.species_id = "feeder_guppy"
		profile.species_name = "Feeder Fry"
		profile.body_color = Color("a7d8b5")
		profile.hunger_rate = 1.0 / 240.0
		profile.starvation_grace = 120.0
		profile.growth_sizes = PackedFloat32Array([0.45, 0.70, 0.70, 0.70, 0.70])
		profile.max_growth_stage = 1
		profile.maximum_lifespan = 900.0
		profile.produces_only_waste = true
		profile.feeder_for_species_id = "piranha"
		profile.prey_priority = 1
	return profile

func eats_pellets_at(stage: int) -> bool:
	return prey_species_id.is_empty() or stage < hunter_stage

func hunger_rate_at(stage: int) -> float:
	return 1.0 / 120.0 if not prey_species_id.is_empty() and stage < hunter_stage else hunger_rate

func reward_is_diamond(stage: int) -> bool:
	return stage >= diamond_stage or (not prey_species_id.is_empty() and stage >= hunter_stage)

func reward_grade(stage: int) -> int:
	if not prey_species_id.is_empty() and stage >= 1:
		return 4 if reward_is_diamond(stage) else 3
	return stage
