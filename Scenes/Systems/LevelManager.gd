extends Node
## Singleton — manages level loading, transitions, fade effects, and restart.

signal level_completed(level_index: int)
signal player_caught()

var current_level: int = 0
var _transitioning: bool = false
var _overlay: CanvasLayer = null
var _fade_rect: ColorRect = null
var _label: Label = null


func _ready() -> void:
	_setup_overlay()


## Build a persistent overlay for fade-to-black and level complete text.
func _setup_overlay() -> void:
	_overlay = CanvasLayer.new()
	_overlay.layer = 100
	add_child(_overlay)

	_fade_rect = ColorRect.new()
	_fade_rect.color = Color(0.0, 0.0, 0.0, 0.0)
	_fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.add_child(_fade_rect)

	_label = Label.new()
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	_label.add_theme_font_size_override("font_size", 32)
	_label.add_theme_color_override("font_color", Color(0.8, 0.9, 1.0))
	_label.text = ""
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.add_child(_label)


## Load a level by index with fade transition.
func load_level(index: int) -> void:
	if _transitioning:
		return
	if index < 0 or index >= Constants.LEVEL_SCENES.size():
		push_warning("LevelManager: invalid level index %d" % index)
		return

	_transitioning = true
	current_level = index

	# Fade to black
	await _fade_in()

	_label.text = ""
	_cleanup_sound_system()
	get_tree().change_scene_to_file(Constants.LEVEL_SCENES[index])
	await get_tree().process_frame

	GameState.start_level_timer()

	# Fade from black
	await _fade_out()
	_transitioning = false


## Restart the current level.
func restart_level() -> void:
	load_level(current_level)


## Advance to the next level, or return to menu if done.
func next_level() -> void:
	var next: int = current_level + 1
	if next >= Constants.LEVEL_SCENES.size():
		return_to_menu()
	else:
		load_level(next)


## Called when player reaches the exit.
func on_level_completed() -> void:
	if _transitioning:
		return
	_transitioning = true

	var elapsed: float = GameState.get_level_time()
	GameState.on_level_completed(current_level)
	AudioManager.play_level_complete()
	level_completed.emit(current_level)

	# Show "Level Complete" overlay
	await _fade_in()

	var time_str: String = _format_time(elapsed)
	var level_name: String = Constants.LEVEL_NAMES[current_level] if current_level < Constants.LEVEL_NAMES.size() else "Level %d" % (current_level + 1)
	_label.text = "%s Complete!\nTime: %s" % [level_name, time_str]

	var best: float = GameState.get_best_time(current_level)
	if best > 0.0:
		_label.text += "\nBest: %s" % _format_time(best)

	# Hold for display time
	await get_tree().create_timer(Constants.LEVEL_COMPLETE_DISPLAY_TIME).timeout

	_label.text = ""
	_cleanup_sound_system()

	# Load next level or menu
	var next: int = current_level + 1
	if next >= Constants.LEVEL_SCENES.size():
		get_tree().change_scene_to_file(Constants.MAIN_MENU_SCENE)
		await get_tree().process_frame
		await _fade_out()
		_transitioning = false
	else:
		current_level = next
		get_tree().change_scene_to_file(Constants.LEVEL_SCENES[next])
		await get_tree().process_frame
		GameState.start_level_timer()
		await _fade_out()
		_transitioning = false


## Called when a guard catches the player.
func on_player_caught() -> void:
	if _transitioning:
		return
	player_caught.emit()
	restart_level()


## Return to main menu.
func return_to_menu() -> void:
	if _transitioning:
		return
	_transitioning = true
	await _fade_in()
	_cleanup_sound_system()
	get_tree().change_scene_to_file(Constants.MAIN_MENU_SCENE)
	await get_tree().process_frame
	await _fade_out()
	_transitioning = false


## Clean up SoundPropagation state between levels.
func _cleanup_sound_system() -> void:
	SoundPropagation.clear()


func _fade_in() -> void:
	var tween: Tween = create_tween()
	tween.tween_property(_fade_rect, "color:a", 1.0, Constants.FADE_DURATION)
	await tween.finished


func _fade_out() -> void:
	var tween: Tween = create_tween()
	tween.tween_property(_fade_rect, "color:a", 0.0, Constants.FADE_DURATION)
	await tween.finished


func _format_time(seconds: float) -> String:
	var mins: int = int(seconds) / 60
	var secs: int = int(seconds) % 60
	var frac: int = int((seconds - int(seconds)) * 10)
	if mins > 0:
		return "%d:%02d.%d" % [mins, secs, frac]
	return "%d.%ds" % [secs, frac]
