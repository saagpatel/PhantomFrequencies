extends Node
## Singleton — manages all audio: procedural SFX, ambient drone, beat click.
## All sounds are generated procedurally — no audio files needed.

var _sfx_player: AudioStreamPlayer = null
var _music_player: AudioStreamPlayer = null
var _ambient_player: AudioStreamPlayer = null

# Pregenerated audio samples
var _footstep_sample: AudioStreamWAV = null
var _alert_sting_sample: AudioStreamWAV = null
var _level_complete_sample: AudioStreamWAV = null
var _recorder_activate_sample: AudioStreamWAV = null
var _recorder_playback_sample: AudioStreamWAV = null
var _beat_click_sample: AudioStreamWAV = null


func _ready() -> void:
	_setup_players()
	_generate_samples()
	_start_ambient()
	BeatManager.beat_tick.connect(_on_beat_tick)


func _setup_players() -> void:
	_sfx_player = AudioStreamPlayer.new()
	_sfx_player.bus = Constants.SFX_BUS
	add_child(_sfx_player)

	_music_player = AudioStreamPlayer.new()
	_music_player.bus = Constants.MUSIC_BUS
	add_child(_music_player)

	_ambient_player = AudioStreamPlayer.new()
	_ambient_player.bus = Constants.AMBIENT_BUS
	_ambient_player.volume_db = -12.0
	add_child(_ambient_player)


func _generate_samples() -> void:
	_footstep_sample = _make_noise_burst(0.06, 800.0, 0.3)
	_alert_sting_sample = _make_tone_sweep(0.25, 600.0, 1200.0, 0.5)
	_level_complete_sample = _make_chime(0.6, 880.0, 0.4)
	_recorder_activate_sample = _make_tone_sweep(0.15, 400.0, 800.0, 0.3)
	_recorder_playback_sample = _make_tone_sweep(0.2, 800.0, 400.0, 0.3)
	_beat_click_sample = _make_noise_burst(0.03, 2000.0, 0.15)


func _start_ambient() -> void:
	# Generate a low ambient drone loop
	var sample_rate: int = 22050
	var duration: float = 2.0
	var num_samples: int = int(sample_rate * duration)
	var data: PackedByteArray = PackedByteArray()
	data.resize(num_samples * 2)  # 16-bit mono

	for i: int in range(num_samples):
		var t: float = float(i) / float(sample_rate)
		# Low drone: mix of sine waves at sub-bass frequencies
		var sample: float = (
			sin(t * TAU * 55.0) * 0.3 +
			sin(t * TAU * 82.5) * 0.2 +
			sin(t * TAU * 110.0) * 0.1
		)
		# Fade edges for seamless loop
		var fade: float = 1.0
		var fade_len: float = 0.1
		if t < fade_len:
			fade = t / fade_len
		elif t > duration - fade_len:
			fade = (duration - t) / fade_len
		sample *= fade * 0.4

		var int_sample: int = clampi(int(sample * 32767.0), -32768, 32767)
		data[i * 2] = int_sample & 0xFF
		data[i * 2 + 1] = (int_sample >> 8) & 0xFF

	var stream: AudioStreamWAV = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.data = data
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_end = num_samples

	_ambient_player.stream = stream
	_ambient_player.play()


func play_footstep() -> void:
	_play_sfx(_footstep_sample)


func play_alert_sting() -> void:
	_play_sfx(_alert_sting_sample)


func play_level_complete() -> void:
	_play_sfx(_level_complete_sample)


func play_recorder_activate() -> void:
	_play_sfx(_recorder_activate_sample)


func play_recorder_playback() -> void:
	_play_sfx(_recorder_playback_sample)


func stop_ambient() -> void:
	_ambient_player.stop()


func start_ambient() -> void:
	if not _ambient_player.playing:
		_ambient_player.play()


func _on_beat_tick(_beat_number: int) -> void:
	# Subtle click on each beat
	var click_player: AudioStreamPlayer = AudioStreamPlayer.new()
	click_player.bus = Constants.SFX_BUS
	click_player.volume_db = -18.0
	click_player.stream = _beat_click_sample
	add_child(click_player)
	click_player.play()
	click_player.finished.connect(click_player.queue_free)


func _play_sfx(sample: AudioStreamWAV) -> void:
	# Use a one-shot player to allow overlapping SFX
	var player: AudioStreamPlayer = AudioStreamPlayer.new()
	player.bus = Constants.SFX_BUS
	player.stream = sample
	add_child(player)
	player.play()
	player.finished.connect(player.queue_free)


## Generate a short noise burst (for footsteps, clicks).
func _make_noise_burst(duration: float, filter_freq: float, volume: float) -> AudioStreamWAV:
	var sample_rate: int = 22050
	var num_samples: int = int(sample_rate * duration)
	var data: PackedByteArray = PackedByteArray()
	data.resize(num_samples * 2)

	var prev: float = 0.0
	var rc: float = 1.0 / (TAU * filter_freq)
	var dt: float = 1.0 / float(sample_rate)
	var alpha: float = dt / (rc + dt)

	for i: int in range(num_samples):
		var t: float = float(i) / float(num_samples)
		var noise: float = randf_range(-1.0, 1.0)
		# Simple low-pass filter
		prev = prev + alpha * (noise - prev)
		# Envelope: quick attack, exponential decay
		var envelope: float = exp(-t * 20.0) * volume
		var sample: float = prev * envelope

		var int_sample: int = clampi(int(sample * 32767.0), -32768, 32767)
		data[i * 2] = int_sample & 0xFF
		data[i * 2 + 1] = (int_sample >> 8) & 0xFF

	var stream: AudioStreamWAV = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.data = data
	return stream


## Generate a frequency sweep tone (for alerts, recorder).
func _make_tone_sweep(duration: float, freq_start: float, freq_end: float, volume: float) -> AudioStreamWAV:
	var sample_rate: int = 22050
	var num_samples: int = int(sample_rate * duration)
	var data: PackedByteArray = PackedByteArray()
	data.resize(num_samples * 2)

	var phase: float = 0.0
	for i: int in range(num_samples):
		var t: float = float(i) / float(num_samples)
		var freq: float = lerpf(freq_start, freq_end, t)
		phase += freq / float(sample_rate)
		var envelope: float = (1.0 - t) * volume  # linear fade out
		var sample: float = sin(phase * TAU) * envelope

		var int_sample: int = clampi(int(sample * 32767.0), -32768, 32767)
		data[i * 2] = int_sample & 0xFF
		data[i * 2 + 1] = (int_sample >> 8) & 0xFF

	var stream: AudioStreamWAV = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.data = data
	return stream


## Generate a pleasant chime (for level complete).
func _make_chime(duration: float, freq: float, volume: float) -> AudioStreamWAV:
	var sample_rate: int = 22050
	var num_samples: int = int(sample_rate * duration)
	var data: PackedByteArray = PackedByteArray()
	data.resize(num_samples * 2)

	for i: int in range(num_samples):
		var t: float = float(i) / float(sample_rate)
		var progress: float = float(i) / float(num_samples)
		# Major chord: root + major third + fifth
		var sample: float = (
			sin(t * TAU * freq) * 0.4 +
			sin(t * TAU * freq * 1.25) * 0.3 +
			sin(t * TAU * freq * 1.5) * 0.3
		)
		# Bell-like envelope
		var envelope: float = exp(-progress * 4.0) * volume
		sample *= envelope

		var int_sample: int = clampi(int(sample * 32767.0), -32768, 32767)
		data[i * 2] = int_sample & 0xFF
		data[i * 2 + 1] = (int_sample >> 8) & 0xFF

	var stream: AudioStreamWAV = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.data = data
	return stream
