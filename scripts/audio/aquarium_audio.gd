class_name AquariumAudio
extends Node
## Synthesized effects with local, freely licensed music files; no backend.
const SETTINGS := "user://audio.cfg"
const CALM_MUSIC: AudioStream = preload("res://assets/audio/underwater_theme_ii.ogg")
const ALIEN_MUSIC: AudioStream = preload("res://assets/audio/space_battle.ogg")
const CALM_DB := -14.0
const ALIEN_DB := -10.0
const SILENT_DB := -60.0
const MUSIC_FADE_DB_PER_SECOND := 28.0
var music_muted: bool = false
var effects_muted: bool = false
var voices: Array[AudioStreamPlayer] = []
var effects: Dictionary = {}
var last_played: Dictionary = {}
var calm_music: AudioStreamPlayer
var alien_music: AudioStreamPlayer
var danger_music: bool = false

func _ready() -> void:
	if not "--test" in OS.get_cmdline_user_args():
		var config := ConfigFile.new()
		if config.load(SETTINGS) == OK:
			# Older builds stored one mute switch. Use it as the default for both
			# channels until each independent preference has been saved.
			var legacy_muted: bool = bool(config.get_value("audio", "muted", false))
			music_muted = bool(config.get_value("audio", "music_muted", legacy_muted))
			effects_muted = bool(config.get_value("audio", "effects_muted", legacy_muted))
	for kind in ["bubble", "feed", "coin", "buy", "grow", "loss", "alert", "hit"]:
		effects[kind] = synthesize(kind)
	for i in range(6):
		var voice := AudioStreamPlayer.new()
		voice.volume_db = -12.0
		add_child(voice)
		voices.append(voice)
	calm_music = make_music_player(looping_copy(CALM_MUSIC), CALM_DB)
	alien_music = make_music_player(looping_copy(ALIEN_MUSIC), SILENT_DB)
	if not music_muted:
		start_music()

func _process(delta: float) -> void:
	if music_muted:
		return
	var calm_target: float = SILENT_DB if danger_music else CALM_DB
	var alien_target: float = ALIEN_DB if danger_music else SILENT_DB
	calm_music.volume_db = move_toward(calm_music.volume_db, calm_target, MUSIC_FADE_DB_PER_SECOND * delta)
	alien_music.volume_db = move_toward(alien_music.volume_db, alien_target, MUSIC_FADE_DB_PER_SECOND * delta)

func _exit_tree() -> void:
	for voice in voices:
		voice.stop()
		voice.stream = null
	for player in [calm_music, alien_music]:
		if is_instance_valid(player):
			player.stop()
			player.stream = null
	effects.clear()

func set_music_muted(value: bool) -> void:
	music_muted = value
	if music_muted:
		calm_music.stop()
		alien_music.stop()
	else:
		start_music()
	save_preferences()

func set_effects_muted(value: bool) -> void:
	effects_muted = value
	if effects_muted:
		for voice in voices:
			voice.stop()
	save_preferences()

func save_preferences() -> void:
	if not "--test" in OS.get_cmdline_user_args():
		var config := ConfigFile.new()
		config.set_value("audio", "music_muted", music_muted)
		config.set_value("audio", "effects_muted", effects_muted)
		config.save(SETTINGS)

func set_danger_music(enabled: bool) -> void:
	danger_music = enabled
	if music_muted:
		return
	if not calm_music.playing or not alien_music.playing:
		start_music()

func start_music() -> void:
	calm_music.volume_db = SILENT_DB if danger_music else CALM_DB
	alien_music.volume_db = ALIEN_DB if danger_music else SILENT_DB
	if not calm_music.playing:
		calm_music.play()
	if not alien_music.playing:
		alien_music.play()

func make_music_player(stream: AudioStream, volume: float) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.stream = stream
	player.volume_db = volume
	add_child(player)
	return player

func looping_copy(source: AudioStream) -> AudioStream:
	var stream: AudioStream = source.duplicate()
	if stream is AudioStreamOggVorbis:
		stream.loop = true
	elif stream is AudioStreamWAV:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_begin = 0
		stream.loop_end = stream.data.size() / 2
	return stream

func play(kind: String) -> void:
	if effects_muted or ActivityPace.multiplier < 1.0 or not effects.has(kind):
		return
	var now: int = Time.get_ticks_msec()
	if now - int(last_played.get(kind, -1000)) < 100:
		return
	last_played[kind] = now
	for voice in voices:
		if not voice.playing:
			voice.stream = effects[kind]
			voice.play()
			return

static func synthesize(kind: String) -> AudioStreamWAV:
	var parameters: Dictionary = {
		"bubble": [900.0, 220.0, 0.16], "feed": [380.0, 650.0, 0.10],
		"coin": [1000.0, 1400.0, 0.23], "buy": [440.0, 880.0, 0.28],
		"grow": [523.0, 1046.0, 0.48], "loss": [330.0, 165.0, 0.42],
		"alert": [440.0, 440.0, 0.50], "hit": [180.0, 65.0, 0.12]}
	var settings: Array = parameters[kind]
	var samples: int = int(settings[2] * 22050)
	var bytes := PackedByteArray()
	bytes.resize(samples * 2)
	var phase: float = 0.0
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(kind)
	for i in range(samples):
		var t: float = float(i) / samples
		var seconds: float = float(i) / 22050.0
		var sample: float
		if kind == "bubble":
			# A short air-pressure snap followed by a small round water resonance.
			var snap: float = rng.randf_range(-1.0, 1.0) * exp(-seconds * 55.0)
			var body: float = sin(TAU * lerpf(210.0, 105.0, t) * seconds) * exp(-seconds * 22.0)
			sample = snap * 0.62 + body * 0.48
		elif kind == "coin":
			# Two clean metallic notes make collection distinct from bubble income.
			var first: float = (sin(TAU * 880.0 * seconds) + 0.28 * sin(TAU * 1760.0 * seconds)) * exp(-seconds * 11.0)
			var second_time: float = maxf(0.0, seconds - 0.075)
			var second: float = 0.0 if seconds < 0.075 else (sin(TAU * 1320.0 * second_time) + 0.2 * sin(TAU * 2640.0 * second_time)) * exp(-second_time * 13.0)
			sample = (first * 0.48 + second * 0.40) * minf(seconds * 180.0, 1.0)
		else:
			phase += TAU * lerpf(settings[0], settings[1], t) / 22050.0
			var envelope: float = minf(t * 40.0, 1.0) * pow(1.0 - t, 2.0)
			if kind == "alert":
				envelope *= 0.5 + 0.5 * sin(t * TAU * 3.0)
			sample = (sin(phase) + 0.15 * sin(phase * 2.0)) * envelope * 0.55
		sample = clampf(sample, -1.0, 1.0)
		bytes.encode_s16(i * 2, int(sample * 32767))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = 22050
	stream.data = bytes
	return stream
