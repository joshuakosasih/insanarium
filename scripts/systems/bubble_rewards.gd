class_name BubbleRewards
extends Resource
## Reward tuning lives separately from appearance and spawning for future upgrades.
@export var amounts: PackedFloat64Array = PackedFloat64Array([0.5, 1.0, 2.0, 3.0])
@export var multiplier: float = 1.0

func roll(rng: RandomNumberGenerator) -> float:
	return snappedf(amounts[rng.randi_range(0, amounts.size() - 1)] * multiplier, 0.01)
