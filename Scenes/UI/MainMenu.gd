extends Control
## Main Menu — Title, Start Game, Level Select, Quit.
## Dark background with glowing text aesthetic.

var _title_label: Label = null
var _button_container: VBoxContainer = null
var _level_select_container: VBoxContainer = null
var _showing_level_select: bool = false


func _ready() -> void:
	_build_ui()
	AudioManager.start_ambient()


func _build_ui() -> void:
	# Dark background
	var bg: ColorRect = ColorRect.new()
	bg.color = Color(0.04, 0.04, 0.07)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	# Center container
	var center: CenterContainer = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 20)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_child(vbox)

	# Title
	_title_label = Label.new()
	_title_label.text = "PHANTOM FREQUENCIES"
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.add_theme_font_size_override("font_size", 48)
	_title_label.add_theme_color_override("font_color", Color(0.6, 0.8, 1.0))
	vbox.add_child(_title_label)

	# Subtitle
	var subtitle: Label = Label.new()
	subtitle.text = "A rhythm-based stealth game"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 16)
	subtitle.add_theme_color_override("font_color", Color(0.4, 0.5, 0.6))
	vbox.add_child(subtitle)

	# Spacer
	var spacer: Control = Control.new()
	spacer.custom_minimum_size = Vector2(0, 40)
	vbox.add_child(spacer)

	# Button container
	_button_container = VBoxContainer.new()
	_button_container.add_theme_constant_override("separation", 12)
	_button_container.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(_button_container)

	_add_menu_button("Start Game", _on_start_pressed)
	_add_menu_button("Level Select", _on_level_select_pressed)
	_add_menu_button("Quit", _on_quit_pressed)

	# Level select container (hidden initially)
	_level_select_container = VBoxContainer.new()
	_level_select_container.add_theme_constant_override("separation", 8)
	_level_select_container.alignment = BoxContainer.ALIGNMENT_CENTER
	_level_select_container.visible = false
	vbox.add_child(_level_select_container)


func _add_menu_button(text: String, callback: Callable) -> Button:
	var btn: Button = Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(250, 45)
	btn.add_theme_font_size_override("font_size", 20)
	btn.add_theme_color_override("font_color", Color(0.7, 0.8, 0.9))
	btn.add_theme_color_override("font_hover_color", Color(0.9, 0.95, 1.0))
	# Style: flat dark button
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.12, 0.18)
	style.border_color = Color(0.3, 0.4, 0.6, 0.5)
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	style.set_content_margin_all(10)
	btn.add_theme_stylebox_override("normal", style)
	var hover_style: StyleBoxFlat = style.duplicate()
	hover_style.bg_color = Color(0.15, 0.18, 0.25)
	hover_style.border_color = Color(0.5, 0.6, 0.8, 0.8)
	btn.add_theme_stylebox_override("hover", hover_style)
	var pressed_style: StyleBoxFlat = style.duplicate()
	pressed_style.bg_color = Color(0.2, 0.25, 0.35)
	btn.add_theme_stylebox_override("pressed", pressed_style)
	btn.pressed.connect(callback)
	_button_container.add_child(btn)
	return btn


func _on_start_pressed() -> void:
	LevelManager.load_level(0)


func _on_level_select_pressed() -> void:
	_showing_level_select = not _showing_level_select
	if _showing_level_select:
		_build_level_select()
	_level_select_container.visible = _showing_level_select


func _build_level_select() -> void:
	# Clear previous
	for child: Node in _level_select_container.get_children():
		child.queue_free()

	for i: int in range(Constants.LEVEL_SCENES.size()):
		var level_name: String = Constants.LEVEL_NAMES[i] if i < Constants.LEVEL_NAMES.size() else "Level %d" % (i + 1)
		var unlocked: bool = i < GameState.unlocked_levels
		var best: float = GameState.get_best_time(i)

		var text: String = level_name
		if best > 0.0:
			text += "  [%s]" % LevelManager._format_time(best)
		elif not unlocked:
			text += "  [locked]"

		var btn: Button = Button.new()
		btn.text = text
		btn.custom_minimum_size = Vector2(250, 38)
		btn.add_theme_font_size_override("font_size", 16)
		btn.disabled = not unlocked

		var style: StyleBoxFlat = StyleBoxFlat.new()
		style.set_corner_radius_all(3)
		style.set_content_margin_all(8)
		if unlocked:
			style.bg_color = Color(0.08, 0.1, 0.15)
			style.border_color = Color(0.2, 0.4, 0.3, 0.6)
			btn.add_theme_color_override("font_color", Color(0.6, 0.8, 0.7))
		else:
			style.bg_color = Color(0.06, 0.06, 0.08)
			style.border_color = Color(0.15, 0.15, 0.2, 0.4)
			btn.add_theme_color_override("font_color", Color(0.3, 0.3, 0.35))
		style.set_border_width_all(1)
		btn.add_theme_stylebox_override("normal", style)
		btn.add_theme_stylebox_override("disabled", style)

		if unlocked:
			var level_index: int = i
			btn.pressed.connect(func() -> void: LevelManager.load_level(level_index))

		_level_select_container.add_child(btn)

	# Back button
	var back: Button = Button.new()
	back.text = "Back"
	back.custom_minimum_size = Vector2(250, 35)
	back.add_theme_font_size_override("font_size", 14)
	back.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
	back.pressed.connect(func() -> void:
		_showing_level_select = false
		_level_select_container.visible = false
	)
	_level_select_container.add_child(back)


func _on_quit_pressed() -> void:
	get_tree().quit()


func _process(_delta: float) -> void:
	# Title glow animation
	if _title_label != null:
		var pulse: float = (sin(Time.get_ticks_msec() / 1500.0) + 1.0) / 2.0
		var color: Color = Color(0.5 + pulse * 0.2, 0.7 + pulse * 0.15, 0.9 + pulse * 0.1)
		_title_label.add_theme_color_override("font_color", color)
