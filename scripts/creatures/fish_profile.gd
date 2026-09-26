class_name FishProfile
extends Resource
## Species data, separate from the creature's runtime state.
@export var species_id: String = "starter_fish"
@export var species_name: String = "Guppy"
@export var swim_speed: float = 72.0
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

@export var starvation_grace: float = 45.0

# Empty prey_species_id means this species never hunts other fish.
@export var prey_species_id: String = ""
@export var max_prey_stage: int = -1
@export var hunter_stage: int = 1
@export var predation_hunger: float = 0.62
@export var prey_nutrition: float = 0.78
@export var prey_growth_credit: int = 2
@export var prey_detection_radius: float = 520.0

static func for_species(id: String) -> FishProfile:
	var profile := FishProfile.new()
	if id == "piranha":
		profile.species_id = "piranha"
		profile.species_name = "Piranha"
		profile.swim_speed = 105.0
		profile.hunger_rate = 1.0 / 105.0
		profile.coin_interval = 28.0
		profile.coin_value = 2
		profile.body_color = Color("dd6c63")
		profile.growth_meals = PackedInt32Array([0, 2, 10, 30, 75])
		profile.growth_sizes = PackedFloat32Array([0.50, 0.78, 1.08, 1.25, 1.40])
		profile.growth_names = PackedStringArray(["Baby", "Teen", "Adult", "Prime", "Diamond"])
		profile.prey_species_id = "starter_fish"
		profile.max_prey_stage = 1
		profile.hunter_stage = 2
	return profile
