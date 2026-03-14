extends Node
## Singleton — persists unlocked levels and best times to ConfigFile.

const SAVE_PATH: String = "user://phantom_frequencies.cfg"
const SECTION: String = "progress"

var unlocked_levels: int = 1  # number of levels unlocked (1-indexed)
var best_times: Dictionary = {}  # level_index (int) → best_time (float seconds)
var _level_start_time: float = 0.0


func _ready() -> void:
	load_state()


## Mark a level as started (for timing).
func start_level_timer() -> void:
	_level_start_time = Time.get_ticks_msec() / 1000.0


## Get elapsed time since level start.
func get_level_time() -> float:
	return Time.get_ticks_msec() / 1000.0 - _level_start_time


## Called when a level is completed. Updates unlock and best time.
func on_level_completed(level_index: int) -> void:
	var elapsed: float = get_level_time()

	# Unlock next level
	var next_unlock: int = level_index + 2  # level_index is 0-based, unlocked is 1-based count
	if next_unlock > unlocked_levels:
		unlocked_levels = next_unlock

	# Track best time
	var key: String = str(level_index)
	if not best_times.has(key) or elapsed < (best_times[key] as float):
		best_times[key] = elapsed

	save_state()


## Get best time for a level, or -1.0 if not completed.
func get_best_time(level_index: int) -> float:
	var key: String = str(level_index)
	if best_times.has(key):
		return best_times[key] as float
	return -1.0


## Save state to disk.
func save_state() -> void:
	var config: ConfigFile = ConfigFile.new()
	config.set_value(SECTION, "unlocked_levels", unlocked_levels)
	for key: String in best_times:
		config.set_value(SECTION, "best_time_%s" % key, best_times[key])
	config.save(SAVE_PATH)


## Load state from disk.
func load_state() -> void:
	var config: ConfigFile = ConfigFile.new()
	var err: Error = config.load(SAVE_PATH)
	if err != OK:
		return  # no save file yet
	unlocked_levels = config.get_value(SECTION, "unlocked_levels", 1) as int
	# Load best times
	for key: String in config.get_section_keys(SECTION):
		if key.begins_with("best_time_"):
			var level_key: String = key.substr(10)  # strip "best_time_"
			best_times[level_key] = config.get_value(SECTION, key, -1.0)
