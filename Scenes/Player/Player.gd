extends CharacterBody2D
## Player character — ghost infiltrating the signal tower.
## Grid-based movement that checks beat timing.
## On-beat = silent. Off-beat = emits sound.

const SPRITE_SIZE: float = 48.0
const FLASH_DURATION: float = 0.15

var grid_position: Vector2i = Vector2i(2, 2)
var _is_moving: bool = false
var _tilemap: TileMapLayer = null
var _sprite: Sprite2D = null


func _ready() -> void:
	# Find the tilemap in the parent level
	_tilemap = get_parent().get_node_or_null("TileMapLayer") as TileMapLayer
	_sprite = $Sprite2D
	add_to_group("player")
	_setup_sprite()
	_setup_collision()
	# Derive grid position from scene placement
	var ts: int = Constants.TILE_SIZE
	grid_position = Vector2i(int(position.x) / ts, int(position.y) / ts)
	_snap_to_grid()


func _setup_sprite() -> void:
	# Generate a ghostly diamond/circle placeholder sprite
	var size: int = int(SPRITE_SIZE)
	var img: Image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	var center: Vector2 = Vector2(size / 2.0, size / 2.0)
	var radius: float = size / 2.0 - 2.0
	for x: int in range(size):
		for y: int in range(size):
			var dist: float = Vector2(x, y).distance_to(center)
			if dist < radius:
				var alpha: float = 1.0 - (dist / radius) * 0.5
				img.set_pixel(x, y, Color(1.0, 1.0, 1.0, alpha))
	_sprite.texture = ImageTexture.create_from_image(img)


func _setup_collision() -> void:
	var collision: CollisionShape2D = $CollisionShape2D
	var shape: CircleShape2D = CircleShape2D.new()
	shape.radius = SPRITE_SIZE / 2.0 - 4.0
	collision.shape = shape


func _unhandled_input(event: InputEvent) -> void:
	if _is_moving:
		return

	var direction: Vector2i = Vector2i.ZERO

	if event.is_action_pressed("ui_right") or event.is_action_pressed("move_right"):
		direction = Vector2i(1, 0)
	elif event.is_action_pressed("ui_left") or event.is_action_pressed("move_left"):
		direction = Vector2i(-1, 0)
	elif event.is_action_pressed("ui_up") or event.is_action_pressed("move_up"):
		direction = Vector2i(0, -1)
	elif event.is_action_pressed("ui_down") or event.is_action_pressed("move_down"):
		direction = Vector2i(0, 1)

	if direction != Vector2i.ZERO:
		_try_move(direction)


func _try_move(direction: Vector2i) -> void:
	var target_tile: Vector2i = grid_position + direction

	# Check for wall collision via tilemap
	if _is_wall(target_tile):
		return

	# Check beat timing
	var on_beat: bool = BeatManager.is_on_beat()

	if on_beat:
		_flash_color(Constants.PLAYER_ON_BEAT_COLOR)
	else:
		# Off-beat movement emits sound
		var world_pos: Vector2 = _tile_to_world(target_tile)
		var is_masked: bool = SoundPropagation.is_masked_by_environment(world_pos)
		if is_masked:
			_flash_color(Constants.PLAYER_MASKED_COLOR)
		else:
			_flash_color(Constants.PLAYER_OFF_BEAT_COLOR)
		SoundPropagation.emit_sound(
			world_pos,
			Constants.PLAYER_SOUND_RADIUS,
			Constants.PLAYER_SOUND_INTENSITY,
			self
		)

	# Execute the move
	grid_position = target_tile
	_animate_move()


func _is_wall(tile: Vector2i) -> bool:
	if _tilemap == null:
		return false
	var atlas_coords: Vector2i = _tilemap.get_cell_atlas_coords(tile)
	# Wall tile is at atlas (1, 0). No tile data means void/blocked.
	var tile_data: TileData = _tilemap.get_cell_tile_data(tile)
	if tile_data == null:
		return true
	return atlas_coords == Vector2i(1, 0)


func _tile_to_world(tile: Vector2i) -> Vector2:
	var ts: int = Constants.TILE_SIZE
	return Vector2(tile.x * ts + ts / 2, tile.y * ts + ts / 2)


func _snap_to_grid() -> void:
	position = _tile_to_world(grid_position)


func _animate_move() -> void:
	_is_moving = true
	var target_pos: Vector2 = _tile_to_world(grid_position)
	var tween: Tween = create_tween()
	tween.tween_property(self, "position", target_pos, Constants.PLAYER_MOVE_DURATION) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_callback(_on_move_finished)


func _on_move_finished() -> void:
	_is_moving = false


func _flash_color(color: Color) -> void:
	if _sprite == null:
		return
	_sprite.modulate = color
	var tween: Tween = create_tween()
	tween.tween_property(_sprite, "modulate", Constants.PLAYER_COLOR, FLASH_DURATION)
