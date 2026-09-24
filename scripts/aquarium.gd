extends Node2D
## Composition root: owns the habitat, entities, economy, and input routing.
const ShopItemScript = preload("res://scripts/ui/shop_item.gd")
const ShopCardScript = preload("res://scripts/ui/shop_card.gd")
const VectorArt = preload("res://scripts/art/aquarium_vector_art.gd")
const BubblePufferScript = preload("res://scripts/pets/bubble_puffer.gd")
const FishTraitBarScript = preload("res://scripts/ui/fish_trait_bar.gd")
const FishRevealPanelScript = preload("res://scripts/ui/fish_reveal_panel.gd")
const MobileOrientationGateScript = preload("res://scripts/ui/mobile_orientation_gate.gd")
const TANK := Rect2(48, 166, 1056, 504)
const SWIM_BOUNDS := Rect2(85, 197, 982, 443)
const STARTER_TANK_WIDTH := 900.0
const CREATURE_PRESENTATION_SCALE := 1.22
const COLLECTIBLE_PRESENTATION_SCALE := 1.30
const PET_PRESENTATION_SCALE := 1.16
const TANK_BOTTOM_MARGIN := 36.0
const POINTER_DUPLICATE_MS := 180
const POINTER_DUPLICATE_RADIUS := 28.0
var tank_rect := Rect2(TANK.position, Vector2(STARTER_TANK_WIDTH, TANK.size.y))
var swim_bounds := Rect2(SWIM_BOUNDS.position, Vector2(STARTER_TANK_WIDTH - (SWIM_BOUNDS.position.x - TANK.position.x) * 2.0, SWIM_BOUNDS.size.y))
var feeds: Array[FeedProfile] = FeedProfile.tiers()
var hud_layer: CanvasLayer
var feed_upgrades := FeedUpgrades.new()
var feed_label: Label
var feed_status: Label
var footer_hint: Label
var invasions: InvasionDirector
var pace_label: Label
var away_data: Dictionary = {}
var offline_ready: bool = false
var applying_offline: bool = false
var return_dialog: AcceptDialog
var transfer: SaveTransfer
var import_dialog: ConfirmationDialog
var pending_import: Dictionary = {}
var life_registry := LifeRegistry.new()
var inspector_panel: Panel
var inspector_detail: Label
var inspector_trait_bars: Array[FishTraitBar] = []
var reveal_panel: FishRevealPanel
var reveal_queue: Array[Dictionary] = []
var inspect_left: float = 0.0
var breeding := FishBreeding.new()
var breeding_status: Label
var breeding_toggle: CheckButton
var assets := IdleAssets.new()
var selected_fish: AquariumFish
var sell_button: Button
var inspect_label: Label
var save_label: Label
var autosave_left: float = 15.0
var challenges: bool = false
var persistence: bool = not "--test" in OS.get_cmdline_user_args()
var economy: Economy
var money_label: Label
var count_label: Label
var cleanliness_label: Label
var clean_button: Button
var water_overlay: WaterQualityOverlay
var buy_button: Button
var shop_button: Button
var controls_button: Button
var shop_panel: Panel
var shop_status: Label
var shop_cards: Dictionary = {}
var shop_items: Dictionary = {}
var shop_selected_id: String = "fish"
var shop_detail_title: Label
var shop_detail_description: Label
var shop_detail_state: Label
var shop_action_button: Button
var shop_secondary_button: Button
var shop_tertiary_button: Button
var care_panel: Panel
var care_details: Label
var care_warnings: Label
var care_refresh: float = 0.0
var audio: AquariumAudio
var sound_button: Button
var bubble_left: float = 3.0
var bubble_rewards := BubbleRewards.new()
var bubble_rng := RandomNumberGenerator.new()
var food_cooldown: float = 0.0
var snail_collection_progress: float = 0.0
var environment := TankEnvironment.new()
var last_pointer_position := Vector2(-10000, -10000)
var last_pointer_msec: int = -1000

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	audio = AquariumAudio.new()
	add_child(audio)
	bubble_rng.randomize()
	economy = Economy.new()
	add_child(economy)
	build_hud()
	get_tree().root.size_changed.connect(update_viewport_layout)
	update_viewport_layout()
	water_overlay = WaterQualityOverlay.new()
	water_overlay.z_index = 8
	add_child(water_overlay)
	water_overlay.set_area(Rect2(tank_rect.position + Vector2(2, 2), tank_rect.size - Vector2(4, 24)))
	breeding.offspring_requested.connect(birth)
	feed_upgrades.upgraded.connect(func(_tier: int) -> void: update_money(economy.money))
	economy.money_changed.connect(update_money)
	update_money(economy.money)
	invasions = InvasionDirector.new()
	invasions.presentation_scale = PET_PRESENTATION_SCALE
	invasions.bounds = Rect2(swim_bounds.position + Vector2(13, 21), swim_bounds.size - Vector2(26, 33))
	invasions.alien_defeated.connect(func(at: Vector2) -> void:
		spawn_coin(at, 10, true)
		audio.set_danger_music(false))
	invasions.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(invasions)
	invasions.running = false
	invasions.warning_started.connect(func() -> void:
		audio.play("alert")
		audio.set_danger_music(true))
	var data: Dictionary = LocalSave.read() if persistence else {}
	if data.is_empty():
		for i in range(2):
			spawn_fish(false, "Starter").hunger = 0.0
	else:
		var result := OfflineProgress.advance(data, Time.get_unix_time_from_system())
		restore(result.data)
		show_return(result.report)
	update_money(economy.money)
	offline_ready = true
	if persistence:
		save_now()
	set_idle(false if "--test" in OS.get_cmdline_user_args() else not get_window().has_focus())

func set_idle(idle: bool) -> void:
	ActivityPace.set_idle(idle)
	if is_instance_valid(pace_label):
		pace_label.text = "AWAY · 0.1× EST." if idle else "ACTIVE · 1×"
	if not persistence or not offline_ready or applying_offline:
		return
	if idle and away_data.is_empty():
		away_data = snapshot()
		LocalSave.write(away_data)
		get_tree().paused = true
	elif not idle and not away_data.is_empty():
		var data: Dictionary = away_data
		away_data = {}
		apply_catchup(data)

func update_viewport_layout() -> void:
	# The starter habitat has one fixed world size on every device. Center it in
	# the available viewport so creatures keep the same proportion to the tank.
	var viewport_size := get_viewport_rect().size
	var extra_width: float = maxf(0.0, viewport_size.x - 1152.0)
	tank_rect = Rect2(TANK.position, Vector2(STARTER_TANK_WIDTH, TANK.size.y))
	swim_bounds = Rect2(SWIM_BOUNDS.position, Vector2(STARTER_TANK_WIDTH - (SWIM_BOUNDS.position.x - TANK.position.x) * 2.0, SWIM_BOUNDS.size.y))
	# Preserve the desktop placement, but move the world slightly upward on short
	# phone viewports so the tank keeps a visible safe gap beneath its border.
	var tank_y: float = minf(-70.0, viewport_size.y - tank_rect.end.y - TANK_BOTTOM_MARGIN)
	position = Vector2((viewport_size.x - tank_rect.size.x) * 0.5 - tank_rect.position.x, tank_y)
	if is_instance_valid(hud_layer):
		hud_layer.offset.x = extra_width * 0.5
	var footer_y: float = position.y + tank_rect.end.y + 6.0
	if is_instance_valid(feed_label):
		feed_label.position.y = footer_y
		feed_status.position.y = footer_y
		footer_hint.position.y = footer_y
		pace_label.position.y = footer_y
		save_label.position.y = footer_y
	if is_instance_valid(water_overlay):
		water_overlay.set_area(Rect2(tank_rect.position + Vector2(2, 2), tank_rect.size - Vector2(4, 24)))
	for fish in get_tree().get_nodes_in_group("fish"):
		fish.bounds = swim_bounds
		fish.position = fish.position.clamp(swim_bounds.position, swim_bounds.end)
	for pet in get_tree().get_nodes_in_group("pets"):
		if pet is SnailPet:
			pet.horizontal_bounds = Vector2(swim_bounds.position.x, swim_bounds.end.x)
			pet.position.x = clampf(pet.position.x, pet.horizontal_bounds.x, pet.horizontal_bounds.y)
		elif pet is BubblePufferScript:
			pet.bounds = Rect2(swim_bounds.position + Vector2(25, 23), swim_bounds.size - Vector2(50, 73))
			pet.position = pet.position.clamp(pet.bounds.position, pet.bounds.end)
	for coin in get_tree().get_nodes_in_group("coins"):
		coin.collection_target.x = 825.0 + extra_width * 0.5 - position.x
	if is_instance_valid(invasions):
		invasions.bounds = Rect2(swim_bounds.position + Vector2(13, 21), swim_bounds.size - Vector2(26, 33))
		if is_instance_valid(invasions.active):
			invasions.active.bounds = invasions.bounds
			invasions.active.position = invasions.active.position.clamp(invasions.bounds.position, invasions.bounds.end)
	queue_redraw()

func viewport_to_tank(viewport_position: Vector2) -> Vector2:
	# Pointer events arrive in viewport coordinates. Convert through the complete
	# canvas transform once so centering, vertical offsets, and stretch all agree.
	return get_global_transform_with_canvas().affine_inverse() * viewport_position

func apply_catchup(data: Dictionary) -> void:
	applying_offline = true
	var result := OfflineProgress.advance(data, Time.get_unix_time_from_system())
	clear_tank()
	restore(result.data)
	get_tree().paused = false
	applying_offline = false
	save_now()
	show_return(result.report)

func clear_tank() -> void:
	selected_fish = null
	reveal_queue.clear()
	if is_instance_valid(reveal_panel):
		reveal_panel.hide()
	for child in get_children():
		if child is Node2D and child != invasions and child != water_overlay:
			child.free()
	if is_instance_valid(invasions.active):
		invasions.active.free()
	invasions.active = null
	invasions.warning_left = 0.0
	invasions.schedule_next()
	audio.set_danger_music(false)
	assets = IdleAssets.new()
	environment = TankEnvironment.new()
	update_inspection()

func show_return(report: Dictionary) -> void:
	if report.away < 30.0:
		return
	return_dialog.dialog_text = "Away: %s
Aquarium time: %s%s

Rewards produced: $%d
Collected by snail: $%d
Meals eaten: %d · Stock used: %d
Growth events: %d · Mutations: %d
Waste produced: %d · Pellets spoiled: %d
Fish lost: %d · Water-quality: %d · Old age: %d

Estimated care; no offline breeding or alien attacks." % [
		FishInspector.duration(report.away), FishInspector.duration(report.simulated), " (%s cap)" % FishInspector.duration(float(report.away_limit)) if report.capped else "",
		report.earned, report.collected, report.fed, report.stock_used, report.growth, report.mutations, report.waste, report.spoiled, report.lost, report.water_lost, report.old_age_lost]
	return_dialog.popup_centered(Vector2i(550, 360))

func confirm_import(data: Dictionary) -> void:
	pending_import = data
	import_dialog.dialog_text = "Replace this tank with the selected backup?
Current progress will be overwritten. Export a backup first if you want to keep it."
	import_dialog.popup_centered(Vector2i(550, 180))

func finish_import() -> void:
	if pending_import.is_empty():
		return
	away_data = {}
	# Import restores the recorded state exactly, without retroactive rewards/losses.
	pending_import.saved_at = Time.get_unix_time_from_system()
	apply_catchup(pending_import)
	pending_import = {}
	save_label.text = "Backup restored"

func purchase_asset(kind: String) -> void:
	if assets.purchase(kind, economy):
		spawn_asset(kind)
		audio.play("buy")
		show_shop_message("%s added to the tank." % kind.capitalize())
		update_money(economy.money)

func spawn_asset(kind: String) -> void:
	if kind == "snail":
		var snail := SnailPet.new()
		snail.presentation_scale = PET_PRESENTATION_SCALE
		snail.position = Vector2(300, 650)
		snail.process_mode = Node.PROCESS_MODE_PAUSABLE
		add_child(snail)
		snail.horizontal_bounds = Vector2(swim_bounds.position.x, swim_bounds.end.x)
		snail.apply_upgrades(int(assets.levels.snail_speed), int(assets.levels.snail_stamina), int(assets.levels.snail_sleep))
	elif kind == "seahorse":
		var seahorse := SeahorsePet.new()
		seahorse.presentation_scale = PET_PRESENTATION_SCALE
		seahorse.feed_produced.connect(supply_pet_food)
		seahorse.process_mode = Node.PROCESS_MODE_PAUSABLE
		add_child(seahorse)
	elif kind == "puffer":
		var puffer = BubblePufferScript.new()
		puffer.presentation_scale = PET_PRESENTATION_SCALE
		puffer.position = Vector2(760, 440)
		puffer.process_mode = Node.PROCESS_MODE_PAUSABLE
		add_child(puffer)
		puffer.bounds = Rect2(swim_bounds.position + Vector2(25, 23), swim_bounds.size - Vector2(50, 73))
		puffer.apply_upgrades(int(assets.levels.puffer_speed), int(assets.levels.puffer_curiosity))
	queue_redraw()

func restock() -> void:
	var before: int = assets.reserve.size()
	if assets.restock(feed_upgrades.unlocked_tier, feeds, economy):
		audio.play("buy")
		show_shop_message("Added %d %s pellets to the feeder." % [assets.reserve.size() - before, feeds[feed_upgrades.unlocked_tier].title])
	update_money(economy.money)

func spawn_income_bubble() -> IncomeBubble:
	if get_tree().get_nodes_in_group("income_bubbles").size() >= assets.bubble_capacity():
		return null
	var bubble := IncomeBubble.new()
	bubble.scale = Vector2.ONE * COLLECTIBLE_PRESENTATION_SCALE
	bubble_rewards.multiplier = assets.bubble_multiplier()
	bubble.value = bubble_rewards.roll(bubble_rng)
	bubble.position = Vector2(bubble_rng.randf_range(swim_bounds.position.x + 35, swim_bounds.end.x - 35), bubble_rng.randf_range(615, 645))
	bubble.process_mode = Node.PROCESS_MODE_PAUSABLE
	bubble.popped.connect(func(value: float) -> void:
		economy.credit(value)
		audio.play("bubble")
		show_feedback(bubble.position, "+$" + Economy.format_money(value)))
	add_child(bubble)
	return bubble

func sell_selected() -> void:
	if not is_instance_valid(selected_fish) or selected_fish.dead:
		return
	var fish := selected_fish
	selected_fish = null
	fish.dead = true
	fish.remove_from_group("fish")
	fish.set_process(false)
	economy.credit(fish.sell_value())
	show_feedback(fish.position, "Sold +$%d" % fish.sell_value())
	fish.queue_free()
	update_count()
	update_inspection()

func update_count() -> void:
	count_label.text = "%02d FISH / %d" % [get_tree().get_nodes_in_group("fish").size(), breeding.CAPACITY]
	update_money(economy.money)

func update_cleanliness() -> void:
	if not is_instance_valid(cleanliness_label):
		return
	cleanliness_label.text = "WATER %d%% · %s" % [roundi(environment.cleanliness), environment.condition()]
	cleanliness_label.add_theme_color_override("font_color", environment.color())
	if is_instance_valid(clean_button):
		var clean_enough: bool = environment.cleanliness > TankEnvironment.FULL_CLEAN_THRESHOLD
		clean_button.text = "Water is clean" if clean_enough else "Full clean  $%d" % int(TankEnvironment.FULL_CLEAN_COST)
		clean_button.disabled = clean_enough or economy.money < TankEnvironment.FULL_CLEAN_COST
	if is_instance_valid(water_overlay):
		water_overlay.set_cleanliness(environment.cleanliness)
	queue_redraw()

func purchase_full_clean() -> void:
	if environment.cleanliness > TankEnvironment.FULL_CLEAN_THRESHOLD:
		return
	if not economy.spend(TankEnvironment.FULL_CLEAN_COST):
		show_feedback(tank_rect.get_center(), "Need $%d" % int(TankEnvironment.FULL_CLEAN_COST))
		return
	for waste in get_tree().get_nodes_in_group("waste"):
		waste.remove_from_group("waste")
		waste.queue_free()
	environment.full_clean()
	audio.play("buy")
	update_cleanliness()
	show_feedback(Vector2(tank_rect.get_center().x, tank_rect.position.y + 35), "Tank fully cleaned")

func update_inspection() -> void:
	var valid: bool = is_instance_valid(selected_fish) and not selected_fish.dead
	sell_button.disabled = not valid
	inspector_panel.visible = valid
	if valid:
		inspector_detail.text = FishInspector.describe(selected_fish)
		var rows := FishInspector.trait_rows(selected_fish)
		for index in range(inspector_trait_bars.size()):
			inspector_trait_bars[index].configure(rows[index])
		inspect_label.text = "%s · %s · %s" % [FishMutation.NAMES[selected_fish.mutation.variant], selected_fish.profile.growth_names[selected_fish.growth.stage], AquariumFish.SEX_NAMES[selected_fish.sex]]
		sell_button.text = "Sell fish  $%d" % selected_fish.sell_value()
	else:
		inspect_label.text = "Click a fish to inspect its sale value"
		sell_button.text = "Select a fish to sell"

func supply_pet_food(at: Vector2) -> void:
	if get_tree().get_nodes_in_group("food").size() < 80:
		spawn_food(at, feeds[0])

func birth(at: Vector2, father_id: String = "", mother_id: String = "") -> void:
	if get_tree().get_nodes_in_group("fish").size() >= breeding.BREEDING_LIMIT:
		return
	var child := spawn_fish(false, "Born in tank")
	if child != null:
		var father: AquariumFish
		var mother: AquariumFish
		for fish in get_tree().get_nodes_in_group("fish"):
			if fish.life.id == father_id:
				father = fish
			elif fish.life.id == mother_id:
				mother = fish
		if father != null and mother != null:
			child.genome = FishGenome.inherit(father.genome, mother.genome)
			child.apply_genome(true)
			child.coin_left = randf_range(3.0, child.genome.output_interval(child.profile.coin_interval))
		child.position = at.clamp(swim_bounds.position, swim_bounds.end)
		child.hunger = 0.1
		child.life.parent_ids = PackedStringArray([father_id, mother_id])
		show_feedback(child.position, "New offspring!")
		show_fish_reveal(child, "NEW OFFSPRING", [father, mother] if father != null and mother != null else [])

func spawn_fish(from_save: bool = false, origin: String = "Purchased") -> AquariumFish:
	if not from_save and get_tree().get_nodes_in_group("fish").size() >= breeding.CAPACITY:
		return null
	var fish := AquariumFish.new()
	fish.presentation_scale = CREATURE_PRESENTATION_SCALE
	if not from_save:
		fish.genome.randomize_traits()
	if not from_save:
		life_registry.allocate(fish.life, origin)
	fish.profile = FishProfile.new()
	fish.sex = randi_range(0, 2) as AquariumFish.Sex
	fish.bounds = swim_bounds
	fish.position = Vector2(randf_range(swim_bounds.position.x + 65, swim_bounds.end.x - 67), randf_range(240, 540))
	fish.coin_produced.connect(func(at: Vector2, value: int, diamond: bool, grade: int) -> void:
		spawn_coin(at, value * assets.coin_multiplier(), diamond, grade))
	fish.waste_produced.connect(spawn_waste)
	fish.grew.connect(show_growth)
	fish.died.connect(on_fish_died)
	fish.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(fish)
	update_count()
	return fish

func on_fish_died(at: Vector2, reason: String) -> void:
	audio.play("loss")
	show_feedback(at, reason)
	update_count()
	update_inspection()

func spawn_coin(at: Vector2, value: int, diamond: bool = false, grade: int = -1) -> TankCoin:
	if get_tree().get_nodes_in_group("coins").size() >= 150:
		var existing = get_tree().get_nodes_in_group("coins")[0]
		existing.value += value
		existing.queue_redraw()
		return existing
	var coin := TankCoin.new()
	coin.scale = Vector2.ONE * COLLECTIBLE_PRESENTATION_SCALE
	coin.position = at
	coin.value = value
	coin.diamond = diamond
	coin.grade = grade
	coin.lifetime = assets.coin_lifetime()
	var extra_width: float = maxf(0.0, get_viewport_rect().size.x - 1152.0)
	coin.collection_target.x = 825.0 + extra_width * 0.5 - position.x
	coin.grounded = coin.position.y >= coin.floor_y
	coin.collected.connect(economy.credit)
	coin.collected.connect(func(_value: int) -> void: audio.play("coin"))
	coin.collected.connect(func(amount: int) -> void: show_feedback(coin.position, "+$%d" % amount))
	coin.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(coin)
	return coin

func spawn_waste(at: Vector2) -> FishWaste:
	environment.pollute(TankEnvironment.WASTE_OUTPUT_POLLUTION)
	update_cleanliness()
	if get_tree().get_nodes_in_group("waste").size() >= 100:
		return null
	var waste := FishWaste.new()
	waste.scale = Vector2.ONE * COLLECTIBLE_PRESENTATION_SCALE
	waste.position = at.clamp(swim_bounds.position, Vector2(swim_bounds.end.x, waste.floor_y))
	waste.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(waste)
	return waste

func clean_waste(waste: FishWaste) -> void:
	if not is_instance_valid(waste) or waste.is_queued_for_deletion():
		return
	var at := waste.position
	waste.remove_from_group("waste")
	waste.queue_free()
	environment.clean(TankEnvironment.CLEANED_WASTE_RECOVERY)
	update_cleanliness()
	show_feedback(at, "Cleanliness +%s%%" % Economy.format_money(TankEnvironment.CLEANED_WASTE_RECOVERY))

func on_food_expired(at: Vector2) -> void:
	environment.pollute(TankEnvironment.SPOILED_PELLET_POLLUTION)
	update_cleanliness()
	show_feedback(at, "Food spoiled")

func show_feedback(at: Vector2, message: String) -> void:
	var feedback := FloatingText.new()
	feedback.position = at
	feedback.text = message
	add_child(feedback)

func show_growth(at: Vector2, stage_name: String) -> void:
	audio.play("grow")
	show_feedback(at, stage_name + "!")

func drop_food(at: Vector2) -> FishFood:
	if not tank_rect.has_point(at) or food_cooldown > 0.0 or get_tree().get_nodes_in_group("food").size() >= 80:
		return null
	if not economy.spend(feeds[feed_upgrades.unlocked_tier].price):
		show_feedback(at, "Need $%d" % feeds[feed_upgrades.unlocked_tier].price)
		food_cooldown = 0.12
		return null
	food_cooldown = 0.12
	audio.play("feed")
	return spawn_food(at, feeds[feed_upgrades.unlocked_tier])

func spawn_food(at: Vector2, feed: FeedProfile) -> FishFood:
	var food := FishFood.new()
	food.scale = Vector2.ONE * COLLECTIBLE_PRESENTATION_SCALE
	food.profile = feed
	food.position = at.clamp(swim_bounds.position, swim_bounds.end)
	food.expired.connect(on_food_expired)
	food.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(food)
	return food

func _process(delta: float) -> void:
	# Poll visibility even while paused: browsers may suspend frame delivery entirely.
	if persistence and offline_ready:
		if OS.has_feature("web"):
			set_idle(bool(JavaScriptBridge.eval("document.hidden || !document.hasFocus()", true)))
		if not away_data.is_empty():
			return
	if ActivityPace.multiplier >= 1.0:
		bubble_left -= delta
		if bubble_left <= 0.0:
			bubble_left = bubble_rng.randf_range(3.0, 5.0)
			spawn_income_bubble()
	food_cooldown = maxf(0.0, food_cooldown - delta)
	inspect_left -= delta
	if inspect_left <= 0.0:
		inspect_left = 0.25
		update_inspection()
		if care_panel.visible:
			care_warnings.text = TankCare.warnings(get_tree().get_nodes_in_group("fish"), assets.reserve.size(), assets.owned.feeder, environment.cleanliness)
	care_refresh -= delta
	if care_panel.visible and care_refresh <= 0.0:
		refresh_care()
	var simulation_delta: float = delta * ActivityPace.multiplier
	life_registry.elapsed += simulation_delta
	breeding.advance(simulation_delta, get_tree().get_nodes_in_group("fish"))
	var count: int = get_tree().get_nodes_in_group("fish").size()
	environment.advance(simulation_delta, count + get_tree().get_nodes_in_group("pets").size(), get_tree().get_nodes_in_group("waste").size())
	update_cleanliness()
	for fish in get_tree().get_nodes_in_group("fish"):
		var well_fed: bool = fish.hunger < fish.profile.hungry_threshold
		if fish.health.advance(simulation_delta, environment.cleanliness, fish.genome.constitution(), well_fed):
			fish.die("Poor water quality")
		else:
			fish.queue_redraw()
	breeding_status.text = "Breeding paused: population %d/16" % count if count >= breeding.BREEDING_LIMIT else "Well-fed adult pairs · 5 min cooldown"
	assets.feeder_left -= simulation_delta
	if assets.owned.feeder and assets.feeder_left <= 0.0:
		assets.feeder_left = 2.0
		var hungriest: AquariumFish
		for fish in get_tree().get_nodes_in_group("fish"):
			if fish.hunger >= fish.profile.hungry_threshold and (hungriest == null or fish.hunger > hungriest.hunger):
				hungriest = fish
		if hungriest != null and not assets.reserve.is_empty() and get_tree().get_nodes_in_group("food").size() < 80:
			spawn_food(hungriest.position + Vector2(0, -12), feeds[assets.reserve.pop_front()])
			update_money(economy.money)
	autosave_left -= delta
	if persistence and autosave_left <= 0.0:
		autosave_left = 15.0
		save_now()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		handle_pointer_press(event.position)

func handle_pointer_press(viewport_position: Vector2) -> void:
	var now: int = Time.get_ticks_msec()
	# Some mobile browsers emit a touch followed by a synthetic mouse click.
	# Treat that pair as one press so collecting a reward cannot also drop food.
	if now - last_pointer_msec <= POINTER_DUPLICATE_MS and viewport_position.distance_to(last_pointer_position) <= POINTER_DUPLICATE_RADIUS:
		get_viewport().set_input_as_handled()
		return
	last_pointer_msec = now
	last_pointer_position = viewport_position
	handle_tank_click(viewport_to_tank(viewport_position))
	get_viewport().set_input_as_handled()

func handle_tank_click(at: Vector2) -> void:
	for bubble in get_tree().get_nodes_in_group("income_bubbles"):
		if bubble.position.distance_to(at) <= IncomeBubble.HIT_RADIUS * absf(bubble.scale.x):
			bubble.pop()
			return
	for alien in get_tree().get_nodes_in_group("invaders"):
		if not alien.dead and alien.position.distance_to(at) <= 48.0 * absf(alien.scale.x):
			alien.hit(at)
			audio.play("hit")
			return
	for coin in get_tree().get_nodes_in_group("coins"):
		if not coin.claimed and coin.position.distance_to(at) <= 24.0 * absf(coin.scale.x):
			coin.collect()
			return
	for waste in get_tree().get_nodes_in_group("waste"):
		if waste.position.distance_to(at) <= 20.0 * absf(waste.scale.x):
			clean_waste(waste)
			return
	for fish in get_tree().get_nodes_in_group("fish"):
		if fish.position.distance_to(at) < 30 * fish.visual_size:
			if is_instance_valid(selected_fish):
				selected_fish.selected = false
			selected_fish = fish
			fish.selected = true
			update_inspection()
			return
	drop_food(at)

func purchase_fish() -> void:
	var population: int = get_tree().get_nodes_in_group("fish").size()
	if population < breeding.CAPACITY and economy.buy_fish(population):
		var fish := spawn_fish()
		audio.play("buy")
		show_shop_message("New %s fish added to the tank." % AquariumFish.SEX_NAMES[fish.sex])
		shop_panel.hide()
		show_fish_reveal(fish, "NEW FISH PURCHASED")

func show_fish_reveal(fish: AquariumFish, heading: String, parents: Array = []) -> void:
	var data: Dictionary = FishRevealPanelScript.capture(fish, heading, parents)
	if reveal_panel.visible:
		reveal_queue.append(data)
		reveal_panel.set_pending_count(reveal_queue.size())
	else:
		reveal_panel.present(data)
		reveal_panel.set_pending_count(0)
		reveal_panel.move_to_front()

func advance_fish_reveal() -> void:
	if reveal_queue.is_empty():
		reveal_panel.hide()
		return
	reveal_panel.present(reveal_queue.pop_front())
	reveal_panel.set_pending_count(reveal_queue.size())

func inspect_revealed_fish(fish_id: String) -> void:
	for fish in get_tree().get_nodes_in_group("fish"):
		if fish.life.id == fish_id and not fish.dead:
			if is_instance_valid(selected_fish):
				selected_fish.selected = false
			selected_fish = fish
			fish.selected = true
			update_inspection()
			break
	advance_fish_reveal()

func purchase_feed_upgrade() -> void:
	if feed_upgrades.purchase(economy):
		audio.play("buy")
		show_shop_message("Feed upgraded to %s." % feeds[feed_upgrades.unlocked_tier].title)

func purchase_upgrade(track: String) -> void:
	var old_coin_lifetime: float = assets.coin_lifetime()
	if assets.upgrade(track, economy):
		for pet in get_tree().get_nodes_in_group("pets"):
			if pet is SnailPet:
				pet.apply_upgrades(int(assets.levels.snail_speed), int(assets.levels.snail_stamina), int(assets.levels.snail_sleep))
			elif pet is BubblePufferScript:
				pet.apply_upgrades(int(assets.levels.puffer_speed), int(assets.levels.puffer_curiosity))
		if track == "coin_lifetime":
			var added: float = assets.coin_lifetime() - old_coin_lifetime
			for coin in get_tree().get_nodes_in_group("coins"):
				coin.lifetime = minf(assets.coin_lifetime(), coin.lifetime + added)
		audio.play("buy")
		show_shop_message("%s upgraded to level %d." % [track.replace("_", " ").capitalize(), int(assets.levels[track]) + 1])
		update_money(economy.money)

func show_shop_message(message: String) -> void:
	if is_instance_valid(shop_status):
		shop_status.text = message
		shop_status.add_theme_color_override("font_color", Color("ffdb80"))

func toggle_shop() -> void:
	shop_panel.visible = not shop_panel.visible
	if shop_panel.visible:
		care_panel.hide()
		if is_instance_valid(selected_fish):
			selected_fish.selected = false
		selected_fish = null
		update_inspection()
		shop_status.text = "Choose something for your aquarium."
		select_shop_item(shop_selected_id)

func select_shop_item(item_id: String) -> void:
	if not shop_items.has(item_id):
		return
	shop_selected_id = item_id
	for key in shop_cards:
		shop_cards[key].set_selected(key == item_id)
	refresh_shop()

func activate_shop_item() -> void:
	match shop_selected_id:
		"fish": purchase_fish()
		"snail":
			if assets.owned.snail:
				purchase_upgrade("snail_speed")
			else:
				purchase_asset("snail")
		"seahorse": purchase_asset("seahorse")
		"puffer":
			if assets.owned.puffer:
				purchase_upgrade("puffer_speed")
			else:
				purchase_asset("puffer")
		"feeder": purchase_asset("feeder")
		"stock": restock()
		"feed": purchase_feed_upgrade()
		"coin_lifetime": purchase_upgrade("coin_lifetime")
		"coin_value": purchase_upgrade("coin_value")
		"idle_duration": purchase_upgrade("idle_duration")
		"bubbles": purchase_upgrade("bubble_capacity")
	refresh_shop()

func activate_shop_secondary() -> void:
	if shop_selected_id == "snail" and assets.owned.snail:
		purchase_upgrade("snail_stamina")
	elif shop_selected_id == "puffer" and assets.owned.puffer:
		purchase_upgrade("puffer_curiosity")
	elif shop_selected_id == "bubbles":
		purchase_upgrade("bubble_value")
	refresh_shop()

func activate_shop_tertiary() -> void:
	if shop_selected_id == "snail" and assets.owned.snail:
		purchase_upgrade("snail_sleep")
	refresh_shop()

func refresh_shop() -> void:
	if not is_instance_valid(shop_panel):
		return
	var feed: FeedProfile = feeds[feed_upgrades.unlocked_tier]
	for pellet_card_id in ["feed", "stock"]:
		if shop_cards.has(pellet_card_id):
			shop_cards[pellet_card_id].set_pellet_preview(feed.color, feed.growth_credit)
	var stock_count: int = mini(20, assets.CAPACITY - assets.reserve.size())
	var fish_count: int = get_tree().get_nodes_in_group("fish").size()
	var current_fish_price: int = Economy.fish_price(fish_count)
	var statuses := {
		"fish": "$%d · %d/%d fish" % [current_fish_price, fish_count, breeding.CAPACITY],
		"snail": "$%d" % assets.PRICES.snail if not assets.owned.snail else "SPD %d · STA %d · SLP %d" % [int(assets.levels.snail_speed) + 1, int(assets.levels.snail_stamina) + 1, int(assets.levels.snail_sleep) + 1],
		"seahorse": "Owned" if assets.owned.seahorse else "$%d" % assets.PRICES.seahorse,
		"puffer": "$%d" % assets.PRICES.puffer if not assets.owned.puffer else "Speed %d · Curiosity %d" % [int(assets.levels.puffer_speed) + 1, int(assets.levels.puffer_curiosity) + 1],
		"feeder": "Owned" if assets.owned.feeder else "$%d" % assets.PRICES.feeder,
		"stock": "%d/%d · $%d" % [assets.reserve.size(), assets.CAPACITY, stock_count * feed.price],
		"feed": "%s · MAX" % feed.title if feed_upgrades.next_price() == 0 else "%s → %s · $%d" % [feed.title, feeds[feed_upgrades.unlocked_tier + 1].title, feed_upgrades.next_price()],
		"coin_lifetime": "Lv. %d · %ds" % [int(assets.levels.coin_lifetime) + 1, int(assets.coin_lifetime())],
		"coin_value": "Lv. %d · ×%d" % [int(assets.levels.coin_value) + 1, assets.coin_multiplier()],
		"idle_duration": "Locked" if assets.idle_limit() <= 0.0 else "Lv. %d · %s" % [int(assets.levels.idle_duration), FishInspector.duration(assets.idle_limit())],
		"bubbles": "%d max · ×%.2f" % [assets.bubble_capacity(), assets.bubble_multiplier()]}
	for key in shop_cards:
		shop_cards[key].set_status(statuses[key])
	var item = shop_items[shop_selected_id]
	shop_detail_title.text = item.title
	shop_detail_description.text = item.description
	shop_action_button.position = Vector2(24, 350)
	shop_action_button.size = Vector2(333, 58)
	shop_action_button.add_theme_font_size_override("font_size", 17)
	shop_secondary_button.add_theme_font_size_override("font_size", 15)
	shop_tertiary_button.add_theme_font_size_override("font_size", 13)
	shop_secondary_button.hide()
	shop_tertiary_button.hide()
	var action_price: int = 0
	var unavailable: bool = false
	match shop_selected_id:
		"fish":
			action_price = current_fish_price
			unavailable = fish_count >= breeding.CAPACITY
			shop_detail_state.text = "Population %d/%d\nPrice rises by about 65%% for each additional fish." % [fish_count, breeding.CAPACITY]
			shop_action_button.text = "Buy fish  $%d" % action_price
		"snail":
			if not assets.owned.snail:
				action_price = assets.PRICES.snail
				shop_detail_state.text = "Not owned\nSpeed: 16 px/s · Stamina: 10s\nSleep after exhaustion: 20s"
				shop_action_button.text = "Buy snail  $%d" % action_price
			else:
				var speed_level: int = int(assets.levels.snail_speed)
				var stamina_level: int = int(assets.levels.snail_stamina)
				var sleep_level: int = int(assets.levels.snail_sleep)
				action_price = assets.upgrade_price("snail_speed")
				shop_detail_state.text = "Speed Lv. %d: %d px/s\nStamina Lv. %d: %ds moving\nSleep Lv. %d: %ds resting" % [speed_level + 1, int(assets.snail_speed()), stamina_level + 1, int(assets.snail_stamina()), sleep_level + 1, int(assets.snail_sleep())]
				shop_action_button.position = Vector2(24, 350)
				shop_action_button.size = Vector2(105, 58)
				shop_action_button.add_theme_font_size_override("font_size", 13)
				shop_action_button.text = "Speed\nMAX" if action_price == 0 else "Speed +1\n$%d" % action_price
				unavailable = action_price == 0
				var stamina_price: int = assets.upgrade_price("snail_stamina")
				shop_secondary_button.position = Vector2(138, 350)
				shop_secondary_button.size = Vector2(105, 58)
				shop_secondary_button.add_theme_font_size_override("font_size", 12)
				shop_secondary_button.text = "Stamina\nMAX" if stamina_price == 0 else "Stamina +1\n$%d" % stamina_price
				shop_secondary_button.disabled = stamina_price == 0 or stamina_price > economy.money
				shop_secondary_button.show()
				var sleep_price: int = assets.upgrade_price("snail_sleep")
				var sleep_reduction: int = 0 if sleep_price == 0 else int(assets.snail_sleep() - IdleAssets.SNAIL_SLEEPS[sleep_level + 1])
				shop_tertiary_button.position = Vector2(252, 350)
				shop_tertiary_button.size = Vector2(105, 58)
				shop_tertiary_button.add_theme_font_size_override("font_size", 12)
				shop_tertiary_button.text = "Sleep\nMAX" if sleep_price == 0 else "Sleep -%ds\n$%d" % [sleep_reduction, sleep_price]
				shop_tertiary_button.disabled = sleep_price == 0 or sleep_price > economy.money
				shop_tertiary_button.show()
		"seahorse":
			action_price = assets.PRICES.seahorse
			unavailable = assets.owned.seahorse
			shop_detail_state.text = "Owned" if unavailable else "Produces one Basic pellet every 8 simulation seconds when needed."
			shop_action_button.text = "Owned" if unavailable else "Buy seahorse  $%d" % action_price
		"puffer":
			if not assets.owned.puffer:
				action_price = assets.PRICES.puffer
				shop_detail_state.text = "Not owned · Active play only\n30% chance to chase each available bubble."
				shop_action_button.text = "Buy bubble puffer  $%d" % action_price
			else:
				var puffer_speed_level: int = int(assets.levels.puffer_speed)
				var curiosity_level: int = int(assets.levels.puffer_curiosity)
				action_price = assets.upgrade_price("puffer_speed")
				shop_detail_state.text = "Speed Lv. %d: %d px/s\nCuriosity Lv. %d: %d%% chase chance\nPuffs briefly after a catch." % [puffer_speed_level + 1, int(assets.puffer_speed()), curiosity_level + 1, int(assets.puffer_curiosity() * 100)]
				shop_action_button.position = Vector2(24, 350)
				shop_action_button.size = Vector2(160, 58)
				shop_action_button.text = "Speed MAX" if action_price == 0 else "Speed +1  $%d" % action_price
				unavailable = action_price == 0
				var curiosity_price: int = assets.upgrade_price("puffer_curiosity")
				shop_secondary_button.position = Vector2(222, 350)
				shop_secondary_button.size = Vector2(160, 58)
				shop_secondary_button.text = "Curiosity MAX" if curiosity_price == 0 else "Curiosity +1  $%d" % curiosity_price
				shop_secondary_button.disabled = curiosity_price == 0 or curiosity_price > economy.money
				shop_secondary_button.show()
		"feeder":
			action_price = assets.PRICES.feeder
			unavailable = assets.owned.feeder
			shop_detail_state.text = "Owned · Stock %d/%d" % [assets.reserve.size(), assets.CAPACITY] if unavailable else "Dispenses one stocked pellet every 2 simulation seconds when needed."
			shop_action_button.text = "Owned" if unavailable else "Buy auto-feeder  $%d" % action_price
		"stock":
			action_price = stock_count * feed.price
			unavailable = not assets.owned.feeder or stock_count == 0
			shop_detail_state.text = "Current stock: %d/%d\nNext batch: %d %s pellets" % [assets.reserve.size(), assets.CAPACITY, stock_count, feed.title]
			shop_action_button.text = "Requires auto-feeder" if not assets.owned.feeder else ("Stock full" if stock_count == 0 else "Buy %d pellets  $%d" % [stock_count, action_price])
		"feed":
			action_price = feed_upgrades.next_price()
			unavailable = action_price == 0
			shop_detail_state.text = "%s feed · $%d per pellet · %d growth credit" % [feed.title, feed.price, feed.growth_credit]
			shop_action_button.text = "Fully upgraded" if unavailable else "Unlock %s  $%d" % [feeds[feed_upgrades.unlocked_tier + 1].title, action_price]
		"coin_lifetime":
			var level: int = int(assets.levels.coin_lifetime)
			action_price = assets.upgrade_price("coin_lifetime")
			unavailable = action_price == 0
			var next_text: String = "Maximum preservation reached" if unavailable else "%d → %d simulation seconds" % [int(assets.coin_lifetime()), int(IdleAssets.COIN_LIFETIMES[level + 1])]
			shop_detail_state.text = "Level %d / 5\n%s\nExisting rewards gain the added time." % [level + 1, next_text]
			shop_action_button.text = "Fully upgraded" if unavailable else "Preserve longer  $%d" % action_price
		"coin_value":
			var value_level: int = int(assets.levels.coin_value)
			action_price = assets.upgrade_price("coin_value")
			unavailable = action_price == 0
			var next_value: String = "Maximum value reached" if unavailable else "×%d → ×%d for future fish coins" % [assets.coin_multiplier(), IdleAssets.COIN_MULTIPLIERS[value_level + 1]]
			shop_detail_state.text = "Level %d / 5\n%s\nCoin color still follows the fish's life stage." % [value_level + 1, next_value]
			shop_action_button.text = "Fully upgraded" if unavailable else "Raise coin value  $%d" % action_price
		"idle_duration":
			var idle_level: int = int(assets.levels.idle_duration)
			action_price = assets.upgrade_price("idle_duration")
			unavailable = action_price == 0
			var current_limit: String = "Locked: no offline simulation" if assets.idle_limit() <= 0.0 else "Current limit: %s real time" % FishInspector.duration(assets.idle_limit())
			var next_limit: String = "Maximum away time reached" if unavailable else "Next: %s real time" % FishInspector.duration(IdleAssets.IDLE_LIMITS[idle_level + 1])
			shop_detail_state.text = "%s\n%s\nAway care advances at 10%% speed." % [current_limit, next_limit]
			shop_action_button.text = "Fully upgraded" if unavailable else "Extend away time  $%d" % action_price
		"bubbles":
			var capacity_level: int = int(assets.levels.bubble_capacity)
			var value_level: int = int(assets.levels.bubble_value)
			action_price = assets.upgrade_price("bubble_capacity")
			unavailable = action_price == 0
			shop_detail_state.text = "Capacity Lv. %d: %d bubbles\nValue Lv. %d: ×%.2f per pop\nBubbles remain active-play income." % [capacity_level + 1, assets.bubble_capacity(), value_level + 1, assets.bubble_multiplier()]
			shop_action_button.position = Vector2(24, 350)
			shop_action_button.size = Vector2(160, 58)
			shop_action_button.text = "Capacity MAX" if unavailable else "Capacity +1  $%d" % action_price
			var value_price: int = assets.upgrade_price("bubble_value")
			shop_secondary_button.position = Vector2(222, 350)
			shop_secondary_button.size = Vector2(160, 58)
			shop_secondary_button.text = "Value MAX" if value_price == 0 else "Value +1  $%d" % value_price
			shop_secondary_button.disabled = value_price == 0 or value_price > economy.money
			shop_secondary_button.show()
	shop_action_button.disabled = unavailable or action_price > economy.money
	buy_button = shop_action_button

func update_money(amount: float) -> void:
	care_refresh = 0.0
	money_label.text = "$ " + Economy.format_money(amount)
	var feed: FeedProfile = feeds[feed_upgrades.unlocked_tier]
	feed_label.text = "%s feed  $%d  ·  %d growth" % [feed.title, feed.price, feed.growth_credit]
	feed_status.text = "Click water to feed" if amount >= feeds[feed_upgrades.unlocked_tier].price else "Not enough money for this feed"
	update_cleanliness()
	refresh_shop()

func label_at(parent: Node, text: String, at: Vector2, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.position = at
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)
	return label

func refresh_care() -> void:
	care_refresh = 10.0
	var care := TankCare.assess(snapshot())
	var capacity: String = "Supply meets average demand" if care.adequate else "Supply below average demand: manual feeding needed"
	care_details.text = "Stock: %d / 200 pellets | Fish: %d / 20\nAutomation: %.1f meals/min | Estimated need: %.1f/min active\n%s\n\n%s\n\nApproximate care, not a guarantee. Swimming and food competition vary.\nFixed population; no away breeding or aliens. Refreshes every 10s." % [care.stock, care.count, care.supply, care.demand, capacity, TankCare.forecast_text(care)]
	care_warnings.text = TankCare.warnings(get_tree().get_nodes_in_group("fish"), assets.reserve.size(), assets.owned.feeder, environment.cleanliness)

func build_hud() -> void:
	var hud := CanvasLayer.new()
	hud_layer = hud
	add_child(hud)
	label_at(hud, "I N S A N A R I U M", Vector2(48, 4), 23, Color("e8f2ed"))
	label_at(hud, "01  /  THE QUIET TANK", Vector2(300, 5), 13, Color("c7dfdb"))
	label_at(hud, "YOUR WALLET", Vector2(785, 4), 11, Color("83a9b7"))
	money_label = label_at(hud, "", Vector2(782, 20), 23, Color("ffdb80"))
	shop_button = Button.new()
	shop_button.position = Vector2(930, 7)
	shop_button.size = Vector2(174, 46)
	shop_button.text = "SHOP"
	shop_button.add_theme_font_size_override("font_size", 18)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("28565b")
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	shop_button.add_theme_stylebox_override("normal", style)
	hud.add_child(shop_button)
	shop_button.pressed.connect(toggle_shop)
	controls_button = make_button(hud, "CONTROLS", Vector2(600, 7), Vector2(150, 46), func() -> void:
		care_panel.visible = not care_panel.visible
		if care_panel.visible:
			refresh_care())
	care_panel = Panel.new()
	care_panel.position = Vector2(251, 10)
	care_panel.size = Vector2(650, 580)
	care_panel.z_index = 25
	var care_style := StyleBoxFlat.new()
	care_style.bg_color = Color("0c2636")
	care_style.border_color = Color("729b9e")
	care_style.set_border_width_all(1)
	care_style.set_corner_radius_all(12)
	care_panel.add_theme_stylebox_override("panel", care_style)
	hud.add_child(care_panel)
	label_at(care_panel, "CONTROLS & TANK CARE", Vector2(18, 15), 19, Color("e8f2ed"))
	care_warnings = label_at(care_panel, "", Vector2(18, 52), 15, Color("ffa86b"))
	care_warnings.size = Vector2(612, 50)
	care_warnings.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	care_details = label_at(care_panel, "", Vector2(18, 107), 15, Color("c7dfdb"))
	care_details.size = Vector2(612, 230)
	care_details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	make_button(care_panel, "Close", Vector2(550, 10), Vector2(82, 30), care_panel.hide)
	care_panel.hide()
	count_label = label_at(hud, "", Vector2(300, 31), 12, Color("83a9b7"))
	cleanliness_label = label_at(hud, "", Vector2(450, 4), 12, Color("8edfe9"))
	cleanliness_label.size = Vector2(150, 28)
	clean_button = make_button(hud, "Full clean", Vector2(450, 27), Vector2(130, 28), purchase_full_clean)
	clean_button.add_theme_font_size_override("font_size", 12)
	update_cleanliness()
	feed_label = label_at(hud, "", Vector2(49, 570), 14, Color("e8f2ed"))
	feed_status = label_at(hud, "", Vector2(285, 570), 12, Color("c7dfdb"))
	footer_hint = label_at(hud, "Tap water to feed · tap rewards/waste to collect", Vector2(680, 570), 12, Color("83a9b7"))
	var debug := DebugControls.new()
	debug.hunger_requested.connect(func() -> void:
		for fish in get_tree().get_nodes_in_group("fish"):
			fish.hunger = 1.0)
	debug.coins_requested.connect(func() -> void:
		for i in range(1, 5):
			spawn_coin(Vector2(400 + i * 90, 320), 10 if i == 4 else i, i == 4, i))
	debug.invasion_requested.connect(func() -> void:
		if challenges:
			invasions.begin_warning())
	hud.add_child(debug)
	inspector_panel = Panel.new()
	inspector_panel.position = Vector2(735, 66)
	inspector_panel.size = Vector2(348, 524)
	inspector_panel.z_index = 15
	var inspector_style := StyleBoxFlat.new()
	inspector_style.bg_color = Color("0c2636")
	inspector_style.border_color = Color("729b9e")
	inspector_style.set_border_width_all(1)
	inspector_style.set_corner_radius_all(12)
	inspector_panel.add_theme_stylebox_override("panel", inspector_style)
	hud.add_child(inspector_panel)
	inspector_detail = label_at(inspector_panel, "", Vector2(16, 14), 13, Color("d2e6df"))
	inspector_detail.size = Vector2(316, 276)
	inspector_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	for index in range(6):
		var trait_bar: FishTraitBar = FishTraitBarScript.new()
		trait_bar.position = Vector2(16, 294 + index * 27)
		inspector_panel.add_child(trait_bar)
		inspector_trait_bars.append(trait_bar)
	make_button(inspector_panel, "×", Vector2(308, 5), Vector2(30, 28), func() -> void:
		if is_instance_valid(selected_fish):
			selected_fish.selected = false
		selected_fish = null
		update_inspection())
	inspector_panel.hide()
	inspect_label = label_at(hud, "Tap a fish to inspect it", Vector2(49, 32), 12, Color("83a9b7"))
	sell_button = make_button(inspector_panel, "Select a fish to sell", Vector2(69, 478), Vector2(210, 38), sell_selected)
	sell_button.disabled = true
	var challenge := CheckButton.new()
	challenge.text = "Alien challenges"
	challenge.position = Vector2(350, 390)
	challenge.button_pressed = challenges
	challenge.toggled.connect(func(enabled: bool) -> void:
		challenges = enabled
		invasions.running = enabled
		if not enabled:
			audio.set_danger_music(false)
			invasions.stop()
			if is_instance_valid(invasions.active):
				invasions.active.queue_free()
		else:
			invasions.schedule_next())
	care_panel.add_child(challenge)
	breeding_toggle = CheckButton.new()
	breeding_toggle.text = "Allow breeding"
	breeding_toggle.position = Vector2(18, 390)
	breeding_toggle.button_pressed = breeding.enabled
	breeding_toggle.toggled.connect(func(value: bool) -> void: breeding.enabled = value)
	care_panel.add_child(breeding_toggle)
	pace_label = label_at(hud, "ACTIVE · 1×", Vector2(520, 570), 11, Color("83a9b7"))
	breeding_status = label_at(care_panel, "Well-fed adult pairs · 5 min cooldown", Vector2(18, 428), 14, Color("83a9b7"))
	save_label = label_at(hud, "Autosave", Vector2(1040, 570), 10, Color("83a9b7"))
	transfer = SaveTransfer.new()
	add_child(transfer)
	transfer.import_ready.connect(confirm_import)
	transfer.status.connect(func(message: String) -> void: save_label.text = message)
	sound_button = make_button(care_panel, "Sound: off" if audio.muted else "Sound: on", Vector2(18, 465), Vector2(180, 42), func() -> void:
		audio.set_muted(not audio.muted)
		sound_button.text = "Sound: off" if audio.muted else "Sound: on"
		if not audio.muted:
			audio.play("bubble"))
	make_button(care_panel, "Export backup", Vector2(214, 465), Vector2(180, 42), func() -> void: transfer.export_save(snapshot()))
	make_button(care_panel, "Import backup", Vector2(410, 465), Vector2(180, 42), transfer.import_save)
	label_at(care_panel, "Away time is upgradeable · No offline breeding or aliens", Vector2(18, 531), 12, Color("83a9b7"))
	return_dialog = AcceptDialog.new()
	return_dialog.title = "Welcome back"
	add_child(return_dialog)
	import_dialog = ConfirmationDialog.new()
	import_dialog.title = "Restore backup"
	import_dialog.confirmed.connect(finish_import)
	add_child(import_dialog)
	build_shop(hud)
	reveal_panel = FishRevealPanelScript.new()
	reveal_panel.position = Vector2(300, 5)
	reveal_panel.z_index = 30
	hud.add_child(reveal_panel)
	reveal_panel.dismissed.connect(advance_fish_reveal)
	reveal_panel.inspect_requested.connect(inspect_revealed_fish)
	var orientation_gate: MobileOrientationGate = MobileOrientationGateScript.new()
	hud.add_child(orientation_gate)

func build_shop(hud: CanvasLayer) -> void:
	shop_panel = Panel.new()
	shop_panel.position = Vector2(16, 10)
	shop_panel.size = Vector2(1120, 580)
	shop_panel.z_index = 20
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color("0b2230")
	panel_style.border_color = Color("729b9e")
	panel_style.set_border_width_all(2)
	panel_style.set_corner_radius_all(16)
	shop_panel.add_theme_stylebox_override("panel", panel_style)
	hud.add_child(shop_panel)
	label_at(shop_panel, "AQUARIUM SHOP", Vector2(30, 14), 25, Color("e8f2ed"))
	label_at(shop_panel, "Tap a card to see details, purchase it, or upgrade it.", Vector2(31, 49), 14, Color("83a9b7"))
	make_button(shop_panel, "Close", Vector2(960, 14), Vector2(96, 42), toggle_shop)

	var grid := GridContainer.new()
	grid.position = Vector2(30, 72)
	grid.size = Vector2(600, 430)
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	shop_panel.add_child(grid)
	for item in ShopItemScript.catalog():
		shop_items[item.id] = item
		var card = ShopCardScript.new()
		card.configure(item)
		card.pressed.connect(select_shop_item.bind(item.id))
		grid.add_child(card)
		shop_cards[item.id] = card

	var detail := Panel.new()
	detail.position = Vector2(650, 72)
	detail.size = Vector2(440, 430)
	var detail_style := StyleBoxFlat.new()
	detail_style.bg_color = Color("0e2b39")
	detail_style.border_color = Color("315b68")
	detail_style.set_border_width_all(1)
	detail_style.set_corner_radius_all(12)
	detail.add_theme_stylebox_override("panel", detail_style)
	shop_panel.add_child(detail)
	label_at(detail, "SELECTED", Vector2(24, 22), 12, Color("8edfe9"))
	shop_detail_title = label_at(detail, "", Vector2(24, 53), 25, Color("e8f2ed"))
	shop_detail_description = label_at(detail, "", Vector2(24, 102), 15, Color("c7dfdb"))
	shop_detail_description.size = Vector2(392, 105)
	shop_detail_description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	shop_detail_state = label_at(detail, "", Vector2(24, 229), 16, Color("83a9b7"))
	shop_detail_state.size = Vector2(392, 100)
	shop_detail_state.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	shop_action_button = make_button(detail, "", Vector2(24, 350), Vector2(392, 58), activate_shop_item)
	shop_action_button.add_theme_font_size_override("font_size", 17)
	shop_secondary_button = make_button(detail, "", Vector2(222, 350), Vector2(194, 58), activate_shop_secondary)
	shop_secondary_button.add_theme_font_size_override("font_size", 15)
	shop_secondary_button.hide()
	shop_tertiary_button = make_button(detail, "", Vector2(286, 350), Vector2(130, 58), activate_shop_tertiary)
	shop_tertiary_button.add_theme_font_size_override("font_size", 13)
	shop_tertiary_button.hide()

	var rule := ColorRect.new()
	rule.position = Vector2(30, 512)
	rule.size = Vector2(1060, 1)
	rule.color = Color("305764")
	rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shop_panel.add_child(rule)
	shop_status = label_at(shop_panel, "Choose something for your aquarium.", Vector2(31, 523), 15, Color("ffdb80"))
	shop_status.size = Vector2(1025, 35)
	shop_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label_at(shop_panel, "Purchases and upgrades are saved locally.", Vector2(760, 528), 12, Color("83a9b7"))
	select_shop_item("fish")
	shop_panel.hide()

func make_button(parent: Node, text: String, at: Vector2, dimensions: Vector2, action: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.position = at
	button.size = dimensions
	button.pressed.connect(action)
	parent.add_child(button)
	return button


func _draw() -> void:
	draw_style_box(tank_style(), tank_rect)
	if assets.owned.feeder:
		VectorArt.draw_feeder(self, Vector2(tank_rect.get_center().x - 56, 155), 1.0, true)
	for i in range(12):
		var y: float = 174.0 + i * 40.0
		draw_rect(Rect2(tank_rect.position.x + 2, y, tank_rect.size.x - 4, 40), Color(0.07, 0.25, 0.31, 0.12 + i * 0.015))
	var left := tank_rect.position.x
	var right := tank_rect.end.x
	draw_colored_polygon(PackedVector2Array([Vector2(left + 112, 168), Vector2(left + 242, 168), Vector2(left + 562, 638), Vector2(left + 302, 638)]), Color(0.6, 0.9, 0.87, 0.035))
	draw_colored_polygon(PackedVector2Array([Vector2(right - 394, 168), Vector2(right - 334, 168), Vector2(right - 104, 638), Vector2(right - 234, 638)]), Color(0.6, 0.9, 0.87, 0.035))
	var murk: float = clampf((70.0 - environment.cleanliness) / 70.0, 0.0, 1.0)
	draw_rect(Rect2(left + 2, 168, tank_rect.size.x - 4, 480), Color(0.22, 0.20, 0.07, murk * 0.16))
	draw_rect(Rect2(left + 2, 648, tank_rect.size.x - 4, 20), Color("344b49"))
	var gravel_count: int = floori((tank_rect.size.x - 20.0) / 38.0)
	for i in range(gravel_count):
		var x: float = left + 15.0 + i * 38.0
		draw_circle(Vector2(x, 652 + sin(i * 2.4) * 4), 3, Color("6d8070"))
	for x in [left + 52.0, left + 87.0, right - 114.0, right - 74.0, right - 44.0]:
		for j in range(3):
			var points := PackedVector2Array()
			for k in range(12):
				points.append(Vector2(x + sin(k * 0.5 + j) * 12 + j * 7, 649 - k * (6 + j * 2)))
			draw_polyline(points, Color("397f76") if j % 2 == 0 else Color("4c9881"), 6, true)
	for i in range(16):
		var at := Vector2(left + 32.0 + fmod(i * 173.0, tank_rect.size.x - 64.0), 220 + fmod(i * 97.0, 360.0))
		draw_arc(at, 2.0 + i % 3, 0, TAU, 16, Color(0.55, 0.82, 0.86, 0.18), 1, true)

func tank_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("103343")
	style.border_color = Color("305764")
	style.set_border_width_all(2)
	style.set_corner_radius_all(14)
	return style

func snapshot() -> Dictionary:
	var fish_data: Array = []
	for fish in get_tree().get_nodes_in_group("fish"):
		fish_data.append({"x": fish.position.x, "y": fish.position.y, "hunger": fish.hunger, "health": fish.health.current, "genome": fish.genome.to_data(),
			"life": fish.life.to_data(), "species_id": fish.profile.species_id,
			"sex": fish.sex, "breeding_left": fish.breeding_left,
			"starving": fish.survival.starving_for, "meals": fish.growth.meals,
			"credit": fish.growth.growth_credit, "stage": fish.growth.stage,
			"mutation": fish.mutation.variant, "coin_left": fish.coin_left})
	var rewards: Array = []
	for coin in get_tree().get_nodes_in_group("coins"):
		if not coin.claimed and not coin.is_queued_for_deletion():
			rewards.append({"x": coin.position.x, "y": coin.position.y, "value": coin.value, "diamond": coin.diamond, "grade": coin.grade, "life": coin.lifetime, "grounded": coin.grounded})
	var waste_data: Array = []
	for waste in get_tree().get_nodes_in_group("waste"):
		if not waste.is_queued_for_deletion():
			waste_data.append({"x": waste.position.x, "y": waste.position.y, "settled": waste.settled, "life": waste.lifetime})
	var pellets: Array = []
	for food in get_tree().get_nodes_in_group("food"):
		if not food.consumed and not food.is_queued_for_deletion():
			pellets.append({"x": food.position.x, "y": food.position.y, "tier": feeds.find(food.profile), "life": food.lifetime})
	var seahorse_left: float = 8.0
	var snail_x: float = 300.0
	var snail_stamina: float = assets.snail_stamina()
	var snail_sleep: float = 0.0
	var puffer_x: float = 760.0
	var puffer_y: float = 440.0
	var puffer_destination := Vector2(760, 440)
	var puffer_wander: float = 0.0
	var puffer_puff: float = 0.0
	for pet in get_tree().get_nodes_in_group("pets"):
		if pet is SeahorsePet:
			seahorse_left = pet.feed_left
		elif pet is SnailPet:
			snail_x = pet.position.x
			snail_stamina = pet.stamina_left
			snail_sleep = pet.sleep_left
		elif pet is BubblePufferScript:
			puffer_x = pet.position.x
			puffer_y = pet.position.y
			puffer_destination = pet.destination
			puffer_wander = pet.wander_left
			puffer_puff = pet.puff_left
	return {"saved_at": Time.get_unix_time_from_system(), "feeder_left": maxf(0.0, assets.feeder_left), "seahorse_left": seahorse_left, "version": 3, "next_fish_id": life_registry.next_id, "simulation_elapsed": life_registry.elapsed, "pace_version": 2, "breeding_enabled": breeding.enabled, "breeding_check": breeding.check_left, "money": economy.money, "tier": feed_upgrades.unlocked_tier,
		"snail_x": snail_x, "snail_stamina": snail_stamina, "snail_sleep": snail_sleep, "snail_collection_progress": snail_collection_progress,
		"puffer_x": puffer_x, "puffer_y": puffer_y, "puffer_destination_x": puffer_destination.x, "puffer_destination_y": puffer_destination.y, "puffer_wander": puffer_wander, "puffer_puff": puffer_puff,
		"owned": assets.owned.duplicate(), "asset_levels": assets.levels.duplicate(), "reserve": assets.reserve.duplicate(),
		"cleanliness": environment.cleanliness, "waste": waste_data,
		"fish": fish_data, "coins": rewards, "food": pellets}

func restore(data: Dictionary) -> void:
	data = SaveMigration.upgrade(data)
	life_registry.next_id = int(data.next_fish_id)
	life_registry.elapsed = float(data.simulation_elapsed)
	breeding.enabled = bool(data.get("breeding_enabled", true))
	breeding.check_left = clampf(float(data.get("breeding_check", 30)), 0, 30)
	breeding_toggle.set_pressed_no_signal(breeding.enabled)
	economy.money = maxf(0.0, float(data.get("money", 100)))
	environment.cleanliness = clampf(float(data.get("cleanliness", TankEnvironment.MAX_CLEANLINESS)), 0.0, TankEnvironment.MAX_CLEANLINESS)
	feed_upgrades.unlocked_tier = clampi(int(data.get("tier", 0)), 0, 2)
	snail_collection_progress = clampf(float(data.get("snail_collection_progress", 0)), 0, 0.999)
	for track in assets.levels:
		assets.levels[track] = clampi(int(data.get("asset_levels", {}).get(track, 0)), 0, assets.MAX_UPGRADE_LEVEL)
	for kind in assets.owned:
		assets.owned[kind] = bool(data.get("owned", {}).get(kind, false))
		if assets.owned[kind]:
			spawn_asset(kind)
	assets.feeder_left = clampf(float(data.get("feeder_left", 2)), 0, 2)
	for pet in get_tree().get_nodes_in_group("pets"):
		if pet is SeahorsePet:
			pet.feed_left = clampf(float(data.get("seahorse_left", 8)), 0, 8)
		elif pet is SnailPet:
			pet.position.x = clampf(float(data.get("snail_x", 300)), pet.horizontal_bounds.x, pet.horizontal_bounds.y)
			pet.stamina_left = clampf(float(data.get("snail_stamina", pet.max_stamina)), 0, pet.max_stamina)
			pet.sleep_left = clampf(float(data.get("snail_sleep", 0)), 0, pet.sleep_duration)
		elif pet is BubblePufferScript:
			pet.position = Vector2(float(data.get("puffer_x", 760)), float(data.get("puffer_y", 440))).clamp(pet.bounds.position, pet.bounds.end)
			pet.destination = Vector2(float(data.get("puffer_destination_x", pet.position.x)), float(data.get("puffer_destination_y", pet.position.y))).clamp(pet.bounds.position, pet.bounds.end)
			pet.wander_left = clampf(float(data.get("puffer_wander", 0)), 0, 4)
			pet.puff_left = clampf(float(data.get("puffer_puff", 0)), 0, pet.PUFF_DURATION)
	for tier in data.get("reserve", []).slice(0, assets.CAPACITY):
		assets.reserve.append(clampi(int(tier), 0, 2))
	for item in data.get("fish", []).slice(0, 50):
		var fish := spawn_fish(true)
		fish.life.from_data(item.life)
		fish.genome.from_data(item.get("genome", {}))
		fish.apply_genome(false)
		fish.sex = clampi(int(item.get("sex", fish.sex)), 0, 2) as AquariumFish.Sex
		fish.breeding_left = clampf(float(item.get("breeding_left", 0)), 0, 300)
		fish.position = Vector2(item.get("x", 500), item.get("y", 350)).clamp(swim_bounds.position, swim_bounds.end)
		fish.hunger = clampf(float(item.get("hunger", 0)), 0, 1)
		fish.health.current = clampf(float(item.get("health", fish.health.maximum)), 0.01, fish.health.maximum)
		var saved_starvation: float = float(item.get("starving", 0))
		if int(data.get("pace_version", 1)) < 2:
			saved_starvation *= fish.profile.starvation_grace / 180.0
		fish.survival.starving_for = clampf(saved_starvation, 0, fish.profile.starvation_grace)
		fish.growth.meals = maxi(0, int(item.get("meals", 0)))
		fish.growth.growth_credit = maxf(0.0, float(item.get("credit", 0)))
		fish.growth.stage = clampi(int(item.get("stage", 0)), 0, 4)
		fish.mutation.variant = clampi(int(item.get("mutation", 0)), 0, 3)
		fish.visual_size = fish.profile.growth_sizes[fish.growth.stage]
		fish.scale = Vector2.ONE * fish.visual_size
		fish.coin_left = clampf(float(item.get("coin_left", 20)), 0, fish.genome.output_interval(fish.profile.coin_interval))
	for item in data.get("coins", []).slice(0, 150):
		var coin := spawn_coin(Vector2(item.get("x", 500), item.get("y", 650)), maxi(1, int(item.get("value", 1))), bool(item.get("diamond", false)), int(item.get("grade", -1)))
		coin.lifetime = clampf(float(item.get("life", assets.coin_lifetime())), 0.01, TankCoin.MAX_LIFETIME)
		coin.grounded = bool(item.get("grounded", coin.position.y >= coin.floor_y))
	for item in data.get("waste", []).slice(0, 100):
		var waste := FishWaste.new()
		waste.position = Vector2(float(item.get("x", 500)), float(item.get("y", 642))).clamp(swim_bounds.position, Vector2(swim_bounds.end.x, waste.floor_y))
		waste.settled = bool(item.get("settled", waste.position.y >= waste.floor_y))
		waste.lifetime = clampf(float(item.get("life", FishWaste.FLOOR_LIFETIME)), 0.01, FishWaste.FLOOR_LIFETIME)
		waste.process_mode = Node.PROCESS_MODE_PAUSABLE
		add_child(waste)
	for item in data.get("food", []).slice(0, 80):
		var food := spawn_food(Vector2(item.get("x", 500), item.get("y", 350)), feeds[clampi(int(item.get("tier", 0)), 0, 2)])
		food.lifetime = clampf(float(item.get("life", 14)), 0, 14)
	update_count()
	update_cleanliness()

func save_now() -> void:
	if persistence:
		save_label.text = "Saved locally" if LocalSave.write(away_data if not away_data.is_empty() else snapshot()) else "Save failed"

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		set_idle(true)
	elif what == NOTIFICATION_APPLICATION_FOCUS_IN:
		set_idle(false)
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		if is_instance_valid(economy) and is_instance_valid(save_label):
			save_now()
