class_name FishProfile
extends Resource
## Species data, separate from the creature's runtime state.
@export var species_id: String = "starter_fish"
@export var species_name: String = "Amberfin"
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
