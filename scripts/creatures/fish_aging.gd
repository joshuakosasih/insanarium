class_name FishAging
extends RefCounted
## Deterministic lifespan model shared by live fish, inspection, and offline catch-up.
const BASE_LIFESPAN: float = 21600.0 # Six hours of simulation time.
const SENIOR_START: float = 0.80

static func lifespan_for(genome: FishGenome) -> float:
	return lifespan_from_values(genome.metabolism_value(), genome.vitality_value())

static func lifespan_from_data(genome_data: Dictionary) -> float:
	return lifespan_from_values(
		FishGenome.phenotype_from_data(genome_data, "metabolism"),
		FishGenome.phenotype_from_data(genome_data, "vitality"))

static func lifespan_from_values(metabolism: float, vitality: float) -> float:
	# Fast metabolism buys activity at the cost of age. Vitality can offset it,
	# but cannot make the tradeoff disappear completely.
	var metabolism_factor: float = lerpf(1.20, 0.75, clampf(metabolism, 0.0, 1.0))
	var vitality_factor: float = lerpf(0.75, 1.30, clampf(vitality, 0.0, 1.0))
	return BASE_LIFESPAN * metabolism_factor * vitality_factor

static func phase(age: float, lifespan: float) -> String:
	var ratio: float = clampf(age / maxf(1.0, lifespan), 0.0, 1.0)
	if ratio >= SENIOR_START:
		return "Senior"
	if ratio >= 0.35:
		return "Mature"
	return "Young"
