extends Node2D
## Environmental noise emitter. Emits sound at configurable intervals.
## Guards learn to ignore familiar environmental sources.

const TYPE_MACHINERY: int = 0  # loud, rhythmic (every N beats)
const TYPE_DRIP: int = 1       # quiet, irregular (random chance per beat)
const TYPE_VENT: int = 2       # medium, constant (every beat)

@export var source_type: int = TYPE_MACHINERY
@export var emission_radius: float = Constants.SOUND_SOURCE_MACHINERY_RADIUS
@export var emission_intensity: float = Constants.SOUND_SOURCE_MACHINERY_INTENSITY
@export var emission_interval: int = Constants.SOUND_SOURCE_MACHINERY_INTERVAL

var _beat_counter: int = 0
var _sprite: Sprite2D = null


func _ready() -> void:
	add_to_group("sound_source")
	_apply_type_defaults()
	_setup_sprite()
	BeatManager.beat_tick.connect(_on_beat_tick)


func _apply_type_defaults() -> void:
	match source_type:
		TYPE_MACHINERY:
			emission_radius = Constants.SOUND_SOURCE_MACHINERY_RADIUS
			emission_intensity = Constants.SOUND_SOURCE_MACHINERY_INTENSITY
			emission_interval = Constants.SOUND_SOURCE_MACHINERY_INTERVAL
		TYPE_DRIP:
			emission_radius = Constants.SOUND_SOURCE_DRIP_RADIUS
			emission_intensity = Constants.SOUND_SOURCE_DRIP_INTENSITY
			emission_interval = 1  # checked per beat with random chance
		TYPE_VENT:
			emission_radius = Constants.SOUND_SOURCE_VENT_RADIUS
			emission_intensity = Constants.SOUND_SOURCE_VENT_INTENSITY
			emission_interval = 1  # every beat


func _setup_sprite() -> void:
	_sprite = $Sprite2D
	var size: int = int(Constants.SOUND_SOURCE_SPRITE_SIZE)
	var img: Image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	var center: Vector2 = Vector2(size / 2.0, size / 2.0)
	# Draw a small square with rounded corners feel
	for x: int in range(size):
		for y: int in range(size):
			var dx: float = absf(x - center.x)
			var dy: float = absf(y - center.y)
			var max_dist: float = size / 2.0 - 3.0
			if dx < max_dist and dy < max_dist:
				var edge_dist: float = minf(max_dist - dx, max_dist - dy)
				var alpha: float = clampf(edge_dist / 4.0, 0.3, 0.8)
				img.set_pixel(x, y, Color(1.0, 1.0, 1.0, alpha))
	_sprite.texture = ImageTexture.create_from_image(img)
	_sprite.modulate = Constants.SOUND_SOURCE_COLOR


func _on_beat_tick(_beat_number: int) -> void:
	_beat_counter += 1

	var should_emit: bool = false
	match source_type:
		TYPE_MACHINERY:
			should_emit = _beat_counter % emission_interval == 0
		TYPE_DRIP:
			should_emit = randf() < Constants.SOUND_SOURCE_DRIP_CHANCE
		TYPE_VENT:
			should_emit = true

	if should_emit:
		SoundPropagation.emit_sound(
			global_position,
			emission_radius,
			emission_intensity,
			self
		)
