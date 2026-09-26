class_name AquariumFish
extends Node2D
const VectorArt = preload("res://scripts/art/aquarium_vector_art.gd")
signal coin_produced(at: Vector2, value: int, diamond: bool, grade: int)
signal waste_produced(at: Vector2)
signal grew(at: Vector2, stage_name: String)
signal died(at: Vector2, reason: String)
enum Sex { MALE, FEMALE, ASEXUAL }
const SEX_NAMES := ["Male", "Female", "Asexual"]
var life := FishLife.new()
var sex: Sex = Sex.MALE
var breeding_left: float = 0.0
var mutation := FishMutation.new()
var genome := FishGenome.new()
var survival := FishSurvival.new()
var health := FishHealth.new()
var dead: bool = false
var selected: bool = false
var growth := FishGrowth.new()
var visual_size: float = 0.75
var presentation_scale: float = 1.0
var profile: FishProfile
var bounds: Rect2
var hunger: float = 0.0
var destination: Vector2
var food_target: FishFood
var prey_target: AquariumFish
var wander_left: float = 0.0
var coin_left: float = 0.0
var facing: float = 1.0
var phase: float = 0.0

func _ready() -> void:
	add_to_group("fish")
	if profile == null:
		profile = FishProfile.new()
	health.configure_maximum(genome.max_health(), true)
	growth.stage_changed.connect(_on_stage_changed)
	visual_size = profile.growth_sizes[growth.stage] * presentation_scale
	scale = Vector2.ONE * visual_size
	hunger = randf_range(0.1, 0.48)
	coin_left = randf_range(3.0, genome.output_interval(profile.coin_interval))
	phase = randf() * TAU
	choose_destination()

func choose_destination() -> void:
	destination = Vector2(randf_range(bounds.position.x, bounds.end.x), randf_range(bounds.position.y, bounds.end.y))
	wander_left = randf_range(2.0, 5.0)

func _process(delta: float) -> void:
	delta *= ActivityPace.multiplier
	if dead:
		return
	life.age_seconds += delta
	if life.age_seconds >= FishAging.lifespan_for(genome):
		die("Old age")
		return
	hunger = minf(1.0, hunger + profile.hunger_rate * genome.hunger_multiplier() * delta)
	coin_left -= delta
	if coin_left <= 0.0:
		coin_left += genome.output_interval(profile.coin_interval)
		# Newborns have a short protected stage before they begin producing output.
		if growth.stage > 0:
			var output_at := position + Vector2(-12 * facing, 16)
			if randf() > genome.coin_chance():
				waste_produced.emit(output_at)
			else:
				coin_produced.emit(output_at, current_coin_value(), growth.stage >= profile.diamond_stage, growth.stage)
	if not is_instance_valid(food_target) or food_target.is_queued_for_deletion():
		food_target = null
	if hunger >= profile.hungry_threshold and food_target == null:
		var nearest: float = profile.detection_radius
		for item in get_tree().get_nodes_in_group("food"):
			if item.consumed or item.is_queued_for_deletion():
				continue
			var distance: float = position.distance_to(item.position)
			if distance < nearest:
				nearest = distance
				food_target = item
	if hunger < profile.predation_hunger or not is_instance_valid(prey_target) or (prey_target != null and not FishPredation.eligible(self, prey_target)):
		prey_target = null
	if food_target != null:
		prey_target = null
	elif prey_target == null:
		prey_target = FishPredation.nearest(self, get_tree().get_nodes_in_group("fish"))
	wander_left -= delta
	if food_target != null:
		destination = food_target.position
	elif prey_target != null:
		destination = prey_target.position
	elif wander_left <= 0.0 or position.distance_to(destination) < 12.0:
		choose_destination()
	var movement: Vector2 = destination - position
	var movement_speed: float = swim_speed() * (1.5 if food_target != null else (1.35 if prey_target != null else 1.0))
	position = position.move_toward(destination, movement_speed * delta)
	position = position.clamp(bounds.position, bounds.end)
	if absf(movement.x) > 3.0:
		facing = signf(movement.x)
	visual_size = move_toward(visual_size, profile.growth_sizes[growth.stage] * presentation_scale, delta * 0.5)
	scale.x = move_toward(scale.x, facing * visual_size, delta * 5.0)
	scale.y = visual_size
	phase += delta * 7.0
	if food_target != null and position.distance_to(food_target.position) < 23.0:
		if food_target.consume():
			hunger = maxf(0.0, hunger - food_target.profile.nutrition)
			survival.fed()
			growth.record_meal(profile, food_target.profile.growth_credit, genome.growth_multiplier())
		food_target = null
		choose_destination()
	if prey_target != null and position.distance_to(prey_target.position) < 20.0 * visual_size + 8.0:
		if FishPredation.eligible(self, prey_target) and prey_target.consume_by_predator():
			hunger = maxf(0.0, hunger - profile.prey_nutrition)
			survival.fed()
			growth.record_meal(profile, profile.prey_growth_credit, genome.growth_multiplier())
		prey_target = null
		choose_destination()
	if survival.advance(hunger, delta, profile.starvation_grace):
		die("Starved")
	queue_redraw()

func die(reason: String) -> void:
	if dead:
		return
	dead = true
	remove_from_group("fish")
	set_process(false)
	died.emit(position, reason)
	# Restore the full silhouette if death happens midway through a turn.
	scale.x = facing * visual_size
	queue_redraw()
	var surface_y: float = bounds.position.y
	var rise_time: float = maxf(0.5, (position.y - surface_y) / 70.0)
	var tween := create_tween().set_parallel(true)
	tween.tween_property(self, "scale:y", -visual_size, 0.35).set_trans(Tween.TRANS_SINE)
	tween.tween_property(self, "position:y", surface_y, rise_time)
	# Remain visible throughout the rise; fade only after reaching the surface.
	tween.chain().tween_property(self, "modulate:a", 0.0, 0.6)
	tween.chain().tween_callback(queue_free)

func consume_by_predator() -> bool:
	if dead:
		return false
	dead = true
	remove_from_group("fish")
	set_process(false)
	died.emit(position, "Eaten by piranha")
	queue_free()
	return true

func current_coin_value() -> int:
	return profile.coin_value * profile.growth_rewards[growth.stage]

func sell_value() -> int:
	return mutation.sell_value(growth.stage)

func wears_crown() -> bool:
	return growth.stage >= profile.diamond_stage

func _on_stage_changed(stage: int) -> void:
	if mutation.roll():
		grew.emit(position, mutation.NAMES[mutation.variant] + " mutation!")
	grew.emit(position, profile.growth_names[stage])

func _draw() -> void:
	if selected and not dead:
		draw_arc(Vector2.ZERO, 33, 0, TAU, 40, Color("d4f0df"), 1.5, true)
	var color: Color = profile.body_color if mutation.variant == 0 else mutation.COLORS[mutation.variant]
	var tail: float = sin(phase) * 4.0
	if profile.species_id == "piranha":
		VectorArt.draw_piranha(self, Vector2.ZERO, 1.0, color, tail, dead, wears_crown())
	else:
		VectorArt.draw_fish(self, Vector2.ZERO, 1.0, color, tail, dead, wears_crown())
	if not dead and hunger >= profile.hungry_threshold:
		draw_circle(Vector2(0, -34), 5, Color("ff657f") if hunger >= 1.0 else Color("ffa86b"))
	if not dead and hunger >= 1.0:
		draw_rect(Rect2(-18, -46, 36, 4), Color("533545"))
		draw_rect(Rect2(-18, -46, 36 * clampf(1.0 - survival.starving_for / profile.starvation_grace, 0.0, 1.0), 4), Color("ff657f"))
	if not dead and health.current < health.maximum - 0.01:
		var health_ratio: float = health.current / health.maximum
		draw_rect(Rect2(-18, 29, 36, 4), Color("3c4650"))
		draw_rect(Rect2(-18, 29, 36 * health_ratio, 4), Color("79d68a") if health_ratio >= 0.5 else Color("ff657f"))

func apply_genome(fill_health: bool = false) -> void:
	health.configure_maximum(genome.max_health(), fill_health)
	coin_left = minf(coin_left, genome.output_interval(profile.coin_interval))

func swim_speed() -> float:
	return profile.swim_speed * genome.speed_multiplier()
