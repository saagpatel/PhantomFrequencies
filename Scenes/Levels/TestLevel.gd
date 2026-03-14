extends Node2D
## Test level — simple walled room for verifying the beat system.
## Generates a 12x10 room with walls on the perimeter and floor inside.

const ROOM_WIDTH: int = 12
const ROOM_HEIGHT: int = 10

# Colors for placeholder tiles
const FLOOR_COLOR: Color = Color(0.12, 0.12, 0.16)   # dark charcoal
const WALL_COLOR: Color = Color(0.35, 0.35, 0.4)      # lighter gray
const GRID_LINE_COLOR: Color = Color(0.08, 0.08, 0.1)  # subtle grid lines

var _floor_atlas: Vector2i = Vector2i(0, 0)
var _wall_atlas: Vector2i = Vector2i(1, 0)


func _ready() -> void:
	var tilemap: TileMapLayer = $TileMapLayer
	_setup_tileset(tilemap)
	_generate_room(tilemap)


func _setup_tileset(tilemap: TileMapLayer) -> void:
	var tile_size: int = Constants.TILE_SIZE

	# Create a 2x1 tile atlas image: [floor, wall]
	var img: Image = Image.create(tile_size * 2, tile_size, false, Image.FORMAT_RGBA8)

	# Floor tile (left half)
	for x: int in range(tile_size):
		for y: int in range(tile_size):
			var color: Color = FLOOR_COLOR
			if x == 0 or y == 0:
				color = GRID_LINE_COLOR
			img.set_pixel(x, y, color)

	# Wall tile (right half)
	for x: int in range(tile_size):
		for y: int in range(tile_size):
			var color: Color = WALL_COLOR
			# Add a subtle border to walls
			if x < 2 or x >= tile_size - 2 or y < 2 or y >= tile_size - 2:
				color = color.darkened(0.3)
			img.set_pixel(tile_size + x, y, color)

	var texture: ImageTexture = ImageTexture.create_from_image(img)

	# Build the TileSet with an atlas source
	var tileset: TileSet = TileSet.new()
	tileset.tile_size = Vector2i(tile_size, tile_size)

	var source: TileSetAtlasSource = TileSetAtlasSource.new()
	source.texture = texture
	source.texture_region_size = Vector2i(tile_size, tile_size)

	# Create the two tiles
	source.create_tile(_floor_atlas)  # (0,0) = floor
	source.create_tile(_wall_atlas)   # (1,0) = wall

	tileset.add_source(source, 0)
	tilemap.tile_set = tileset


func _generate_room(tilemap: TileMapLayer) -> void:
	for x: int in range(ROOM_WIDTH):
		for y: int in range(ROOM_HEIGHT):
			var coords: Vector2i = Vector2i(x, y)
			var is_wall: bool = (
				x == 0 or x == ROOM_WIDTH - 1 or
				y == 0 or y == ROOM_HEIGHT - 1
			)
			if is_wall:
				tilemap.set_cell(coords, 0, _wall_atlas)
			else:
				tilemap.set_cell(coords, 0, _floor_atlas)
