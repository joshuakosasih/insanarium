class_name FishGenome
extends RefCounted
## Two-allele inheritable traits. The UI exposes phenotypes, while alleles remain hidden.
const MUTATION_CHANCE: float = 0.03
const MUTATION_RANGE: float = 0.08
var metabolism: PackedFloat32Array = PackedFloat32Array([0.5, 0.5])
var allocation: PackedFloat32Array = PackedFloat32Array([0.5, 0.5])
var vitality: PackedFloat32Array = PackedFloat32Array([0.5, 0.5])
var speed: PackedFloat32Array = PackedFloat32Array([0.5, 0.5])
const MIN_MAX_HEALTH: float = 70.0
const MAX_MAX_HEALTH: float = 130.0
const MIN_SPEED_MULTIPLIER: float = 0.75
const MAX_SPEED_MULTIPLIER: float = 1.25

func randomize_traits() -> void:
	metabolism = PackedFloat32Array([randf_range(0.2, 0.8), randf_range(0.2, 0.8)])
	allocation = PackedFloat32Array([randf_range(0.2, 0.8), randf_range(0.2, 0.8)])
	vitality = PackedFloat32Array([randf_range(0.2, 0.8), randf_range(0.2, 0.8)])
	speed = PackedFloat32Array([randf_range(0.2, 0.8), randf_range(0.2, 0.8)])

static func inherit(father: FishGenome, mother: FishGenome) -> FishGenome:
	var child := FishGenome.new()
	child.metabolism = PackedFloat32Array([mutate(father.metabolism[randi_range(0, 1)]), mutate(mother.metabolism[randi_range(0, 1)])])
	child.allocation = PackedFloat32Array([mutate(father.allocation[randi_range(0, 1)]), mutate(mother.allocation[randi_range(0, 1)])])
	child.vitality = PackedFloat32Array([mutate(father.vitality[randi_range(0, 1)]), mutate(mother.vitality[randi_range(0, 1)])])
	child.speed = PackedFloat32Array([mutate(father.speed[randi_range(0, 1)]), mutate(mother.speed[randi_range(0, 1)])])
	return child

static func mutate(value: float) -> float:
	if randf() < MUTATION_CHANCE:
		value += randf_range(-MUTATION_RANGE, MUTATION_RANGE)
	return clampf(value, 0.0, 1.0)

func metabolism_value() -> float:
	return (metabolism[0] + metabolism[1]) * 0.5

func allocation_value() -> float:
	return (allocation[0] + allocation[1]) * 0.5

func vitality_value() -> float:
	return (vitality[0] + vitality[1]) * 0.5

func speed_value() -> float:
	return (speed[0] + speed[1]) * 0.5

func max_health() -> float:
	return max_health_for(vitality_value())

func speed_multiplier() -> float:
	return speed_multiplier_for(speed_value())

func hunger_multiplier() -> float:
	return hunger_multiplier_for(metabolism_value())

func growth_multiplier() -> float:
	return growth_multiplier_for(metabolism_value())

func output_interval(base_interval: float) -> float:
	return output_interval_for(base_interval, metabolism_value())

func coin_chance() -> float:
	return coin_chance_for(allocation_value())

func constitution() -> float:
	return constitution_for(allocation_value())

static func speed_multiplier_for(value: float) -> float:
	return lerpf(MIN_SPEED_MULTIPLIER, MAX_SPEED_MULTIPLIER, clampf(value, 0.0, 1.0))

static func max_health_for(value: float) -> float:
	return lerpf(MIN_MAX_HEALTH, MAX_MAX_HEALTH, clampf(value, 0.0, 1.0))

static func hunger_multiplier_for(value: float) -> float:
	return lerpf(0.75, 1.35, clampf(value, 0.0, 1.0))

static func growth_multiplier_for(value: float) -> float:
	return lerpf(0.85, 1.20, clampf(value, 0.0, 1.0))

static func output_interval_for(base_interval: float, value: float) -> float:
	return base_interval * lerpf(1.25, 0.70, clampf(value, 0.0, 1.0))

static func coin_chance_for(value: float) -> float:
	return lerpf(0.55, 0.90, clampf(value, 0.0, 1.0))

static func constitution_for(value: float) -> float:
	return lerpf(1.20, 0.80, clampf(value, 0.0, 1.0))

func metabolism_label() -> String:
	var value := metabolism_value()
	return "Slow" if value < 0.4 else ("Fast" if value > 0.6 else "Balanced")

func allocation_label() -> String:
	var value := allocation_value()
	return "Conservative" if value < 0.4 else ("Productive" if value > 0.6 else "Balanced")

func to_data() -> Dictionary:
	return {"metabolism": Array(metabolism), "allocation": Array(allocation),
		"vitality": Array(vitality), "speed": Array(speed)}

func from_data(data: Dictionary) -> void:
	metabolism = read_pair(data.get("metabolism", [0.5, 0.5]))
	allocation = read_pair(data.get("allocation", [0.5, 0.5]))
	vitality = read_pair(data.get("vitality", [0.5, 0.5]))
	speed = read_pair(data.get("speed", [0.5, 0.5]))

static func phenotype_from_data(data: Dictionary, trait_name: String) -> float:
	var pair: Array = data.get(trait_name, [0.5, 0.5])
	if pair.size() != 2:
		return 0.5
	return clampf((float(pair[0]) + float(pair[1])) * 0.5, 0.0, 1.0)

static func read_pair(value: Variant) -> PackedFloat32Array:
	if not value is Array or value.size() != 2:
		return PackedFloat32Array([0.5, 0.5])
	return PackedFloat32Array([clampf(float(value[0]), 0.0, 1.0), clampf(float(value[1]), 0.0, 1.0)])
