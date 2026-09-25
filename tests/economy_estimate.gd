extends SceneTree
## Analytical active-play estimate. This complements simulation tests; it is not a promise about play time.

const BUBBLE_CAPTURE_RATE := 0.80
const COIN_CAPTURE_RATE := 0.85
const MEAN_BUBBLE_INTERVAL := 4.0
const MEAN_BUBBLE_VALUE := 1.625
const MEAN_METABOLISM := 0.50
const MEAN_ALLOCATION := 0.50

func _initialize() -> void:
	var profile := FishProfile.new()
	var output_interval: float = FishGenome.output_interval_for(profile.coin_interval, MEAN_METABOLISM)
	var coin_chance: float = FishGenome.coin_chance_for(MEAN_ALLOCATION)
	var collected_events_per_fish_minute: float = 60.0 / output_interval * coin_chance * COIN_CAPTURE_RATE
	var bubbles_per_minute: float = 60.0 / MEAN_BUBBLE_INTERVAL * MEAN_BUBBLE_VALUE * BUBBLE_CAPTURE_RATE
	var meals_per_fish_minute: float = profile.hunger_rate * FishGenome.hunger_multiplier_for(MEAN_METABOLISM) / profile.hungry_threshold * 60.0
	var feed_cost_per_fish_minute: float = meals_per_fish_minute * FeedProfile.new().price
	var early_net: float = bubbles_per_minute + collected_events_per_fish_minute * 2.0 - feed_cost_per_fish_minute * 2.0
	var established_net: float = bubbles_per_minute + collected_events_per_fish_minute * 5.0 * 2.0 * 2.0 - feed_cost_per_fish_minute * 5.0
	print("BALANCE ASSUMPTIONS: 80% bubbles, 85% coins, mean genes, prompt Basic feeding")
	print("Expected net $/active minute: two Teens x1=%.2f; five Adults x2=%.2f" % [early_net, established_net])
	var increments := [1, 1, 2, 3]
	for level in range(IdleAssets.COIN_VALUE_PRICES.size()):
		var early_payback: float = float(IdleAssets.COIN_VALUE_PRICES[level]) / (collected_events_per_fish_minute * 2.0 * int(increments[level]))
		var established_payback: float = float(IdleAssets.COIN_VALUE_PRICES[level]) / (collected_events_per_fish_minute * 5.0 * 2.0 * int(increments[level]))
		print("Coin upgrade %d: $%d; payback %.1fm early / %.1fm established" % [level + 1, IdleAssets.COIN_VALUE_PRICES[level], early_payback, established_payback])
	assert(IdleAssets.COIN_VALUE_PRICES[0] / (collected_events_per_fish_minute * 2.0) >= 45.0, "first global coin multiplier should not repay itself immediately in the opening")
	assert(IdleAssets.COIN_VALUE_PRICES[0] / (collected_events_per_fish_minute * 5.0 * 2.0) >= 8.0, "first global coin multiplier should remain a meaningful established-tank purchase")
	quit()
