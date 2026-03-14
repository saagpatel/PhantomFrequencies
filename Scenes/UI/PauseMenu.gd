extends CanvasLayer
## Pause Menu — Resume, Restart Level, Return to Menu.
## Triggered by Escape key. Pauses the scene tree.

var _panel: Control = null
var _is_paused: bool = false


func _ready() -> void:
	layer = 99
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	_panel.visible = false


func _build_ui() -> void:
	# Semi-transparent overlay
	var overlay: ColorRect = ColorRect.new()
	overlay.color = Color(0.0, 0.0, 0.0, 0.6)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(overlay)

	_panel = overlay

	# Center container
	var center: CenterContainer = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_child(vbox)

	# Title
	var title: Label = Label.new()
	title.text = "PAUSED"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 36)
	title.add_theme_color_override("font_color", Color(0.7, 0.8, 0.9))
	vbox.add_child(title)

	var spacer: Control = Control.new()
	spacer.custom_minimum_size = Vector2(0, 20)
	vbox.add_child(spacer)

	_add_pause_button(vbox, "Resume", _on_resume)
	_add_pause_button(vbox, "Restart Level", _on_restart)
	_add_pause_button(vbox, "Return to Menu", _on_return_to_menu)


func _add_pause_button(parent: VBoxContainer, text: String, callback: Callable) -> void:
	var btn: Button = Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(220, 42)
	btn.add_theme_font_size_override("font_size", 18)
	btn.add_theme_color_override("font_color", Color(0.7, 0.8, 0.9))

	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.12, 0.18)
	style.border_color = Color(0.3, 0.4, 0.6, 0.5)
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	style.set_content_margin_all(8)
	btn.add_theme_stylebox_override("normal", style)

	var hover_style: StyleBoxFlat = style.duplicate()
	hover_style.bg_color = Color(0.15, 0.18, 0.25)
	hover_style.border_color = Color(0.5, 0.6, 0.8, 0.8)
	btn.add_theme_stylebox_override("hover", hover_style)

	btn.pressed.connect(callback)
	parent.add_child(btn)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		_toggle_pause()
		get_viewport().set_input_as_handled()


func _toggle_pause() -> void:
	_is_paused = not _is_paused
	_panel.visible = _is_paused
	get_tree().paused = _is_paused


func _on_resume() -> void:
	_toggle_pause()


func _on_restart() -> void:
	_toggle_pause()
	LevelManager.restart_level()


func _on_return_to_menu() -> void:
	_toggle_pause()
	LevelManager.return_to_menu()
