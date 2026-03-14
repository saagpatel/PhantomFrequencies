extends CharacterBody2D
## Base guard with hearing Area2D and FSM.
## Guards detect the player by sound only — no sight.

const STATE_PATROL: int = 0
const STATE_INVESTIGATE: int = 1
const STATE_ALERT: int = 2
const STATE_RETURN: int = 3

@export var hearing_range: float = Constants.GUARD_HEARING_RANGE
@export var hearing_threshold: float = Constants.GUARD_HEARING_THRESHOLD

var grid_position: Vector2i = Vector2i.ZERO
var state: int = STATE_PATROL
var _sprite: Sprite2D = null
var _hearing_shape: CollisionShape2D = null
var _tilemap: TileMapLayer = null

# Investigation / alert tracking
var _last_sound_position: Vector2 = Vector2.ZERO
var _silent_beats: int = 0  # beats since last heard sound
var _beat_counter: int = 0  # counts beats for investigate move pacing

# Patrol
var _patrol_waypoints: Array[Vector2i] = []
var _patrol_index: int = 0
var _return_waypoint_index: int = 0  # where to resume patrol after returning


func _ready() -> void:
	_tilemap = get_parent().get_node_or_null("TileMapLayer") as TileMapLayer
	_setup_sprite()
	_setup_collision()
	_setup_hearing_area()
	# If no waypoints set, derive grid position from scene placement
	if _patrol_waypoints.is_empty() and grid_position == Vector2i.ZERO:
		var ts: int = Constants.TILE_SIZE
		grid_position = Vector2i(int(position.x) / ts, int(position.y) / ts)
	_snap_to_grid()
	_apply_state_color()

	SoundPropagation.sound_emitted.connect(_on_sound_emitted)
	BeatManager.beat_tick.connect(_on_beat_tick)


func _setup_sprite() -> void:
	_sprite = $Sprite2D
	var size: int = int(Constants.GUARD_SPRITE_SIZE)
	var img: Image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	var center: Vector2 = Vector2(size / 2.0, size / 2.0)
	# Draw a diamond shape for guards
	for x: int in range(size):
		for y: int in range(size):
			var dx: float = absf(x - center.x)
			var dy: float = absf(y - center.y)
			var dist: float = dx + dy
			if dist < size / 2.0 - 2.0:
				var alpha: float = 1.0 - (dist / (size / 2.0)) * 0.4
				img.set_pixel(x, y, Color(1.0, 1.0, 1.0, alpha))
	_sprite.texture = ImageTexture.create_from_image(img)


func _setup_collision() -> void:
	var collision: CollisionShape2D = $CollisionShape2D
	var shape: CircleShape2D = CircleShape2D.new()
	shape.radius = Constants.GUARD_SPRITE_SIZE / 2.0 - 4.0
	collision.shape = shape


func _setup_hearing_area() -> void:
	var area: Area2D = $HearingArea
	_hearing_shape = area.get_node("CollisionShape2D") as CollisionShape2D
	var shape: CircleShape2D = CircleShape2D.new()
	shape.radius = hearing_range
	_hearing_shape.shape = shape


func set_patrol_waypoints(waypoints: Array[Vector2i]) -> void:
	_patrol_waypoints = waypoints
	if _patrol_waypoints.size() > 0:
		grid_position = _patrol_waypoints[0]
		_snap_to_grid()


func _on_sound_emitted(event: Dictionary) -> void:
	var sound_origin: Vector2 = event["origin"] as Vector2
	var intensity: float = event["intensity"] as float

	# Filter: below hearing threshold
	if intensity < hearing_threshold:
		return

	# Filter: outside hearing range
	var distance: float = global_position.distance_to(sound_origin)
	if distance > hearing_range:
		return

	# Filter: blocked by walls
	if not SoundPropagation.can_sound_reach(sound_origin, global_position):
		return

	# Sound detected — update FSM
	_last_sound_position = sound_origin
	_silent_beats = 0

	match state:
		STATE_PATROL:
			_transition_to(STATE_INVESTIGATE)
		STATE_INVESTIGATE:
			# Second sound while investigating → confirm threat
			_transition_to(STATE_ALERT)
		STATE_ALERT:
			pass  # already chasing
		STATE_RETURN:
			_transition_to(STATE_INVESTIGATE)


func _on_beat_tick(beat_number: int) -> void:
	_silent_beats += 1
	_beat_counter += 1

	match state:
		STATE_PATROL:
			_do_patrol()
		STATE_INVESTIGATE:
			_do_investigate()
		STATE_ALERT:
			_do_alert()
		STATE_RETURN:
			_do_return()


func _transition_to(new_state: int) -> void:
	if state == new_state:
		return

	# Save patrol position when leaving patrol
	if state == STATE_PATROL:
		_return_waypoint_index = _patrol_index

	state = new_state
	_beat_counter = 0
	_apply_state_color()


func _apply_state_color() -> void:
	if _sprite == null:
		return
	match state:
		STATE_PATROL:
			_sprite.modulate = Constants.GUARD_PATROL_COLOR
		STATE_INVESTIGATE:
			_sprite.modulate = Constants.GUARD_INVESTIGATE_COLOR
		STATE_ALERT:
			_sprite.modulate = Constants.GUARD_ALERT_COLOR
		STATE_RETURN:
			_sprite.modulate = Constants.GUARD_RETURN_COLOR


## Override in subclasses. Base does nothing.
func _do_patrol() -> void:
	pass


func _do_investigate() -> void:
	# Timeout: return after N quiet beats
	if _silent_beats >= Constants.GUARD_INVESTIGATE_TIMEOUT_BEATS:
		_transition_to(STATE_RETURN)
		return

	# Move toward last sound position every N beats
	if _beat_counter % Constants.GUARD_INVESTIGATE_BEAT_INTERVAL != 0:
		return
	_move_toward_world_position(_last_sound_position)


func _do_alert() -> void:
	# Escape: return after N quiet beats
	if _silent_beats >= Constants.GUARD_ALERT_ESCAPE_BEATS:
		_transition_to(STATE_RETURN)
		return

	# Chase: move toward last known sound position every beat
	_move_toward_world_position(_last_sound_position)


func _do_return() -> void:
	# Move back toward patrol resume point
	if _patrol_waypoints.is_empty():
		_transition_to(STATE_PATROL)
		return

	var target_tile: Vector2i = _patrol_waypoints[_return_waypoint_index]
	if grid_position == target_tile:
		_patrol_index = _return_waypoint_index
		_transition_to(STATE_PATROL)
		return

	_move_toward_tile(target_tile)


func _move_toward_world_position(target_world: Vector2) -> void:
	var ts: int = Constants.TILE_SIZE
	var target_tile: Vector2i = Vector2i(
		int(target_world.x) / ts,
		int(target_world.y) / ts
	)
	_move_toward_tile(target_tile)


func _move_toward_tile(target: Vector2i) -> void:
	if grid_position == target:
		return

	var diff: Vector2i = target - grid_position
	# Move one tile in the dominant direction
	var direction: Vector2i = Vector2i.ZERO
	if absi(diff.x) >= absi(diff.y):
		direction.x = signi(diff.x)
	else:
		direction.y = signi(diff.y)

	var next_tile: Vector2i = grid_position + direction
	if _is_wall(next_tile):
		# Try the other axis
		if direction.x != 0:
			direction = Vector2i(0, signi(diff.y)) if diff.y != 0 else Vector2i.ZERO
		else:
			direction = Vector2i(signi(diff.x), 0) if diff.x != 0 else Vector2i.ZERO
		next_tile = grid_position + direction
		if direction == Vector2i.ZERO or _is_wall(next_tile):
			return  # stuck

	grid_position = next_tile
	_animate_move()


func _is_wall(tile: Vector2i) -> bool:
	if _tilemap == null:
		return false
	var tile_data: TileData = _tilemap.get_cell_tile_data(tile)
	if tile_data == null:
		return true
	var atlas_coords: Vector2i = _tilemap.get_cell_atlas_coords(tile)
	return atlas_coords == Vector2i(1, 0)


func _tile_to_world(tile: Vector2i) -> Vector2:
	var ts: int = Constants.TILE_SIZE
	return Vector2(tile.x * ts + ts / 2, tile.y * ts + ts / 2)


func _snap_to_grid() -> void:
	position = _tile_to_world(grid_position)


func _animate_move() -> void:
	var target_pos: Vector2 = _tile_to_world(grid_position)
	var tween: Tween = create_tween()
	tween.tween_property(self, "position", target_pos, Constants.PLAYER_MOVE_DURATION) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
