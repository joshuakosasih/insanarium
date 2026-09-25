extends SceneTree
const BubblePufferScript = preload("res://scripts/pets/bubble_puffer.gd")

func _initialize() -> void:
	call_deferred("capture")

func capture() -> void:
	var tank = load("res://scenes/aquarium.tscn").instantiate()
	root.add_child(tank)
	if "--idle" in OS.get_cmdline_user_args():
		tank.economy.credit(1500)
		for kind in ["snail", "shrimp", "seahorse", "puffer", "feeder"]:
			tank.purchase_asset(kind)
		tank.restock()
		var specimen = get_nodes_in_group("fish")[0]
		specimen.growth.stage = 2
		specimen.mutation.variant = 1
		specimen.position = Vector2(550, 370)
		specimen.selected = true
		tank.selected_fish = specimen
	if "--showcase" in OS.get_cmdline_user_args():
		var fish = get_nodes_in_group("fish")[0]
		fish.growth.stage = fish.profile.diamond_stage
		fish.growth.meals = 75
		fish.visual_size = fish.profile.growth_sizes[fish.growth.stage]
		fish.scale = Vector2.ONE * fish.visual_size
		fish.queue_redraw()
		fish.position = Vector2(620, 340)
		fish.destination = Vector2(680, 340)
		fish.wander_left = 5.0
		tank.spawn_coin(Vector2(600, 400), 100, true)
		tank.spawn_coin(Vector2(400, 650), 20)
	if "--warning" in OS.get_cmdline_user_args():
		tank.invasions.begin_warning()
	if "--alien" in OS.get_cmdline_user_args():
		tank.invasions.begin_warning()
		tank.invasions._process(5.1)
		tank.invasions.active.position = Vector2(550, 390)
		var hungry = get_nodes_in_group("fish")[0]
		hungry.hunger = 1.0
		hungry.survival.starving_for = 6.0
	if "--death" in OS.get_cmdline_user_args():
		var dying = get_nodes_in_group("fish")[0]
		dying.position = Vector2(580, 450)
		dying.die("Starved")
	if "--care" in OS.get_cmdline_user_args():
		tank.care_panel.show()
		tank.refresh_care()
	if "--shop" in OS.get_cmdline_user_args():
		tank.shop_panel.show()
		print("Shop preview: position=", tank.shop_panel.position, " size=", tank.shop_panel.size)
	if "--snail-shop" in OS.get_cmdline_user_args():
		tank.select_shop_item("snail")
	if "--puffer-shop" in OS.get_cmdline_user_args():
		tank.select_shop_item("puffer")
	if "--shrimp-shop" in OS.get_cmdline_user_args():
		tank.select_shop_item("shrimp")
	if "--coins-shop" in OS.get_cmdline_user_args():
		tank.select_shop_item("coins")
	if "--seahorse-shop" in OS.get_cmdline_user_args():
		tank.select_shop_item("seahorse")
	if "--puffed" in OS.get_cmdline_user_args():
		for pet in get_nodes_in_group("pets"):
			if pet is BubblePufferScript:
				pet.puff_left = pet.PUFF_DURATION
				pet.queue_redraw()
	if "--sleeping-snail" in OS.get_cmdline_user_args():
		for pet in get_nodes_in_group("pets"):
			if pet is SnailPet:
				pet.sleep_left = pet.sleep_duration
				pet.queue_redraw()
	if "--deluxe-feed" in OS.get_cmdline_user_args():
		tank.purchase_feed_upgrade()
		tank.purchase_feed_upgrade()
		tank.select_shop_item("feed")
	if "--environment" in OS.get_cmdline_user_args():
		for x in [360.0, 520.0, 680.0, 820.0]:
			var waste = tank.spawn_waste(Vector2(x, 642))
			waste.settled = true
		tank.environment.cleanliness = 52.0
		tank.update_cleanliness()
		var affected_fish = get_nodes_in_group("fish")[0]
		affected_fish.health.current = 45.0
		affected_fish.queue_redraw()
	if "--reveal" in OS.get_cmdline_user_args():
		var revealed_fish = get_nodes_in_group("fish")[0]
		tank.show_fish_reveal(revealed_fish, "NEW FISH PURCHASED")
	if "--tank" in OS.get_cmdline_user_args():
		tank.acquisition_queue.clear()
		tank.active_acquisition.clear()
		tank.acquisition_celebration.hide()
		tank.reveal_panel.hide()
		if is_instance_valid(tank.selected_fish):
			tank.selected_fish.selected = false
		tank.selected_fish = null
		tank.inspector_panel.hide()
	await process_frame
	await process_frame
	RenderingServer.force_draw()
	root.get_texture().get_image().save_png("/tmp/insanarium-preview.png")
	quit()
