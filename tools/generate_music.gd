extends SceneTree
## Regenerates the two original procedural music loops used by AquariumAudio.
const RATE := 11025

func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://assets/audio"))
	assert(synthesize("calm").save_to_wav("res://assets/audio/calm_theme.wav") == OK)
	assert(synthesize("alien").save_to_wav("res://assets/audio/alien_theme.wav") == OK)
	print("Generated original aquarium music loops")
	quit()

static func synthesize(kind: String) -> AudioStreamWAV:
	var duration: float = 16.0 if kind == "calm" else 8.0
	var samples: int = int(duration * RATE)
	var bytes := PackedByteArray()
	bytes.resize(samples * 2)
	var calm_roots := [48, 45, 41, 43]
	var calm_thirds := [4, 3, 4, 4]
	var calm_melody := [72, 76, 79, 76, 74, 72, 69, 72, 69, 72, 76, 72, 69, 67, 64, 67, 65, 69, 72, 69, 67, 65, 64, 60, 67, 71, 74, 71, 69, 67, 62, 67]
	var alien_bass := [36, 36, 39, 35, 36, 43, 39, 35, 36, 36, 46, 43, 39, 35, 34, 35]
	for i in range(samples):
		var t: float = float(i) / RATE
		var sample: float
		if kind == "calm":
			var chord: int = mini(int(t / 4.0), calm_roots.size() - 1)
			var root: int = calm_roots[chord]
			var pad: float = sin(TAU * note_frequency(root) * t)
			pad += sin(TAU * note_frequency(root + calm_thirds[chord]) * t) * 0.72
			pad += sin(TAU * note_frequency(root + 7) * t) * 0.58
			var step: int = mini(int(t / 0.5), calm_melody.size() - 1)
			var local: float = fmod(t, 0.5)
			var pluck: float = sin(TAU * note_frequency(calm_melody[step]) * local) * exp(-5.5 * local)
			var shimmer: float = sin(TAU * note_frequency(root + 19) * t) * (0.5 + 0.5 * sin(TAU * t / 4.0))
			sample = pad * 0.095 + pluck * 0.105 + shimmer * 0.018
		else:
			var beat_local: float = fmod(t, 0.5)
			var bass_step: int = int(t / 0.5) % alien_bass.size()
			var bass_frequency: float = note_frequency(alien_bass[bass_step])
			var bass_envelope: float = exp(-2.7 * beat_local)
			var bass: float = (sin(TAU * bass_frequency * beat_local) + 0.28 * sin(TAU * bass_frequency * 2.0 * beat_local)) * bass_envelope
			var kick: float = sin(TAU * (82.0 - beat_local * 95.0) * beat_local) * exp(-13.0 * beat_local)
			var alarm: float = sin(TAU * note_frequency(72 + (bass_step % 2) * 3) * t) * (0.35 + 0.65 * sin(TAU * t * 2.0) ** 2)
			sample = bass * 0.18 + kick * 0.16 + alarm * 0.045
		var loop_envelope: float = minf(1.0, minf(t * 12.0, (duration - t) * 12.0))
		sample = clampf(sample * loop_envelope, -0.8, 0.8)
		bytes.encode_s16(i * 2, int(sample * 32767.0))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = RATE
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_end = samples
	stream.data = bytes
	return stream

static func note_frequency(midi_note: int) -> float:
	return 440.0 * pow(2.0, (midi_note - 69) / 12.0)
