extends Node2D
## Level 02 — Intermediate: use the recorder to distract the Sentinel.
## 16x16 room with internal walls, 2 Patrollers, 1 Sentinel, 1 Recorder pickup.

const ROOM_WIDTH: int = 16
const ROOM_HEIGHT: int = 16

const FLOOR_COLOR: Color = Color(0.09, 0.09, 0.13)
const WALL_COLOR: Color = Color(0.28, 0.28, 0.33)
const GRID_LINE_COLOR: Color = Color(0.06, 0.06, 0.09)
const EXIT_COLOR: Color = Color(0.15, 0.35, 0.15)

var _floor_atlas: Vector2i = Vector2i(0, 0)
var _wall_atlas: Vector2i = Vector2i(1, 0)
var _exit_atlas: Vector2i = Vector2i(2, 0)

var _exit_tile: Vector2i = Vector2i(14, 1)

# Internal wall layout: vertical wall from (9, 3) to (9, 12) with a gap at (9, 8)
var _internal_walls: Array[Vector2i] = [
	Vector2i(9, 3), Vector2i(9, 4), Vector2i(9, 5), Vector2i(9, 6),
	Vector2i(9, 7),
	# gap at (9, 8) — the corridor the Sentinel guards
	Vector2i(9, 9), Vector2i(9, 10), Vector2i(9, 11), Vector2i(9, 12),
]


func _ready() -> void:
	var tilemap: TileMapLayer = $TileMapLayer
	_setup_tileset(tilemap)
	_generate_room(tilemap)
	_setup_exit()
	_setup_guards()

	SoundPropagation.set_tilemap(tilemap)
	SoundPropagation.init_wave_pool(self)
	GameState.start_level_timer()


func _setup_tileset(tilemap: TileMapLayer) -> void:
	var tile_size: int = Constants.TILE_SIZE
	var img: Image = Image.create(tile_size * 3, tile_size, false, Image.FORMAT_RGBA8)

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

	var texture: ImageTexture = ImageTexture.create_from_image(img)
	var tileset: TileSet = TileSet.new()
	tileset.tile_size = Vector2i(tile_size, tile_size)

	var source: TileSetAtlasSource = TileSetAtlasSource.new()
	source.texture = texture
	source.texture_region_size = Vector2i(tile_size, tile_size)
	source.create_tile(_floor_atlas)
	source.create_tile(_wall_atlas)
	source.create_tile(_exit_atlas)

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
			elif is_perimeter or is_internal:
				tilemap.set_cell(coords, 0, _wall_atlas)
			else:
				tilemap.set_cell(coords, 0, _floor_atlas)


func _setup_exit() -> void:
	var exit_area: Area2D = $ExitArea
	var ts: int = Constants.TILE_SIZE
	exit_area.position = Vector2(
		_exit_tile.x * ts + ts / 2,
		_exit_tile.y * ts + ts / 2
	)
	var collision: CollisionShape2D = exit_area.get_node("CollisionShape2D")
	var shape: RectangleShape2D = RectangleShape2D.new()
	shape.size = Vector2(ts / 2, ts / 2)
	collision.shape = shape
	exit_area.body_entered.connect(_on_exit_body_entered)


func _setup_guards() -> void:
	# Patroller 1: horizontal patrol in the left half, rows 4-5
	var p1: Node = $Patroller1
	var wp1: Array[Vector2i] = [
		Vector2i(2, 4), Vector2i(3, 4), Vector2i(4, 4), Vector2i(5, 4),
		Vector2i(6, 4), Vector2i(7, 4), Vector2i(7, 4), Vector2i(6, 4),
		Vector2i(5, 4), Vector2i(4, 4), Vector2i(3, 4), Vector2i(2, 4),
	]
	p1.set_patrol_waypoints(wp1)

	# Patroller 2: horizontal patrol in the left half, rows 11-12
	var p2: Node = $Patroller2
	var wp2: Array[Vector2i] = [
		Vector2i(2, 12), Vector2i(3, 12), Vector2i(4, 12), Vector2i(5, 12),
		Vector2i(6, 12), Vector2i(7, 12), Vector2i(7, 12), Vector2i(6, 12),
		Vector2i(5, 12), Vector2i(4, 12), Vector2i(3, 12), Vector2i(2, 12),
	]
	p2.set_patrol_waypoints(wp2)

	# Sentinel: guards the gap in the wall at (9, 8)
	# Position set in scene at (10, 8) — just past the gap


func _on_exit_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		LevelManager.on_level_completed()
