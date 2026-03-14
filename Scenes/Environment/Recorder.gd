extends Node2D
## Recorder — captures and replays sound events as distractions.
## States: IDLE (pickup), RECORDING, READY (playback available), PLAYING, SPENT.

const STATE_IDLE: int = 0      # on ground, waiting for pickup
const STATE_RECORDING: int = 1  # capturing sounds
const STATE_READY: int = 2      # has recording, ready to play
const STATE_PLAYING: int = 3    # replaying captured sounds
const STATE_SPENT: int = 4      # used up

var state: int = STATE_IDLE
var _sprite: Sprite2D = null
var _pickup_area: Area2D = null
var _captured_events: Array[Dictionary] = []  # { radius, intensity }
var _beats_recorded: int = 0
var _playback_index: int = 0
var _playback_timer: float = 0.0


func _ready() -> void:
	_setup_sprite()
	_setup_pickup_area()
	_apply_state_visual()


func _setup_sprite() -> void:
	_sprite = $Sprite2D
	var size: int = 40  # larger for visibility
	var img: Image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	var center: Vector2 = Vector2(size / 2.0, size / 2.0)
	var radius: float = size / 2.0 - 3.0
	# Draw a filled circle with a hollow center (ring/record shape)
	for x: int in range(size):
		for y: int in range(size):
			var dist: float = Vector2(x, y).distance_to(center)
			if dist < radius and dist > radius * 0.35:
				var alpha: float = 0.9
				img.set_pixel(x, y, Color(1.0, 1.0, 1.0, alpha))
			elif dist <= radius * 0.35:
				img.set_pixel(x, y, Color(1.0, 1.0, 1.0, 0.5))
	_sprite.texture = ImageTexture.create_from_image(img)


func _setup_pickup_area() -> void:
	_pickup_area = $PickupArea
	var collision: CollisionShape2D = _pickup_area.get_node("CollisionShape2D")
	var shape: CircleShape2D = CircleShape2D.new()
	shape.radius = Constants.TILE_SIZE / 2.0
	collision.shape = shape


func _check_player_proximity() -> void:
	if state != STATE_IDLE:
		return
	var player: Node = get_tree().get_first_node_in_group("player")
	if player == null:
		return
	var dist: float = global_position.distance_to(player.global_position)
	if dist < Constants.TILE_SIZE * 0.75:
		pickup(player)


func pickup(_player: Node2D) -> void:
	state = STATE_IDLE  # will transition when player uses it
	visible = false
	_pickup_area.set_deferred("monitoring", false)
	# Register with player
	var player: Node = get_tree().get_first_node_in_group("player")
	if player != null and player.has_method("_on_recorder_pickup"):
		player._on_recorder_pickup(self)


## Called by the player when they press R to start recording.
func start_recording(record_position: Vector2) -> void:
	state = STATE_RECORDING
	global_position = record_position
	visible = true
	_captured_events.clear()
	_beats_recorded = 0
	_apply_state_visual()
	SoundPropagation.sound_emitted.connect(_on_sound_during_recording)
	BeatManager.beat_tick.connect(_on_beat_during_recording)


func _on_sound_during_recording(event: Dictionary) -> void:
	if state != STATE_RECORDING:
		return
	var sound_origin: Vector2 = event["origin"] as Vector2
	var distance: float = global_position.distance_to(sound_origin)
	if distance > Constants.RECORDER_CAPTURE_RADIUS:
		return
	# Capture the event's sound properties
	_captured_events.append({
		"radius": event["radius"] as float,
		"intensity": event["intensity"] as float,
	})


func _on_beat_during_recording(_beat_number: int) -> void:
	if state != STATE_RECORDING:
		return
	_beats_recorded += 1
	if _beats_recorded >= Constants.RECORDER_CAPTURE_BEATS:
		_finish_recording()


func _finish_recording() -> void:
	state = STATE_READY
	_apply_state_visual()
	if SoundPropagation.sound_emitted.is_connected(_on_sound_during_recording):
		SoundPropagation.sound_emitted.disconnect(_on_sound_during_recording)
	if BeatManager.beat_tick.is_connected(_on_beat_during_recording):
		BeatManager.beat_tick.disconnect(_on_beat_during_recording)


## Called by the player when they press R to trigger playback.
func start_playback() -> void:
	if state != STATE_READY:
		return
	if _captured_events.is_empty():
		# Nothing recorded — go straight to spent
		state = STATE_SPENT
		_apply_state_visual()
		return
	state = STATE_PLAYING
	_playback_index = 0
	_playback_timer = 0.0
	_apply_state_visual()


func _process(delta: float) -> void:
	_check_player_proximity()

	if state == STATE_PLAYING:
		_playback_timer += delta
		if _playback_timer >= Constants.RECORDER_PLAYBACK_INTERVAL:
			_playback_timer -= Constants.RECORDER_PLAYBACK_INTERVAL
			_play_next_event()

	# Pulse animation for ready state
	if state == STATE_READY:
		var pulse: float = (sin(Time.get_ticks_msec() / 200.0) + 1.0) / 2.0
		_sprite.modulate.a = 0.5 + pulse * 0.5

	# Glow animation for recording state
	if state == STATE_RECORDING:
		var glow: float = (sin(Time.get_ticks_msec() / 100.0) + 1.0) / 2.0
		_sprite.modulate.a = 0.6 + glow * 0.4


func _play_next_event() -> void:
	if _playback_index >= _captured_events.size():
		_finish_playback()
		return
	var event_data: Dictionary = _captured_events[_playback_index]
	SoundPropagation.emit_sound(
		global_position,
		event_data["radius"] as float,
		event_data["intensity"] as float,
		self
	)
	_playback_index += 1


func _finish_playback() -> void:
	state = STATE_SPENT
	_apply_state_visual()
	# Notify player the recorder is consumed
	var player: Node = get_tree().get_first_node_in_group("player")
	if player != null and player.has_method("_on_recorder_spent"):
		player._on_recorder_spent()


func _apply_state_visual() -> void:
	if _sprite == null:
		return
	match state:
		STATE_IDLE:
			_sprite.modulate = Constants.RECORDER_IDLE_COLOR
		STATE_RECORDING:
			_sprite.modulate = Constants.RECORDER_RECORDING_COLOR
		STATE_READY:
			_sprite.modulate = Constants.RECORDER_READY_COLOR
		STATE_PLAYING:
			_sprite.modulate = Constants.RECORDER_READY_COLOR
		STATE_SPENT:
			_sprite.modulate = Constants.RECORDER_SPENT_COLOR
