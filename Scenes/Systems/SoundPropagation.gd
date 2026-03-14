extends Node
## Singleton — manages all sound events in the level.
## Sound events have a position, radius, intensity, and TTL.
## Guards and other listeners connect to the sound_emitted signal.

signal sound_emitted(event: Dictionary)

## Active sound events. Each entry:
## { origin: Vector2, radius: float, intensity: float, source: Node,
##   time_remaining: float, id: int, is_environmental: bool }
var _active_events: Array[Dictionary] = []
var _next_event_id: int = 0
var _tilemap: TileMapLayer = null
var _wall_atlas: Vector2i = Vector2i(1, 0)

# SoundWave VFX object pool
var _wave_pool: Array[Node] = []
var _wave_scene: PackedScene = preload("res://Scenes/Player/SoundWave.tscn")
var _pool_parent: Node = null


func set_tilemap(tilemap: TileMapLayer) -> void:
	_tilemap = tilemap


## Initialize the wave pool under a parent node (call from level _ready).
func init_wave_pool(parent: Node) -> void:
	_pool_parent = parent
	for i: int in range(Constants.SOUND_WAVE_POOL_SIZE):
		var wave: Node = _wave_scene.instantiate()
		parent.add_child(wave)
		_wave_pool.append(wave)


## Emit a sound event at a world position.
func emit_sound(origin: Vector2, radius: float, intensity: float, source: Node) -> void:
	var is_env: bool = source.is_in_group("sound_source")
	var event: Dictionary = {
		"origin": origin,
		"radius": radius,
		"intensity": intensity,
		"source": source,
		"time_remaining": Constants.SOUND_EVENT_TTL,
		"id": _next_event_id,
		"is_environmental": is_env,
	}
	_next_event_id += 1
	_active_events.append(event)
	sound_emitted.emit(event)
	_spawn_wave_vfx(origin, radius, intensity)


## Check if a position is within an active environmental sound's radius.
## Used for masking player sounds.
func is_masked_by_environment(position: Vector2) -> bool:
	for event: Dictionary in _active_events:
		if not event["is_environmental"]:
			continue
		var env_origin: Vector2 = event["origin"] as Vector2
		var env_radius: float = event["radius"] as float
		if position.distance_to(env_origin) <= env_radius:
			return true
	return false


## Check if a sound at origin can reach target without hitting a wall.
func can_sound_reach(origin: Vector2, target: Vector2) -> bool:
	if _tilemap == null:
		return true

	var tile_size: int = Constants.TILE_SIZE
	var from_tile: Vector2i = Vector2i(
		int(origin.x) / tile_size,
		int(origin.y) / tile_size
	)
	var to_tile: Vector2i = Vector2i(
		int(target.x) / tile_size,
		int(target.y) / tile_size
	)

	# Bresenham line between tiles — if any tile is a wall, sound is blocked
	var points: Array[Vector2i] = _bresenham_line(from_tile, to_tile)
	for point: Vector2i in points:
		var tile_data: TileData = _tilemap.get_cell_tile_data(point)
		if tile_data == null:
			# No tile = void = blocked
			return false
		var atlas_coords: Vector2i = _tilemap.get_cell_atlas_coords(point)
		if atlas_coords == _wall_atlas:
			return false
	return true


func get_active_events() -> Array[Dictionary]:
	return _active_events


## Clear all state for level transitions.
func clear() -> void:
	_active_events.clear()
	_next_event_id = 0
	_tilemap = null
	for wave: Node in _wave_pool:
		wave.deactivate()
		wave.queue_free()
	_wave_pool.clear()
	_pool_parent = null


func _process(delta: float) -> void:
	# Decay and remove expired events
	var i: int = _active_events.size() - 1
	while i >= 0:
		_active_events[i]["time_remaining"] -= delta
		if _active_events[i]["time_remaining"] <= 0.0:
			_active_events.remove_at(i)
		i -= 1


## Grab an inactive wave from the pool and activate it.
func _spawn_wave_vfx(origin: Vector2, radius: float, intensity: float) -> void:
	for wave: Node in _wave_pool:
		if not wave.is_active():
			wave.activate(origin, radius, intensity)
			return
	# Pool exhausted — skip VFX this frame


## Bresenham line algorithm returning all tile coordinates between two points.
func _bresenham_line(from: Vector2i, to: Vector2i) -> Array[Vector2i]:
	var points: Array[Vector2i] = []
	var dx: int = absi(to.x - from.x)
	var dy: int = -absi(to.y - from.y)
	var sx: int = 1 if from.x < to.x else -1
	var sy: int = 1 if from.y < to.y else -1
	var err: int = dx + dy
	var current: Vector2i = from

	while true:
		points.append(current)
		if current == to:
			break
		var e2: int = 2 * err
		if e2 >= dy:
			err += dy
			current.x += sx
		if e2 <= dx:
			err += dx
			current.y += sy
	return points
