extends Sprite2D
## Pooled sound wave VFX — expanding ring driven by SoundRipple shader.
## Managed by SoundPropagation system, not instantiated directly.

const BASE_TEXTURE_SIZE: int = 128

var _is_active: bool = false
var _duration: float = 0.5


func _ready() -> void:
	# Generate a white square texture for the shader to draw on
	if texture == null:
		var img: Image = Image.create(BASE_TEXTURE_SIZE, BASE_TEXTURE_SIZE, false, Image.FORMAT_RGBA8)
		img.fill(Color.WHITE)
		texture = ImageTexture.create_from_image(img)
	# Each instance needs its own material so shader params don't clash
	material = (material as ShaderMaterial).duplicate()


func activate(origin: Vector2, radius: float, intensity: float) -> void:
	_is_active = true
	visible = true
	global_position = origin

	# Scale the sprite so it covers the full radius when progress=1.0
	# The shader draws at 0.5 UV radius, so sprite needs to be 2x the sound radius
	var target_size: float = radius * 2.0
	scale = Vector2(target_size / 128.0, target_size / 128.0)

	# Set color based on intensity: low=blue, high=red
	var ring_color: Color = _intensity_to_color(intensity)
	(material as ShaderMaterial).set_shader_parameter("progress", 0.0)
	(material as ShaderMaterial).set_shader_parameter("ring_color", ring_color)

	# Animate progress 0→1
	_duration = Constants.SOUND_EVENT_TTL
	var tween: Tween = create_tween()
	tween.tween_method(_set_progress, 0.0, 1.0, _duration) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tween.tween_callback(deactivate)


func deactivate() -> void:
	_is_active = false
	visible = false


func is_active() -> bool:
	return _is_active


func _set_progress(value: float) -> void:
	(material as ShaderMaterial).set_shader_parameter("progress", value)


func _intensity_to_color(intensity: float) -> Color:
	# Lerp from blue (low) to red (high)
	var low: Color = Color(0.2, 0.4, 0.9, 0.8)
	var high: Color = Color(0.9, 0.2, 0.1, 0.8)
	return low.lerp(high, clampf(intensity, 0.0, 1.0))
