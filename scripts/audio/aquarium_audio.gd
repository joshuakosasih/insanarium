class_name AquariumAudio
extends Node
## Original synthesized effects; no external recordings or backend.
const SETTINGS := "user://audio.cfg"
var muted: bool = false
var voices: Array[AudioStreamPlayer] = []
var effects: Dictionary = {}
var last_played: Dictionary = {}

func _ready() -> void:
	if not "--test" in OS.get_cmdline_user_args():
		var config := ConfigFile.new()
		if config.load(SETTINGS) == OK:
			muted = bool(config.get_value("audio", "muted", false))
	for kind in ["bubble", "feed", "coin", "buy", "grow", "loss", "alert", "hit"]:
		effects[kind] = synthesize(kind)
	for i in range(6):
		var voice := AudioStreamPlayer.new()
		voice.volume_db = -12.0
		add_child(voice)
		voices.append(voice)

func _exit_tree() -> void:
	for voice in voices:
		voice.stop()
		voice.stream = null
	effects.clear()

func set_muted(value: bool) -> void:
	muted = value
	if muted:
		for voice in voices:
			voice.stop()
	if not "--test" in OS.get_cmdline_user_args():
		var config := ConfigFile.new()
		config.set_value("audio", "muted", muted)
		config.save(SETTINGS)

func play(kind: String) -> void:
	if muted or ActivityPace.multiplier < 1.0 or not effects.has(kind):
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
	for i in range(samples):
		var t: float = float(i) / samples
		phase += TAU * lerpf(settings[0], settings[1], t) / 22050.0
		var envelope: float = minf(t * 40.0, 1.0) * pow(1.0 - t, 2.0)
		if kind == "alert":
			envelope *= 0.5 + 0.5 * sin(t * TAU * 3.0)
		var sample: float = (sin(phase) + 0.15 * sin(phase * 2.0)) * envelope * 0.55
		bytes.encode_s16(i * 2, int(sample * 32767))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = 22050
	stream.data = bytes
	return stream
