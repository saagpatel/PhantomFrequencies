extends Node
## Singleton beat clock. Drives the rhythm system with sub-millisecond precision.

signal beat_tick(beat_number: int)

var bpm: int = Constants.DEFAULT_BPM:
	set(value):
		bpm = clampi(value, Constants.MIN_BPM, Constants.MAX_BPM)
		beat_interval = 60.0 / float(bpm)

var beat_count: int = 0
var beat_interval: float = 0.6  # seconds per beat, recomputed from bpm
var beat_phase: float = 0.0     # 0.0-1.0, progress through current beat

var _time_since_last_beat: float = 0.0
var _last_beat_time_ms: int = 0


func _ready() -> void:
	beat_interval = 60.0 / float(bpm)
	_last_beat_time_ms = Time.get_ticks_msec()


func _process(delta: float) -> void:
	_time_since_last_beat += delta
	beat_phase = clampf(_time_since_last_beat / beat_interval, 0.0, 1.0)

	if _time_since_last_beat >= beat_interval:
		_time_since_last_beat -= beat_interval
		beat_count += 1
		_last_beat_time_ms = Time.get_ticks_msec()
		beat_tick.emit(beat_count)


## Returns true if the current moment is within tolerance of a beat boundary.
func is_on_beat(tolerance_ms: float = Constants.BEAT_TOLERANCE_MS) -> bool:
	var now_ms: int = Time.get_ticks_msec()
	var ms_since_beat: int = now_ms - _last_beat_time_ms
	var beat_interval_ms: int = int(beat_interval * 1000.0)
	var ms_until_next: int = beat_interval_ms - ms_since_beat

	return ms_since_beat <= int(tolerance_ms) or ms_until_next <= int(tolerance_ms)
