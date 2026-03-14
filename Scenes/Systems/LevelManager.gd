extends Node
## Singleton — manages level loading, transitions, and restart.

signal level_completed(level_index: int)
signal player_caught()

var current_level: int = 0
var _transitioning: bool = false


func _ready() -> void:
	pass


## Load a level by index.
func load_level(index: int) -> void:
	if _transitioning:
		return
	if index < 0 or index >= Constants.LEVEL_SCENES.size():
		push_warning("LevelManager: invalid level index %d" % index)
		return

	_transitioning = true
	current_level = index
	_cleanup_sound_system()

	get_tree().change_scene_to_file(Constants.LEVEL_SCENES[index])
	# Transitioning flag cleared next frame after scene loads
	await get_tree().process_frame
	_transitioning = false


## Restart the current level.
func restart_level() -> void:
	load_level(current_level)


## Advance to the next level, or reload current if no more levels.
func next_level() -> void:
	var next: int = current_level + 1
	if next >= Constants.LEVEL_SCENES.size():
		# No more levels — restart current for now
		restart_level()
	else:
		load_level(next)


## Called when player reaches the exit.
func on_level_completed() -> void:
	level_completed.emit(current_level)
	next_level()


## Called when a guard catches the player.
func on_player_caught() -> void:
	player_caught.emit()
	restart_level()


## Clean up SoundPropagation state between levels.
func _cleanup_sound_system() -> void:
	SoundPropagation.clear()
