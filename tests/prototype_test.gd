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
	check(get_nodes_in_group("fish").size() == 2 and get_nodes_in_group("pets").is_empty(), "two normal fish and no free pets")
	check(not tank.shop_panel.visible and tank.shop_cards.size() == 8, "shop starts closed with reusable product cards")
	tank.toggle_shop()
	check(tank.shop_panel.visible, "shop opens from its shared toggle")
	tank.toggle_shop()
	check(not tank.invasions.running, "lethal invasions disabled by default")
	check(Economy.fish_price(2) == 50 and Economy.fish_price(10) == 2745 and Economy.fish_price(19) == 249000, "fish purchase price climbs steeply with population")
	var fish = get_nodes_in_group("fish")[0]
	check(fish.mutation.variant == 0 and fish.current_coin_value() == 1, "normal fish start amber with one-dollar coins")
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
	check(not mutation.roll(1.0) and mutation.sell_value(3) == 2400, "mutation occurs only once and doubles mature sale value")
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
	check(tank.economy.money == balance + 700 and get_nodes_in_group("fish").size() == 1, "mutant sale pays once and removes fish")
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
	check(not tank.shop_panel.visible and tank.reveal_panel.visible and tank.reveal_panel.heading_label.text == "NEW FISH PURCHASED" and tank.reveal_panel.trait_bars.size() == 6, "fish purchase closes the shop and opens reusable six-trait reveal card")
	check(tank.reveal_panel.trait_bars[0].title == "Maximum health" and tank.reveal_panel.trait_bars[5].title == "Water resistance", "reveal card shows direct outcomes rather than hidden genes")
	tank.show_fish_reveal(get_nodes_in_group("fish")[0], "QUEUED FISH")
	check(tank.reveal_queue.size() == 1 and "1 waiting" in tank.reveal_panel.dismiss_button.text, "additional fish reveals queue without replacing the current card")
	tank.advance_fish_reveal()
	check(tank.reveal_panel.heading_label.text == "QUEUED FISH", "dismissing advances to the next queued fish")
	tank.advance_fish_reveal()
	check(not tank.reveal_panel.visible, "final reveal dismisses cleanly")
	tank.economy.credit(2000)
	for kind in ["snail", "seahorse", "puffer", "feeder"]:
		balance = tank.economy.money
		tank.purchase_asset(kind)
		tank.purchase_asset(kind)
		check(tank.assets.owned[kind] and tank.economy.money == balance - tank.assets.PRICES[kind], "automation purchase charges only once: " + kind)
	for pet in get_nodes_in_group("pets"):
		pet.set_process(false)
	check(get_nodes_in_group("pets").size() == 3, "purchased pets are spawned")
	var snail: SnailPet
	var puffer
	for pet in get_nodes_in_group("pets"):
		if pet is SnailPet:
			snail = pet
		elif pet is BubblePufferScript:
			puffer = pet
	check(snail != null and snail.crawl_speed == 16.0 and snail.max_stamina == 10.0 and snail.sleep_duration == 20.0, "new snail starts slow, tires quickly, and sleeps for a long time")
	check(puffer != null and puffer.move_speed == 45.0 and puffer.curiosity == 0.30, "new bubble puffer starts slow and selectively curious")
	tank.select_shop_item("puffer")
	check(tank.shop_detail_title.text == "Bubble puffer" and tank.shop_secondary_button.visible, "puffer card exposes speed and curiosity upgrades")
	balance = tank.economy.money
	tank.activate_shop_item()
	check(tank.assets.levels.puffer_speed == 1 and puffer.move_speed == 60.0 and tank.economy.money == balance - 100, "puffer speed upgrades independently")
	balance = tank.economy.money
	tank.activate_shop_secondary()
	check(tank.assets.levels.puffer_curiosity == 1 and puffer.curiosity == 0.45 and tank.economy.money == balance - 100, "puffer curiosity upgrades independently")
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
	tank.select_shop_item("snail")
	check(tank.shop_detail_title.text == "Snail" and tank.shop_secondary_button.visible and tank.shop_tertiary_button.visible, "snail card exposes speed, stamina, and sleep upgrades")
	balance = tank.economy.money
	tank.activate_shop_item()
	check(tank.assets.levels.snail_speed == 1 and snail.crawl_speed == 22.0 and tank.economy.money == balance - 100, "first exponential track upgrade increases snail speed")
	balance = tank.economy.money
	tank.activate_shop_secondary()
	check(tank.assets.levels.snail_stamina == 1 and snail.max_stamina == 16.0 and tank.economy.money == balance - 100, "independent stamina upgrade increases movement time")
	balance = tank.economy.money
	tank.activate_shop_tertiary()
	check(tank.assets.levels.snail_sleep == 1 and snail.sleep_duration == 15.0 and tank.economy.money == balance - 100, "independent sleep upgrade shortens rest time")
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
	var old_life: float = falling_coin.lifetime
	tank.select_shop_item("coin_lifetime")
	balance = tank.economy.money
	tank.activate_shop_item()
	check(tank.assets.levels.coin_lifetime == 1 and tank.assets.coin_lifetime() == 15.0 and falling_coin.lifetime == old_life + 7.0 and tank.economy.money == balance - 100, "coin preservation upgrades future and existing reward lifetime")
	check(tank.assets.upgrade_price("coin_lifetime") == 190, "upgrade prices grow geometrically")
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
	check(data.fish.size() == 2 and data.owned.feeder and data.owned.puffer and data.tier == 2 and data.asset_levels.snail_speed == 1 and data.asset_levels.snail_stamina == 1 and data.asset_levels.snail_sleep == 1 and data.asset_levels.puffer_speed == 1 and data.asset_levels.puffer_curiosity == 1 and data.asset_levels.coin_lifetime == 1, "snapshot includes progression automation and upgrade tracks")
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
	for pet in get_nodes_in_group("pets"):
		if pet is SnailPet:
			restored_snail = pet
		elif pet is BubblePufferScript:
			restored_puffer = pet
	check(get_nodes_in_group("fish").size() == 2 and restored.assets.reserve.size() == 19 and restored.feed_upgrades.unlocked_tier == 2 and restored.economy.money == int(data.money), "JSON round-trip restores wallet fish upgrades and stock")
	check(restored.assets.levels.snail_speed == 1 and restored.assets.levels.snail_stamina == 1 and restored.assets.levels.snail_sleep == 1 and restored.assets.levels.coin_lifetime == 1 and restored_snail != null and restored_snail.crawl_speed == 22.0 and restored_snail.max_stamina == 16.0 and restored_snail.sleep_duration == 15.0, "JSON round-trip restores snail and preservation upgrades")
	check(restored.assets.owned.puffer and restored_puffer != null and restored_puffer.position == Vector2(data.puffer_x, data.puffer_y) and restored_puffer.move_speed == 60.0 and restored_puffer.curiosity == 0.45, "JSON round-trip restores the bubble puffer and its upgrades")
	for living in get_nodes_in_group("fish"):
		living.die("Test")
	restored.economy.money = 0
	restored.update_money(0)
	var recovery = restored.spawn_income_bubble()
	recovery.value = 1
	restored.handle_tank_click(recovery.position)
	check(restored.economy.money == 1 and get_nodes_in_group("fish").is_empty(), "extinction keeps click income available")
	print("Idle checks: ", checks, "; failures: ", failures)
	quit(1 if failures else 0)
