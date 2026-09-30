extends Control

const GAME_SCENE := "res://Main.tscn"

var pixel_font: Font
var menu_panel: PanelContainer
var credits_panel: PanelContainer
var sound_settings: Control
var game_audio: Node


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pixel_font = preload("res://PixelFont.gd").make()
	_build_background()
	_build_title()
	_build_menu()
	_build_credits()
	_build_settings()
	resized.connect(_layout)
	_layout()


func _build_background() -> void:
	var background := TextureRect.new()
	background.texture = load("res://menu/menu_background.png")
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	move_child(background, 0)

	var shade := ColorRect.new()
	shade.color = Color(0.035, 0.045, 0.035, 0.28)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)


func _build_title() -> void:
	var logo := TextureRect.new()
	logo.name = "TitleLogo"
	logo.texture = load("res://menu/title_logo.png")
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(logo)

	var game_title := Label.new()
	game_title.name = "GameTitle"
	game_title.text = "BAN KERD: TAI NGAO WINYAN"
	game_title.add_theme_font_override("font", pixel_font)
	game_title.add_theme_font_size_override("font_size", 18)
	game_title.add_theme_color_override("font_color", Color("fff1c5"))
	game_title.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	game_title.add_theme_constant_override("shadow_offset_y", 2)
	game_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(game_title)

	var subtitle := Label.new()
	subtitle.name = "Subtitle"
	subtitle.text = "A FOLK-HORROR ACTION ADVENTURE"
	subtitle.add_theme_font_override("font", pixel_font)
	subtitle.add_theme_font_size_override("font_size", 12)
	subtitle.add_theme_color_override("font_color", Color("e2ddc9"))
	subtitle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(subtitle)


func _build_menu() -> void:
	menu_panel = PanelContainer.new()
	menu_panel.name = "MenuPanel"
	menu_panel.add_theme_stylebox_override("panel", _panel_style())
	add_child(menu_panel)

	var margin := MarginContainer.new()
	for side in ["margin_left", "margin_top", "margin_right", "margin_bottom"]:
		margin.add_theme_constant_override(side, 22)
	menu_panel.add_child(margin)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 11)
	margin.add_child(content)

	var heading := Label.new()
	heading.text = "MAIN MENU"
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_font_override("font", pixel_font)
	heading.add_theme_font_size_override("font_size", 22)
	heading.add_theme_color_override("font_color", Color("fff1c5"))
	content.add_child(heading)

	_add_image_button(content, "res://menu/button_start.png", _start_game)
	_add_image_button(content, "res://menu/button_setting.png", _open_settings)
	_add_image_button(content, "res://menu/button_credit.png", _open_credits)
	_add_image_button(content, "res://menu/button_exit.png", _exit_game)


func _build_credits() -> void:
	credits_panel = PanelContainer.new()
	credits_panel.name = "CreditsPanel"
	credits_panel.visible = false
	credits_panel.add_theme_stylebox_override("panel", _panel_style())
	add_child(credits_panel)

	var margin := MarginContainer.new()
	for side in ["margin_left", "margin_top", "margin_right", "margin_bottom"]:
		margin.add_theme_constant_override(side, 30)
	credits_panel.add_child(margin)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 18)
	margin.add_child(content)

	var heading := Label.new()
	heading.text = "CREDITS"
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_font_override("font", pixel_font)
	heading.add_theme_font_size_override("font_size", 26)
	heading.add_theme_color_override("font_color", Color("fff1c5"))
	content.add_child(heading)

	var details := Label.new()
	details.text = "BAN KERD: TAI NGAO WINYAN\n\nA folk-horror action adventure\n\nMade with Godot Engine"
	details.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	details.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	details.add_theme_font_override("font", pixel_font)
	details.add_theme_font_size_override("font_size", 15)
	details.add_theme_color_override("font_color", Color("eee8d7"))
	details.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(details)

	var back := _text_button("BACK")
	back.pressed.connect(_close_credits)
	content.add_child(back)


func _build_settings() -> void:
	game_audio = preload("res://GameAudio.gd").new()
	game_audio.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(game_audio)
	sound_settings = preload("res://SoundSettings.gd").new()
	add_child(sound_settings)
	sound_settings.hide()
	sound_settings.connect("volume_changed", Callable(game_audio, "set_volume_level"))
	sound_settings.connect("sensitivity_changed", Callable(game_audio, "set_look_sensitivity"))
	sound_settings.connect("close_requested", Callable(self, "_close_settings"))
	sound_settings.connect("start_menu_requested", Callable(self, "_close_settings"))
	sound_settings.call("set_levels", game_audio.call("get_volume_levels"))
	sound_settings.call("set_sensitivity", game_audio.call("get_look_sensitivity"))


func _add_image_button(parent: VBoxContainer, texture_path: String, action: Callable) -> void:
	var button := TextureButton.new()
	button.texture_normal = load(texture_path)
	button.ignore_texture_size = true
	button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	button.custom_minimum_size = Vector2(300, 65)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.pressed.connect(action)
	parent.add_child(button)


func _text_button(caption: String) -> Button:
	var button := Button.new()
	button.text = caption
	button.custom_minimum_size = Vector2(150, 42)
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	button.add_theme_font_override("font", pixel_font)
	button.add_theme_font_size_override("font_size", 17)
	button.add_theme_color_override("font_color", Color("fff1c5"))
	button.add_theme_color_override("font_hover_color", Color("ffffff"))
	button.add_theme_stylebox_override("normal", _button_style(Color("425b37")))
	button.add_theme_stylebox_override("hover", _button_style(Color("597b48")))
	button.add_theme_stylebox_override("pressed", _button_style(Color("30432a")))
	return button


func _panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.035, 0.045, 0.035, 0.88)
	style.border_color = Color("b28b4c")
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
	style.shadow_color = Color(0, 0, 0, 0.55)
	style.shadow_size = 8
	return style


func _button_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = Color("d2b66e")
	style.set_border_width_all(2)
	style.set_corner_radius_all(3)
	return style


func _layout() -> void:
	if not is_instance_valid(menu_panel):
		return
	var margin := clampf(size.x * 0.045, 20.0, 58.0)
	var panel_width := minf(390.0, size.x * 0.43)
	menu_panel.size = Vector2(panel_width, minf(420.0, size.y * 0.72))
	menu_panel.position = Vector2(size.x - panel_width - margin, (size.y - menu_panel.size.y) * 0.5)
	var logo := get_node("TitleLogo") as TextureRect
	logo.position = Vector2(margin, size.y * 0.12)
	logo.size = Vector2(minf(590.0, size.x * 0.53), 170.0)
	var game_title := get_node("GameTitle") as Label
	game_title.position = Vector2(margin + 16.0, size.y * 0.43)
	game_title.size = Vector2(minf(520.0, size.x * 0.48), 32.0)
	var subtitle := get_node("Subtitle") as Label
	subtitle.position = Vector2(margin + 16.0, size.y * 0.43 + 36.0)
	subtitle.size = Vector2(minf(520.0, size.x * 0.48), 24.0)
	credits_panel.size = Vector2(minf(530.0, size.x - 40.0), minf(350.0, size.y - 40.0))
	credits_panel.position = (size - credits_panel.size) * 0.5


func _start_game() -> void:
	game_audio.queue_free()
	get_tree().change_scene_to_file(GAME_SCENE)


func _open_settings() -> void:
	sound_settings.show()


func _close_settings() -> void:
	sound_settings.hide()


func _open_credits() -> void:
	menu_panel.hide()
	credits_panel.show()


func _close_credits() -> void:
	credits_panel.hide()
	menu_panel.show()


func _exit_game() -> void:
	get_tree().quit()


func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		if sound_settings.visible:
			_close_settings()
		elif credits_panel.visible:
			_close_credits()