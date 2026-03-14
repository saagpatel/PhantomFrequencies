extends Node2D
## Level 03 — Full Run: multi-room layout requiring all mechanics.
## 24x20 grid, 3 Patrollers, 2 Sentinels, multiple env sources, 2 Recorders.
## Hidden bonus exit at tile (22,1) — reach it on a beat divisible by 4.

const ROOM_WIDTH: int = 24
const ROOM_HEIGHT: int = 20

const FLOOR_COLOR: Color = Color(0.08, 0.08, 0.12)
const WALL_COLOR: Color = Color(0.25, 0.25, 0.30)
const GRID_LINE_COLOR: Color = Color(0.05, 0.05, 0.08)
const EXIT_COLOR: Color = Color(0.15, 0.35, 0.15)
const BONUS_EXIT_COLOR: Color = Color(0.35, 0.15, 0.35)

var _floor_atlas: Vector2i = Vector2i(0, 0)
var _wall_atlas: Vector2i = Vector2i(1, 0)
var _exit_atlas: Vector2i = Vector2i(2, 0)
var _bonus_atlas: Vector2i = Vector2i(3, 0)

var _exit_tile: Vector2i = Vector2i(22, 18)
var _bonus_exit_tile: Vector2i = Constants.BONUS_EXIT_TILE  # (22, 1)

# Internal walls define the multi-room layout:
# Vertical wall at x=8 from y=1 to y=14 with gap at y=7
# Vertical wall at x=16 from y=5 to y=18 with gap at y=12
# Horizontal wall at y=10 from x=1 to x=8 with gap at x=4
# Horizontal wall at y=10 from x=16 to x=22 with gap at x=19
var _internal_walls: Array[Vector2i] = []


func _ready() -> void:
	_build_internal_walls()

	var tilemap: TileMapLayer = $TileMapLayer
	_setup_tileset(tilemap)
	_generate_room(tilemap)
	_setup_exits()
	_setup_guards()

	SoundPropagation.set_tilemap(tilemap)
	SoundPropagation.init_wave_pool(self)


func _build_internal_walls() -> void:
	# Vertical wall x=8, y=1..14, gap at y=7
	for y: int in range(1, 15):
		if y != 7:
			_internal_walls.append(Vector2i(8, y))

	# Vertical wall x=16, y=5..18, gap at y=12
	for y: int in range(5, 19):
		if y != 12:
			_internal_walls.append(Vector2i(16, y))

	# Horizontal wall y=10, x=1..8, gap at x=4
	for x: int in range(1, 9):
		if x != 4:
			var coord: Vector2i = Vector2i(x, 10)
			if coord not in _internal_walls:
				_internal_walls.append(coord)

	# Horizontal wall y=10, x=16..22, gap at x=19
	for x: int in range(16, 23):
		if x != 19:
			var coord: Vector2i = Vector2i(x, 10)
			if coord not in _internal_walls:
				_internal_walls.append(coord)


func _setup_tileset(tilemap: TileMapLayer) -> void:
	var tile_size: int = Constants.TILE_SIZE
	# 4 tile types: floor, wall, exit, bonus exit
	var img: Image = Image.create(tile_size * 4, tile_size, false, Image.FORMAT_RGBA8)

	# Floor
	for x: int in range(tile_size):
		for y: int in range(tile_size):
			var color: Color = FLOOR_COLOR
			if x == 0 or y == 0:
				color = GRID_LINE_COLOR
			img.set_pixel(x, y, color)

	# Wall
	for x: int in range(tile_size):
		for y: int in range(tile_size):
			var color: Color = WALL_COLOR
			if x < 2 or x >= tile_size - 2 or y < 2 or y >= tile_size - 2:
				color = color.darkened(0.3)
			img.set_pixel(tile_size + x, y, color)

	# Exit
	for x: int in range(tile_size):
		for y: int in range(tile_size):
			var color: Color = EXIT_COLOR
			if x < 3 or x >= tile_size - 3 or y < 3 or y >= tile_size - 3:
				color = color.lightened(0.4)
			img.set_pixel(tile_size * 2 + x, y, color)

	# Bonus exit (subtle purple)
	for x: int in range(tile_size):
		for y: int in range(tile_size):
			var color: Color = BONUS_EXIT_COLOR
			if x < 3 or x >= tile_size - 3 or y < 3 or y >= tile_size - 3:
				color = color.lightened(0.3)
			img.set_pixel(tile_size * 3 + x, y, color)

	var texture: ImageTexture = ImageTexture.create_from_image(img)
	var tileset: TileSet = TileSet.new()
	tileset.tile_size = Vector2i(tile_size, tile_size)

	var source: TileSetAtlasSource = TileSetAtlasSource.new()
	source.texture = texture
	source.texture_region_size = Vector2i(tile_size, tile_size)
	source.create_tile(_floor_atlas)
	source.create_tile(_wall_atlas)
	source.create_tile(_exit_atlas)
	source.create_tile(_bonus_atlas)

	tileset.add_source(source, 0)
	tilemap.tile_set = tileset


func _generate_room(tilemap: TileMapLayer) -> void:
	for x: int in range(ROOM_WIDTH):
		for y: int in range(ROOM_HEIGHT):
			var coords: Vector2i = Vector2i(x, y)
			var is_perimeter: bool = (
				x == 0 or x == ROOM_WIDTH - 1 or
				y == 0 or y == ROOM_HEIGHT - 1
			)
			var is_internal: bool = coords in _internal_walls

			if coords == _exit_tile:
				tilemap.set_cell(coords, 0, _exit_atlas)
			elif coords == _bonus_exit_tile:
				tilemap.set_cell(coords, 0, _bonus_atlas)
			elif is_perimeter or is_internal:
				tilemap.set_cell(coords, 0, _wall_atlas)
			else:
				tilemap.set_cell(coords, 0, _floor_atlas)


func _setup_exits() -> void:
	var ts: int = Constants.TILE_SIZE

	# Main exit
	var exit_area: Area2D = $ExitArea
	exit_area.position = Vector2(
		_exit_tile.x * ts + ts / 2,
		_exit_tile.y * ts + ts / 2
	)
	var collision: CollisionShape2D = exit_area.get_node("CollisionShape2D")
	var shape: RectangleShape2D = RectangleShape2D.new()
	shape.size = Vector2(ts / 2, ts / 2)
	collision.shape = shape
	exit_area.body_entered.connect(_on_exit_body_entered)

	# Bonus exit
	var bonus_area: Area2D = $BonusExitArea
	bonus_area.position = Vector2(
		_bonus_exit_tile.x * ts + ts / 2,
		_bonus_exit_tile.y * ts + ts / 2
	)
	var bonus_collision: CollisionShape2D = bonus_area.get_node("CollisionShape2D")
	var bonus_shape: RectangleShape2D = RectangleShape2D.new()
	bonus_shape.size = Vector2(ts / 2, ts / 2)
	bonus_collision.shape = bonus_shape
	bonus_area.body_entered.connect(_on_bonus_exit_body_entered)


func _setup_guards() -> void:
	# Patroller 1: left room, horizontal patrol rows 3-5
	var p1: Node = $Patroller1
	var wp1: Array[Vector2i] = [
		Vector2i(2, 4), Vector2i(3, 4), Vector2i(4, 4), Vector2i(5, 4),
		Vector2i(6, 4), Vector2i(7, 4), Vector2i(7, 4), Vector2i(6, 4),
		Vector2i(5, 4), Vector2i(4, 4), Vector2i(3, 4), Vector2i(2, 4),
	]
	p1.set_patrol_waypoints(wp1)

	# Patroller 2: left room lower, horizontal patrol rows 13-15
	var p2: Node = $Patroller2
	var wp2: Array[Vector2i] = [
		Vector2i(2, 14), Vector2i(3, 14), Vector2i(4, 14), Vector2i(5, 14),
		Vector2i(6, 14), Vector2i(7, 14), Vector2i(7, 14), Vector2i(6, 14),
		Vector2i(5, 14), Vector2i(4, 14), Vector2i(3, 14), Vector2i(2, 14),
	]
	p2.set_patrol_waypoints(wp2)

	# Patroller 3: right room, vertical patrol
	var p3: Node = $Patroller3
	var wp3: Array[Vector2i] = [
		Vector2i(20, 6), Vector2i(20, 7), Vector2i(20, 8), Vector2i(20, 9),
		Vector2i(20, 10), Vector2i(20, 11), Vector2i(20, 12), Vector2i(20, 13),
		Vector2i(20, 14), Vector2i(20, 15), Vector2i(20, 16), Vector2i(20, 17),
		Vector2i(20, 17), Vector2i(20, 16), Vector2i(20, 15), Vector2i(20, 14),
		Vector2i(20, 13), Vector2i(20, 12), Vector2i(20, 11), Vector2i(20, 10),
		Vector2i(20, 9), Vector2i(20, 8), Vector2i(20, 7), Vector2i(20, 6),
	]
	p3.set_patrol_waypoints(wp3)

	# Sentinel 1: guards the gap in wall x=8 at y=7
	# Positioned at (9, 7) — just past the gap on right side
	# (scene position set in .tscn)

	# Sentinel 2: guards the gap in wall x=16 at y=12
	# Positioned at (17, 12) — just past the gap on right side
	# (scene position set in .tscn)


func _on_exit_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		LevelManager.on_level_completed()


func _on_bonus_exit_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		# Easter egg: only works if arriving on a beat divisible by 4
		if BeatManager.is_on_beat() and BeatManager.beat_count % Constants.BONUS_EXIT_BEAT_WINDOW == 0:
			LevelManager.on_level_completed()
