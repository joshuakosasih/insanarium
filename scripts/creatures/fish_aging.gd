class_name FishAging
extends RefCounted
## Deterministic lifespan model shared by live fish, inspection, and offline catch-up.
const BASE_LIFESPAN: float = 21600.0 # Six hours of simulation time.
const SENIOR_START: float = 0.80

static func lifespan_for(genome: FishGenome) -> float:
	return lifespan_from_values(genome.metabolism_value(), genome.allocation_value())

static func lifespan_from_data(genome_data: Dictionary) -> float:
	return lifespan_from_values(
		FishGenome.phenotype_from_data(genome_data, "metabolism"),
		FishGenome.phenotype_from_data(genome_data, "allocation"))

static func lifespan_from_values(metabolism: float, allocation: float) -> float:
	# Fast metabolisms trade longevity for activity. Conservative allocation's
	# stronger constitution also extends life, so existing genes matter over time.
	var metabolism_factor: float = lerpf(1.20, 0.80, clampf(metabolism, 0.0, 1.0))
	return BASE_LIFESPAN * metabolism_factor * FishGenome.constitution_for(allocation)

static func phase(age: float, lifespan: float) -> String:
	var ratio: float = clampf(age / maxf(1.0, lifespan), 0.0, 1.0)
	if ratio >= SENIOR_START:
		return "Senior"
	if ratio >= 0.35:
		return "Mature"
	return "Young"
