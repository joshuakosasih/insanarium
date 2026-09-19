extends SceneTree
var failures: int = 0

func check(ok: bool, description: String) -> void:
	if ok:
		print("PASS: ", description)
	else:
		failures += 1
		push_error(description)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var tank = load("res://scenes/aquarium.tscn").instantiate()
	root.add_child(tank)
	tank.set_process(false)
	for fish in get_nodes_in_group("fish"):
		fish.set_process(false)
	var falling_coin = tank.spawn_coin(Vector2(500, 500), 1)
	var full_lifetime: float = falling_coin.lifetime
	falling_coin._process(4.0)
	check(not falling_coin.grounded and falling_coin.lifetime == full_lifetime and falling_coin.modulate.a == 1.0, "coin preservation timer does not run while falling")
	falling_coin._process(1.0)
	check(falling_coin.grounded and falling_coin.lifetime == full_lifetime, "coin lands before its preservation countdown begins")
	falling_coin._process(full_lifetime - TankCoin.FADE_DURATION - 0.1)
	check(falling_coin.modulate.a == 1.0, "coin remains opaque through most of its floor lifetime")
	falling_coin._process(0.2)
	check(falling_coin.modulate.a < 1.0, "coin begins a short final fade")
	var initial_cleanliness: float = tank.environment.cleanliness
	var waste = tank.spawn_waste(Vector2(420, 400))
	check(waste != null and get_nodes_in_group("waste").size() == 1 and tank.environment.cleanliness < initial_cleanliness, "fish waste is visible and pollutes the tank")
	tank.handle_tank_click(waste.position)
	check(get_nodes_in_group("waste").is_empty() and tank.environment.cleanliness == initial_cleanliness, "clicking waste removes it and restores cleanliness")
	var expiring_waste = tank.spawn_waste(Vector2(500, 642))
	expiring_waste._process(0.0)
	expiring_waste._process(FishWaste.FLOOR_LIFETIME - FishWaste.FADE_DURATION - 0.1)
	check(expiring_waste.modulate.a == 1.0, "settled waste stays opaque until its short final fade")
	expiring_waste._process(0.2)
	check(expiring_waste.modulate.a < 1.0, "waste fades near expiry")
	expiring_waste._process(FishWaste.FADE_DURATION)
	check(expiring_waste.is_queued_for_deletion(), "uncleaned waste disappears on its fixed timer")
	var pellet = tank.spawn_food(Vector2(450, 400), tank.feeds[0])
	pellet.set_process(false)
	var before_spoil: float = tank.environment.cleanliness
	pellet._process(15.0)
	check(tank.environment.cleanliness == before_spoil - TankEnvironment.SPOILED_PELLET_POLLUTION, "expired food pollutes the water")
	var before_bioload: float = tank.environment.cleanliness
	tank.environment.advance(100.0, 2, 0)
	check(tank.environment.cleanliness < before_bioload, "living creatures create gradual biological load")
	tank.environment.cleanliness = 35.0
	tank.update_cleanliness()
	check(tank.water_overlay.murk_strength(tank.environment.cleanliness) > 0.5 and not tank.clean_button.disabled, "dirty water creates strong visible haze and enables full cleaning")
	var clean_price: float = TankEnvironment.FULL_CLEAN_COST
	var money_before_clean: float = tank.economy.money
	var lingering_waste = tank.spawn_waste(Vector2(520, 642))
	tank.purchase_full_clean()
	check(tank.environment.cleanliness == 100.0 and tank.economy.money == money_before_clean - clean_price and lingering_waste.is_queued_for_deletion(), "paid full clean restores pristine water and removes visible waste")
	var money_after_clean: float = tank.economy.money
	tank.purchase_full_clean()
	check(tank.economy.money == money_after_clean, "full clean cannot charge an already pristine tank")
	var health := FishHealth.new()
	health.current = 50.0
	health.advance(100.0, 80.0)
	check(is_equal_approx(health.current, 70.0), "very clean water quickly restores a well-fed fish")
	var hungry_health := FishHealth.new()
	hungry_health.current = 50.0
	hungry_health.advance(100.0, 100.0, 1.0, false)
	check(hungry_health.current == 50.0, "hungry fish cannot regenerate even in pristine water")
	var pristine_rate: float = FishHealth.rate_for_conditions(100.0, true)
	var clear_rate: float = FishHealth.rate_for_conditions(70.0, true)
	check(pristine_rate > clear_rate and clear_rate > 0.0, "recovery accelerates as clean water becomes pristine")
	var before_cloudy: float = health.current
	health.advance(100.0, 60.0)
	check(health.current < before_cloudy, "sixty-percent cloudy water already damages fish")
	var damage_50: float = -FishHealth.rate_for_cleanliness(50.0)
	var damage_40: float = -FishHealth.rate_for_cleanliness(40.0)
	var damage_30: float = -FishHealth.rate_for_cleanliness(30.0)
	var damage_0: float = -FishHealth.rate_for_cleanliness(0.0)
	check(damage_40 > damage_50 * 3.0 and damage_30 > damage_40 * 3.0 and damage_0 > damage_30 * 20.0, "water damage grows geometrically as cleanliness falls")
	var zero_water_health := FishHealth.new()
	check(zero_water_health.advance(6.0, 0.0), "zero-percent cleanliness kills a healthy neutral fish within seconds")
	var survivor = get_nodes_in_group("fish")[0]
	survivor.health.current = 77.0
	var data: Dictionary = tank.snapshot()
	check(data.has("cleanliness") and data.has("waste") and data.fish[0].health == 77.0 and not BackupValidation.parse(JSON.stringify(data)).is_empty(), "cleanliness and fish health are saved and backup-valid")
	var vulnerable = get_nodes_in_group("fish")[1]
	vulnerable.health.current = 0.02
	tank.environment.cleanliness = 0.0
	tank._process(1.0)
	check(vulnerable.dead, "toxic water can kill a fish whose health reaches zero")
	print("Environment failures: ", failures)
	quit(1 if failures else 0)
