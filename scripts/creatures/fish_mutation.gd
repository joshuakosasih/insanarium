class_name FishMutation
extends RefCounted
const NAMES := ["Normal", "Azure", "Rose", "Jade"]
const COLORS := [Color("f6be73"), Color("75cdf2"), Color("ee95c7"), Color("83e4b7")]
var variant: int = 0

func roll(chance: float = 0.08) -> bool:
	if variant != 0 or randf() >= chance:
		return false
	variant = randi_range(1, 3)
	return true

func sell_value(stage: int) -> int:
	return [15, 120, 350, 1200][clampi(stage, 0, 3)] * (2 if variant > 0 else 1)
