class_name BeatIndicator
extends Control
## Visual beat indicator — expanding ring that pulses on each beat.

const RING_EXPAND_DURATION: float = 0.3
const RING_MAX_SCALE: float = 2.0
const ON_BEAT_COLOR: Color = Color(0.2, 0.9, 0.3, 0.9)   # green
const OFF_BEAT_COLOR: Color = Color(0.15, 0.15, 0.2, 0.6)  # dim dark
const BASE_RING_RADIUS: float = 20.0
const RING_WIDTH: float = 3.0

var _ring_scale: float = 0.0
var _ring_alpha: float = 0.0
var _is_pulsing: bool = false
var _current_color: Color = OFF_BEAT_COLOR


@onready var _beat_manager: Node = get_node("/root/BeatManager")


func _ready() -> void:
	_beat_manager.beat_tick.connect(_on_beat_tick)


func _process(_delta: float) -> void:
	if _beat_manager.is_on_beat():
		_current_color = ON_BEAT_COLOR
	else:
		_current_color = OFF_BEAT_COLOR
	queue_redraw()


func _on_beat_tick(_beat_number: int) -> void:
	_is_pulsing = true
	_ring_scale = 1.0
	_ring_alpha = 1.0

	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "_ring_scale", RING_MAX_SCALE, RING_EXPAND_DURATION) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(self, "_ring_alpha", 0.0, RING_EXPAND_DURATION) \
		.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	tween.chain().tween_callback(_on_pulse_finished)


func _on_pulse_finished() -> void:
	_is_pulsing = false


func _draw() -> void:
	# Draw steady center dot
	draw_circle(Vector2.ZERO, 6.0, _current_color)

	# Draw expanding ring on beat
	if _is_pulsing and _ring_alpha > 0.01:
		var radius: float = BASE_RING_RADIUS * _ring_scale
		var color: Color = ON_BEAT_COLOR
		color.a = _ring_alpha
		draw_arc(Vector2.ZERO, radius, 0.0, TAU, 64, color, RING_WIDTH, true)
