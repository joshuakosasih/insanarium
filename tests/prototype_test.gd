extends SceneTree
const BubblePufferScript = preload("res://scripts/pets/bubble_puffer.gd")
var failures: int = 0
var checks: int = 0

func check(ok: bool, description: String) -> void:
	checks += 1
	if ok:
		print("PASS: ", description)
	else:
		push_error(description)
		failures += 1

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	seed(42)
	var tank = load("res://scenes/aquarium.tscn").instantiate()
	root.add_child(tank)
	await process_frame
	tank.set_process(false)
	for fish in get_nodes_in_group("fish"):
		fish.set_process(false)
	var sample_tank_point := Vector2(500, 400)
	var sample_viewport_point: Vector2 = tank.get_global_transform_with_canvas() * sample_tank_point
	check(tank.viewport_to_tank(sample_viewport_point).is_equal_approx(sample_tank_point), "pointer conversion reverses the complete scaled and centered canvas transform")
	check(tank.position.y + tank.tank_rect.end.y <= tank.get_viewport_rect().size.y - tank.TANK_BOTTOM_MARGIN, "short viewports retain a safe margin below the tank")
	check(tank.tank_rect.size.x == tank.STARTER_TANK_WIDTH, "starter tank keeps one consistent world width across devices")
	var visible_tank_left: float = tank.position.x + tank.tank_rect.position.x
	var visible_tank_right: float = tank.position.x + tank.tank_rect.end.x
	check(is_equal_approx(visible_tank_left, tank.get_viewport_rect().size.x - visible_tank_right), "starter tank remains centered in the available viewport")
	var visible_tank_top: float = tank.position.y + tank.tank_rect.position.y
	var visible_tank_bottom: float = tank.position.y + tank.tank_rect.end.y
	check(tank.controls_button.position.y + tank.controls_button.size.y < visible_tank_top and tank.shop_button.position.y + tank.shop_button.size.y < visible_tank_top, "shop and controls occupy the header above the tank")
	check(tank.feed_label.position.y > visible_tank_bottom and tank.feed_status.position.y > visible_tank_bottom and tank.footer_hint.position.y > visible_tank_bottom, "feeding and help text occupy the footer below the tank")
	var pointer_event := InputEventMouseButton.new()
	pointer_event.button_index = MOUSE_BUTTON_LEFT
	pointer_event.pressed = true
	pointer_event.position = sample_viewport_point
	tank._unhandled_input(pointer_event)
	var pointer_food = get_nodes_in_group("food")[0]
	check(pointer_food.position.is_equal_approx(sample_tank_point), "scaled mouse clicks drop food at the visible tank position")
	pointer_food.free()
	tank.economy.credit(2)
	tank.food_cooldown = 0.0
	check(ProjectSettings.get_setting("input_devices/pointing/emulate_mouse_from_touch", false), "touch is translated into mouse input for buttons and panels")
	var tapped_bubble = tank.spawn_income_bubble()
	tapped_bubble.position = sample_tank_point
	tapped_bubble.value = 1.0
	var before_bubble_tap: float = tank.economy.money
	tank.last_pointer_msec = -1000
	var touch_event := InputEventScreenTouch.new()
	touch_event.pressed = true
	touch_event.position = sample_viewport_point
	tank._unhandled_input(touch_event)
	check(not tapped_bubble.claimed and tank.economy.money == before_bubble_tap, "raw touch waits for Godot's single synthesized mouse event")
	var synthetic_mouse := InputEventMouseButton.new()
	synthetic_mouse.button_index = MOUSE_BUTTON_LEFT
	synthetic_mouse.pressed = true
	synthetic_mouse.position = sample_viewport_point
	tank._unhandled_input(synthetic_mouse)
	check(tapped_bubble.claimed and tank.economy.money == before_bubble_tap + 1.0 and get_nodes_in_group("food").is_empty(), "a mobile bubble tap resolves once without also dropping food")
	check(get_nodes_in_group("fish").size() == 2 and get_nodes_in_group("pets").is_empty(), "two normal fish and no free pets")
	check(not tank.shop_panel.visible and tank.shop_cards.size() == 12, "shop starts closed with reusable product cards")
	check(tank.shop_cards.fish.discovered and not tank.shop_cards.snail.discovered and not tank.shop_cards.shrimp.discovered and not tank.shop_cards.feed.discovered and not tank.shop_cards.coins.discovered and not tank.shop_cards.diamond_value.discovered, "unowned pets and untouched upgrades begin as shop silhouettes")
	check(tank.shop_scroll.scroll_deadzone == 8, "shop catalog uses a short touch-drag threshold")
	check(tank.shop_cards.snail.icon_preview.icon_kind == "snail" and tank.shop_cards.snail.icon_preview.material != null, "hidden products reuse their exact artwork through a grayscale material")
	tank.shop_button.pressed.emit()
	check(tank.shop_panel.visible and tank.menu_paused and paused, "shop button opens its panel and pauses the tank")
	var shop_drag := InputEventScreenDrag.new()
	shop_drag.relative = Vector2(0, -120)
	tank.shop_cards.fish._gui_input(shop_drag)
	check(tank.shop_scroll.scroll_vertical > 0, "dragging directly over a shop card scrolls the catalog")
	tank.toggle_shop()
	check(not tank.menu_paused and not paused, "closing the shop resumes the tank")
	tank.controls_button.pressed.emit()
	check(tank.care_panel.visible and tank.menu_paused and paused, "controls button opens its panel and pauses the tank")
	tank.toggle_controls()
	check(not tank.menu_paused and not paused, "closing controls resumes the tank")
	check(tank.invasions.running and tank.challenges, "alien encounters are enabled during active play by default")
	check(Economy.fish_price(2) == 50 and Economy.fish_price(10) == 2745 and Economy.fish_price(19) == 249000, "fish purchase price climbs steeply with population")
	var fish = get_nodes_in_group("fish")[0]
	check(fish.mutation.variant == 0 and fish.current_coin_value() == 0, "normal fish start amber and babies do not produce coins")
	var balance: int = tank.economy.money
	var pellet = tank.drop_food(fish.position)
	check(pellet != null and tank.economy.money == balance - 2, "basic feed costs two")
	check(tank.drop_food(fish.position) == null and tank.economy.money == balance - 2, "rejected click does not charge")
	fish.hunger = 1.0
	fish._process(0.01)
	check(pellet.consumed and fish.growth.meals == 1, "fish eats and grows")
	var mutation := FishMutation.new()
	check(not mutation.roll(0.0) and mutation.variant == 0, "zero mutation probability preserves normal fish")
	check(mutation.roll(1.0) and mutation.variant > 0, "mutation changes color variant")
	check(not mutation.roll(1.0) and mutation.sell_value(4) == 2400, "mutation occurs only once and doubles mature sale value")
	var expiring_coin = tank.spawn_coin(Vector2(500, 650), 3)
	var coin_balance: float = tank.economy.money
	expiring_coin._process(5.9)
	check(not expiring_coin.is_queued_for_deletion() and expiring_coin.modulate.a == 1.0, "grounded coin stays fully visible until its short final fade")
	expiring_coin._process(1.1)
	check(expiring_coin.modulate.a < 1.0, "coin fades only near expiry")
	expiring_coin._process(1.1)
	expiring_coin.collect()
	check(expiring_coin.is_queued_for_deletion() and tank.economy.money == coin_balance, "expired coin disappears without paying")
	fish.growth.stage = 2
	fish.mutation.variant = 1
	tank.selected_fish = fish
	balance = tank.economy.money
	tank.sell_selected()
	tank.sell_selected()
	check(tank.economy.money == balance + 240 and get_nodes_in_group("fish").size() == 1, "mutant sale pays once and removes fish")
	tank.economy.money = 0
	tank.update_money(0)
	tank.purchase_asset("snail")
	check(not tank.assets.owned.snail and tank.economy.money == 0, "unaffordable pet cannot be purchased")
	for i in range(50):
		var bubble = tank.spawn_income_bubble()
		bubble.value = 1
		tank.handle_tank_click(bubble.position)
	tank.purchase_fish()
	check(tank.economy.money == 0 and get_nodes_in_group("fish").size() == 2 and "fish added" in tank.shop_status.text.to_lower(), "click income buys a replacement fish from zero")
	check(not tank.shop_panel.visible and tank.acquisition_celebration.visible and not tank.reveal_panel.visible and tank.acquisition_celebration.icon_kind == "fish", "fish purchase starts with a centered acquisition celebration")
	tank.acquisition_celebration.finish_now()
	check(tank.reveal_panel.visible and tank.reveal_panel.heading_label.text == "NEW FISH PURCHASED" and tank.reveal_panel.trait_bars.size() == 5, "celebration hands off to the reusable five-trait reveal card")
	check(tank.reveal_panel.trait_bars[0].title == "Vitality" and tank.reveal_panel.trait_bars[4].title == "Fertility", "reveal card shows five understandable inherited traits")
	tank.show_fish_reveal(get_nodes_in_group("fish")[0], "QUEUED FISH")
	check(tank.acquisition_queue.size() == 1 and "1 waiting" in tank.reveal_panel.dismiss_button.text, "additional acquisitions queue without replacing the current card")
	tank.advance_fish_reveal()
	check(tank.acquisition_celebration.visible and not tank.reveal_panel.visible, "queued fish receives its own celebration before details")
	tank.acquisition_celebration.finish_now()
	check(tank.reveal_panel.heading_label.text == "QUEUED FISH", "dismissing advances to the next queued fish")
	tank.advance_fish_reveal()
	check(not tank.reveal_panel.visible, "final reveal dismisses cleanly")
	tank.economy.credit(2500)
	for kind in ["snail", "shrimp", "seahorse", "puffer", "feeder"]:
		balance = tank.economy.money
		tank.purchase_asset(kind)
		tank.purchase_asset(kind)
		check(tank.assets.owned[kind] and tank.economy.money == balance - tank.assets.PRICES[kind], "automation purchase charges only once: " + kind)
	check(tank.acquisition_celebration.visible and tank.acquisition_celebration.icon_kind == "snail" and tank.acquisition_queue.size() == 3, "pet purchases use the reusable celebration and queue in order")
	while tank.acquisition_celebration.visible:
		tank.acquisition_celebration.finish_now()
	check(tank.shop_cards.snail.discovered and tank.shop_cards.shrimp.discovered and tank.shop_cards.seahorse.discovered and tank.shop_cards.puffer.discovered and tank.shop_cards.feeder.discovered, "purchased helpers reveal their normal shop artwork")
	check(tank.shop_cards.snail.icon_preview.material == null, "discovery removes the grayscale material and reveals the original colors")
	for pet in get_nodes_in_group("pets"):
		pet.set_process(false)
	check(get_nodes_in_group("pets").size() == 4, "purchased pets are spawned")
	var snail: SnailPet
	var puffer
	var shrimp: CleanupShrimpPet
	var seahorse: SeahorsePet
	for pet in get_nodes_in_group("pets"):
		if pet is SnailPet:
			snail = pet
		elif pet is BubblePufferScript:
			puffer = pet
		elif pet is CleanupShrimpPet:
			shrimp = pet
		elif pet is SeahorsePet:
			seahorse = pet
	check(snail != null and snail.crawl_speed == 16.0 and snail.max_stamina == 10.0 and snail.sleep_duration == 20.0, "new snail starts slow, tires quickly, and sleeps for a long time")
	check(shrimp != null and shrimp.move_speed == 30.0 and shrimp.digestion_duration == 12.0, "new cleanup shrimp begins with modest speed and a long digestion pause")
	check(puffer != null and puffer.move_speed == 45.0 and puffer.curiosity == 0.30, "new bubble puffer starts slow and selectively curious")
	check(seahorse != null and seahorse.feed_interval == 18.0 and seahorse.feed_tier == 0, "new seahorse starts with deliberate Basic-feed production")
	for specimen in get_nodes_in_group("fish"):
		specimen.hunger = 0.0
	seahorse.feed_left = 0.0
	var food_before_ready: int = get_nodes_in_group("food").size()
	seahorse._process(0.1)
	check(seahorse.feed_left == 0.0 and get_nodes_in_group("food").size() == food_before_ready, "ready seahorse holds its pellet while no fish needs food")
	var hungry_specimen = get_nodes_in_group("fish")[0]
	hungry_specimen.hunger = hungry_specimen.profile.hungry_threshold
	seahorse._process(0.1)
	check(seahorse.feed_left == seahorse.feed_interval and get_nodes_in_group("food").size() == food_before_ready + 1, "ready seahorse feeds immediately when hunger appears")
	get_nodes_in_group("food")[-1].free()
	hungry_specimen.hunger = 0.0
	tank.select_shop_item("seahorse")
	check(tank.shop_secondary_button.visible and tank.shop_sell_button.visible, "owned seahorse exposes rate, pellet quality, and sale controls")
	balance = tank.economy.money
	tank.activate_shop_item()
	check(tank.assets.levels.seahorse_interval == 1 and seahorse.feed_interval == 14.0 and tank.economy.money == balance - 60, "seahorse production interval upgrades independently")
	balance = tank.economy.money
	tank.activate_shop_secondary()
	check(tank.assets.levels.seahorse_feed == 1 and seahorse.feed_tier == 1 and tank.economy.money == balance - 150, "seahorse pellet quality upgrades to Premium")
	tank.select_shop_item("puffer")
	check(tank.shop_detail_title.text == "Bubble puffer" and tank.shop_secondary_button.visible, "puffer card exposes speed and curiosity upgrades")
	balance = tank.economy.money
	tank.activate_shop_item()
	check(tank.assets.levels.puffer_speed == 1 and puffer.move_speed == 60.0 and tank.economy.money == balance - 40, "puffer speed upgrades independently")
	balance = tank.economy.money
	tank.activate_shop_secondary()
	check(tank.assets.levels.puffer_curiosity == 1 and puffer.curiosity == 0.45 and tank.economy.money == balance - 40, "puffer curiosity upgrades independently")
	var missed_bubble = tank.spawn_income_bubble()
	missed_bubble.position = Vector2(puffer.position.x + 150, puffer.position.y)
	var bubble_balance: float = tank.economy.money
	puffer.curiosity = 0.0
	puffer._process(0.1)
	check(puffer.target_bubble == null and not missed_bubble.claimed, "uninterested puffer keeps wandering")
	puffer.curiosity = 1.0
	puffer.seen_bubbles.clear()
	var old_distance: float = puffer.position.distance_to(missed_bubble.position)
	puffer._process(0.5)
	check(puffer.target_bubble == missed_bubble and puffer.position.distance_to(missed_bubble.position) < old_distance, "interested puffer chases a noticed bubble")
	missed_bubble.position = puffer.position
	missed_bubble.value = 2.0
	ActivityPace.set_idle(true)
	puffer._process(1.0)
	check(not missed_bubble.claimed and tank.economy.money == bubble_balance, "bubble puffer does not create offline income")
	ActivityPace.set_idle(false)
	puffer._process(0.0)
	check(missed_bubble.claimed and tank.economy.money == bubble_balance + 2.0 and puffer.puff_left == puffer.PUFF_DURATION, "puffer pops on contact and briefly inflates")
	var shrimp_waste = tank.spawn_waste(Vector2(shrimp.position.x, shrimp.floor_y))
	shrimp_waste.settled = true
	var dirty_before_shrimp: float = tank.environment.cleanliness
	shrimp._process(0.01)
	check(shrimp_waste.is_queued_for_deletion() and is_equal_approx(tank.environment.cleanliness, dirty_before_shrimp + TankEnvironment.SHRIMP_WASTE_RECOVERY) and shrimp.digestion_left == shrimp.digestion_duration, "cleanup shrimp eats settled waste and restores partial cleanliness before digesting")
	shrimp.digestion_left = 0.0
	var doomed_pellet = tank.spawn_food(Vector2(shrimp.position.x, shrimp.floor_y), tank.feeds[0])
	doomed_pellet.position.y = doomed_pellet.floor_y
	doomed_pellet.lifetime = 3.0
	shrimp._process(0.01)
	check(doomed_pellet.consumed and doomed_pellet.is_queued_for_deletion(), "cleanup shrimp rescues a floor pellet shortly before it would pollute the tank")
	tank.select_shop_item("shrimp")
	check(tank.shop_secondary_button.visible, "cleanup shrimp exposes speed and digestion upgrades")
	balance = tank.economy.money
	tank.activate_shop_item()
	check(tank.assets.levels.shrimp_speed == 1 and shrimp.move_speed == 45.0 and tank.economy.money == balance - 20, "first shrimp speed upgrade has a strong low-cost effect")
	balance = tank.economy.money
	tank.activate_shop_secondary()
	check(tank.assets.levels.shrimp_digestion == 1 and shrimp.digestion_duration == 8.0 and tank.economy.money == balance - 20, "first shrimp digestion upgrade sharply shortens its pause")
	tank.select_shop_item("snail")
	check(tank.shop_detail_title.text == "Snail" and tank.shop_secondary_button.visible and tank.shop_tertiary_button.visible, "snail card exposes speed, stamina, and sleep upgrades")
	balance = tank.economy.money
	tank.activate_shop_item()
	check(tank.assets.levels.snail_speed == 1 and snail.crawl_speed == 30.0 and tank.economy.money == balance - 30, "first snail speed upgrade has a useful but non-trivial price")
	balance = tank.economy.money
	tank.activate_shop_secondary()
	check(tank.assets.levels.snail_stamina == 1 and snail.max_stamina == 28.0 and tank.economy.money == balance - 30, "first snail stamina upgrade sharply increases movement time")
	balance = tank.economy.money
	tank.activate_shop_tertiary()
	check(tank.assets.levels.snail_sleep == 1 and snail.sleep_duration == 11.0 and tank.economy.money == balance - 30, "first snail sleep upgrade sharply shortens rest time")
	var falling_coin = tank.spawn_coin(Vector2(snail.position.x + 100, 600), 1)
	falling_coin.set_process(false)
	var snail_x: float = snail.position.x
	snail._process(0.5)
	check(snail.position.x == snail_x, "snail waits for falling coins to settle")
	falling_coin.position.y = falling_coin.floor_y
	snail.stamina_left = 0.1
	snail._process(0.2)
	var tired_x: float = snail.position.x
	check(snail.sleep_left == snail.sleep_duration, "snail sleeps after exhausting movement stamina")
	snail._process(1.0)
	check(snail.position.x == tired_x and snail.sleep_left < snail.sleep_duration, "sleeping snail stops moving")
	var food_before_wake: int = get_nodes_in_group("food").size()
	tank.handle_tank_click(snail.position)
	check(snail.sleep_left == 0.0 and snail.stamina_left == snail.max_stamina and get_nodes_in_group("food").size() == food_before_wake, "tapping a sleeping snail wakes it without dropping food")
	var old_life: float = falling_coin.lifetime
	tank.select_shop_item("coins")
	check(tank.shop_secondary_button.visible, "one fish-coin card exposes lifetime and value upgrades")
	balance = tank.economy.money
	tank.activate_shop_item()
	check(tank.assets.levels.coin_lifetime == 1 and tank.assets.coin_lifetime() == 15.0 and falling_coin.lifetime == old_life + 7.0 and tank.economy.money == balance - 40, "coin preservation upgrades future and existing reward lifetime")
	check(tank.assets.upgrade_price("coin_lifetime") == 100, "upgrade prices grow geometrically")
	balance = tank.economy.money
	tank.activate_shop_secondary()
	check(tank.assets.coin_multiplier() == 2 and tank.economy.money == balance - 200, "coin-value upgrade doubles future fish rewards at its rebalanced price")
	check(tank.shop_cards.coins.discovered, "either fish-coin upgrade reveals the shared shop artwork")
	var teen := get_nodes_in_group("fish")[0] as AquariumFish
	teen.growth.stage = 1
	teen.coin_produced.emit(teen.position, 1, false, 1)
	var upgraded_coin = get_nodes_in_group("coins")[-1]
	check(upgraded_coin.value == 2 and upgraded_coin.grade == 1 and upgraded_coin.coin_color() == Color("d79b69"), "coin-value upgrade pays more while the Teen coin stays bronze")
	tank.select_shop_item("diamond_value")
	balance = tank.economy.money
	tank.activate_shop_item()
	check(tank.assets.diamond_multiplier() == 2 and tank.economy.money == balance - 150 and tank.shop_cards.diamond_value.discovered, "diamond value upgrades independently from ordinary coin value")
	teen.coin_produced.emit(teen.position, 10, true, 4)
	var fish_diamond = get_nodes_in_group("coins")[-1]
	check(fish_diamond.value == 20 and fish_diamond.diamond and fish_diamond.lifetime == 8.0 and tank.shop_secondary_button.visible, "fish diamonds use only Diamond Value and expose a separate lifetime upgrade")
	var ordinary_life: float = upgraded_coin.lifetime
	balance = tank.economy.money
	tank.activate_shop_secondary()
	check(tank.assets.diamond_lifetime() == 15.0 and fish_diamond.lifetime == 15.0 and upgraded_coin.lifetime == ordinary_life and tank.economy.money == balance - 50, "diamond lifetime upgrades existing diamonds without changing ordinary coins")
	tank.invasions.alien_defeated.emit(Vector2(620, 320))
	var alien_diamond = get_nodes_in_group("coins")[-1]
	check(alien_diamond.value == fish_diamond.value * 2 and alien_diamond.diamond and alien_diamond.lifetime == tank.assets.diamond_lifetime(), "alien diamonds are worth twice a normal fish diamond and share Diamond Lifetime")
	tank.select_shop_item("idle_duration")
	check("Locked" in tank.shop_detail_state.text and tank.shop_action_button.text.contains("$50"), "away-time card explains the initial lock and first price")
	balance = tank.economy.money
	tank.activate_shop_item()
	check(tank.assets.levels.idle_duration == 1 and tank.assets.idle_limit() == 300.0 and tank.economy.money == balance - 50, "first away-time upgrade unlocks five minutes")
	check(tank.assets.upgrade_price("idle_duration") == 150, "away-time price rises geometrically")
	tank.select_shop_item("bubbles")
	check(tank.shop_secondary_button.visible and tank.shop_action_button.text.contains("$30") and tank.shop_secondary_button.text.contains("$30"), "bubble card exposes separate capacity and value tracks")
	balance = tank.economy.money
	tank.activate_shop_item()
	check(tank.assets.levels.bubble_capacity == 1 and tank.assets.bubble_capacity() == 2 and tank.economy.money == balance - 30, "bubble capacity upgrade raises the simultaneous limit")
	balance = tank.economy.money
	tank.activate_shop_secondary()
	check(tank.assets.levels.bubble_value == 1 and tank.assets.bubble_multiplier() == 1.5 and tank.economy.money == balance - 30, "bubble value upgrade raises every pop multiplier")
	check(tank.assets.upgrade_price("bubble_capacity") == 90 and tank.assets.upgrade_price("bubble_value") == 90, "both bubble tracks use exponential prices")
	tank.restock()
	check(tank.assets.reserve.size() == 20 and tank.assets.reserve[0] == 0 and "20 basic pellets" in tank.shop_status.text.to_lower(), "reserve stores purchased basic pellets and confirms restock")
	tank.purchase_feed_upgrade()
	check(tank.feed_upgrades.unlocked_tier == 1 and tank.shop_cards.feed.pellet_color == tank.feeds[1].color and tank.shop_cards.feed.pellet_growth == 2, "premium unlock updates the shop pellet preview")
	tank.purchase_feed_upgrade()
	check(tank.feed_upgrades.unlocked_tier == 2 and tank.assets.reserve[0] == 0 and tank.shop_cards.feed.pellet_color == tank.feeds[2].color and tank.shop_cards.stock.pellet_color == tank.feeds[2].color, "deluxe changes shop pellet colors without changing stored pellet tiers")
	tank.food_cooldown = 0.0
	pellet = tank.drop_food(Vector2(500, 400))
	check(pellet.profile.growth_credit == 3, "manual feed always uses highest upgrade")
	for living in get_nodes_in_group("fish"):
		living.hunger = 0.0
	fish = get_nodes_in_group("fish")[0]
	fish.hunger = 1.0
	tank.assets.feeder_left = 0.0
	balance = tank.economy.money
	tank._process(0.01)
	check(tank.assets.reserve.size() == 19 and tank.economy.money == balance, "feeder consumes stock without a second charge")
	var data: Dictionary = tank.snapshot()
	check(data.fish.size() == 2 and data.owned.feeder and data.owned.puffer and data.owned.shrimp and data.owned.seahorse and data.tier == 2 and data.asset_levels.snail_speed == 1 and data.asset_levels.snail_stamina == 1 and data.asset_levels.snail_sleep == 1 and data.asset_levels.shrimp_speed == 1 and data.asset_levels.shrimp_digestion == 1 and data.asset_levels.seahorse_interval == 1 and data.asset_levels.seahorse_feed == 1 and data.asset_levels.puffer_speed == 1 and data.asset_levels.puffer_curiosity == 1 and data.asset_levels.coin_lifetime == 1 and data.asset_levels.coin_value == 1 and data.asset_levels.diamond_value == 1 and data.asset_levels.diamond_lifetime == 1 and data.asset_levels.idle_duration == 1 and data.asset_levels.bubble_capacity == 1 and data.asset_levels.bubble_value == 1, "snapshot includes progression automation and upgrade tracks")
	# Round-trip JSON without touching the user's actual save.
	check(LocalSave.write(data, "/tmp/insanarium-test-save.json"), "atomic save writer succeeds")
	tank.queue_free()
	await process_frame
	var restored = load("res://scenes/aquarium.tscn").instantiate()
	# Empty startup fish before restoring the captured state.
	root.add_child(restored)
	for living in get_nodes_in_group("fish"):
		living.free()
	restored.restore(LocalSave.read("/tmp/insanarium-test-save.json"))
	var restored_snail: SnailPet
	var restored_puffer
	var restored_shrimp: CleanupShrimpPet
	var restored_seahorse: SeahorsePet
	for pet in get_nodes_in_group("pets"):
		if pet is SnailPet:
			restored_snail = pet
		elif pet is BubblePufferScript:
			restored_puffer = pet
		elif pet is CleanupShrimpPet:
			restored_shrimp = pet
		elif pet is SeahorsePet:
			restored_seahorse = pet
	check(get_nodes_in_group("fish").size() == 2 and restored.assets.reserve.size() == 19 and restored.feed_upgrades.unlocked_tier == 2 and restored.economy.money == int(data.money), "JSON round-trip restores wallet fish upgrades and stock")
	check(restored.assets.levels.snail_speed == 1 and restored.assets.levels.snail_stamina == 1 and restored.assets.levels.snail_sleep == 1 and restored.assets.levels.coin_lifetime == 1 and restored.assets.levels.coin_value == 1 and restored.assets.levels.diamond_value == 1 and restored.assets.levels.diamond_lifetime == 1 and restored_snail != null and restored_snail.crawl_speed == 30.0 and restored_snail.max_stamina == 28.0 and restored_snail.sleep_duration == 11.0, "JSON round-trip restores snail and reward upgrades")
	check(restored.assets.owned.puffer and restored_puffer != null and restored_puffer.position == Vector2(data.puffer_x, data.puffer_y) and restored_puffer.move_speed == 60.0 and restored_puffer.curiosity == 0.45, "JSON round-trip restores the bubble puffer and its upgrades")
	check(restored.assets.owned.shrimp and restored_shrimp != null and restored_shrimp.move_speed == 45.0 and restored_shrimp.digestion_duration == 8.0 and is_equal_approx(restored_shrimp.position.x, float(data.shrimp_x)), "JSON round-trip restores cleanup shrimp state and upgrades")
	check(restored.assets.owned.seahorse and restored_seahorse != null and restored_seahorse.feed_interval == 14.0 and restored_seahorse.feed_tier == 1, "JSON round-trip restores seahorse rate and pellet quality")
	restored.select_shop_item("snail")
	var pet_count_before_sale: int = get_nodes_in_group("pets").size()
	var wallet_before_sale: float = restored.economy.money
	var expected_sale: int = restored.assets.pet_sell_value("snail")
	restored.activate_shop_sell()
	await process_frame
	check(not restored.assets.owned.snail and get_nodes_in_group("pets").size() == pet_count_before_sale - 1 and restored.economy.money == wallet_before_sale + expected_sale and restored.assets.levels.snail_speed == 0 and not restored.shop_cards.snail.discovered, "selling a pet refunds half its investment, removes it, and resets its upgrades")
	for living in get_nodes_in_group("fish"):
		living.die("Test")
	restored.economy.money = 0
	restored.update_money(0)
	var recovery = restored.spawn_income_bubble()
	recovery.value = 1
	restored.handle_tank_click(recovery.position)
	check(restored.economy.money == 1 and get_nodes_in_group("fish").is_empty(), "extinction keeps click income available")
	check(restored.debug_controls.visible, "test controls are available in debug builds")
	restored.debug_controls.speed_button.pressed.emit()
	check(Engine.time_scale == 10.0, "test speed button accelerates the whole simulation to 10x")
	restored.debug_controls.speed_button.pressed.emit()
	var auto_fish: AquariumFish = restored.spawn_fish(false, "Autoplay test")
	auto_fish.hunger = 1.0
	restored.economy.credit(100)
	var auto_coin = restored.spawn_coin(Vector2(500, 650), 3)
	var auto_bubble = restored.spawn_income_bubble()
	var auto_waste = restored.spawn_waste(Vector2(520, 640))
	restored.debug_purchase_left = 5.0
	restored.debug_autoplay_step()
	check(auto_coin.claimed and auto_bubble.claimed and auto_waste.is_queued_for_deletion() and not get_nodes_in_group("food").is_empty(), "autoplay collects rewards, cleans waste, and feeds hungry fish through normal game rules")
	restored.debug_autoplay = true
	restored.reset_test_tank()
	var owns_nothing: bool = true
	for value in restored.assets.owned.values():
		owns_nothing = owns_nothing and not bool(value)
	check(Engine.time_scale == 1.0 and not restored.debug_autoplay and restored.economy.money == 100 and get_nodes_in_group("fish").size() == 2 and owns_nothing, "confirmed test reset restores the clean two-fish starting state")
	print("Idle checks: ", checks, "; failures: ", failures)
	quit(1 if failures else 0)
