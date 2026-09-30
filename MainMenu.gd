extends Control

const STAGE_SELECT_SCENE := "res://StageSelect.tscn"
const MENU_MUSIC = preload("res://MenuMusic.gd")

var pixel_font: Font
var menu_background: TextureRect
var menu_shade: ColorRect
var title_logo: TextureRect
var menu_panel: PanelContainer
var menu_buttons: VBoxContainer
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
	menu_background = TextureRect.new()
	menu_background.name = "MenuBackground"
	menu_background.texture = load("res://menu/ChatGPT Image Oct 1, 2026, 02_58_31 AM.png")
	menu_background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	menu_background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	menu_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	menu_background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var background_material := ShaderMaterial.new()
	background_material.shader = preload("res://menu/main_menu_sunset.gdshader")
	menu_background.material = background_material
	add_child(menu_background)
	move_child(menu_background, 0)

	menu_shade = ColorRect.new()
	menu_shade.color = Color(0.035, 0.045, 0.035, 0.1)
	menu_shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	menu_shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(menu_shade)


func _build_title() -> void:
	title_logo = TextureRect.new()
	title_logo.name = "TitleLogo"
	title_logo.texture = load("res://menu/title_logo.png")
	title_logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	title_logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	title_logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(title_logo)


func _build_menu() -> void:
	menu_panel = PanelContainer.new()
	menu_panel.name = "MenuPanel"
	menu_panel.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	add_child(menu_panel)

	var margin := MarginContainer.new()
	for side in ["margin_left", "margin_top", "margin_right", "margin_bottom"]:
		margin.add_theme_constant_override(side, 0)
	menu_panel.add_child(margin)

	var content := VBoxContainer.new()
	content.name = "MenuButtons"
	content.add_theme_constant_override("separation", 12)
	menu_buttons = content
	margin.add_child(content)

	_add_image_button(content, "res://menu/ChatGPT Image Oct 1, 2026, 03_15_28 AM.png", Rect2(32, 88, 2016, 608), _start_game)
	_add_image_button(content, "res://menu/ChatGPT Image Oct 1, 2026, 03_15_29 AM.png", Rect2(48, 72, 2080, 596), _open_settings)
	_add_image_button(content, "res://menu/ChatGPT Image Oct 1, 2026, 03_15_33 AM.png", Rect2(52, 100, 1948, 556), _open_credits)
	_add_image_button(content, "res://menu/ChatGPT Image Oct 1, 2026, 03_15_31 AM.png", Rect2(56, 104, 1940, 552), _exit_game)


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
	content.add_theme_constant_override("separation", 16)
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	margin.add_child(content)

	var heading := Label.new()
	heading.text = "CREDITS"
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_font_override("font", pixel_font)
	heading.add_theme_font_size_override("font_size", 28)
	heading.add_theme_color_override("font_color", Color("fff1c5"))
	content.add_child(heading)

	var game_title := Label.new()
	game_title.text = "A NEW DAWN"
	game_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	game_title.add_theme_font_override("font", pixel_font)
	game_title.add_theme_font_size_override("font_size", 26)
	game_title.add_theme_color_override("font_color", Color("fff1c5"))
	content.add_child(game_title)

	var group_credit := Label.new()
	group_credit.text = "CREATED BY GROUP 15"
	group_credit.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	group_credit.add_theme_font_override("font", pixel_font)
	group_credit.add_theme_font_size_override("font_size", 20)
	group_credit.add_theme_color_override("font_color", Color("fff1c5"))
	content.add_child(group_credit)

	var details := Label.new()
	details.text = "ชวกร สมทรัพย์ — 673380312-5\nมหาสมุทร แมทโอ เจแดน — 673380339-5\nเสรีธรรม ประทุมรัตน์ — 673380359-9"
	details.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	details.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	details.autowrap_mode = TextServer.AUTOWRAP_OFF
	details.add_theme_font_override("font", pixel_font)
	details.add_theme_font_size_override("font_size", 19)
	details.add_theme_color_override("font_color", Color("eee8d7"))
	content.add_child(details)

	var made_with := Label.new()
	made_with.text = "MADE WITH GODOT ENGINE"
	made_with.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	made_with.add_theme_font_override("font", pixel_font)
	made_with.add_theme_font_size_override("font_size", 14)
	made_with.add_theme_color_override("font_color", Color("fff1c5"))
	content.add_child(made_with)

	var back := _text_button("BACK")
	back.pressed.connect(_close_credits)
	content.add_child(back)


func _build_settings() -> void:
	game_audio = MENU_MUSIC.ensure(get_tree(), self)
	sound_settings = preload("res://SoundSettings.gd").new()
	sound_settings.set("show_game_return_hint", false)
	sound_settings.set("backdrop_alpha", 0.1)
	add_child(sound_settings)
	sound_settings.hide()
	sound_settings.connect("volume_changed", Callable(game_audio, "set_volume_level"))
	sound_settings.connect("sensitivity_changed", Callable(game_audio, "set_look_sensitivity"))
	sound_settings.connect("close_requested", Callable(self, "_close_settings"))
	sound_settings.connect("start_menu_requested", Callable(self, "_close_settings"))
	sound_settings.call("set_levels", game_audio.call("get_volume_levels"))
	sound_settings.call("set_sensitivity", game_audio.call("get_look_sensitivity"))


func _add_image_button(parent: VBoxContainer, texture_path: String, crop: Rect2, action: Callable) -> void:
	var button := TextureButton.new()
	var cropped_texture := AtlasTexture.new()
	cropped_texture.atlas = load(texture_path)
	cropped_texture.region = crop
	button.texture_normal = cropped_texture
	button.ignore_texture_size = true
	button.stretch_mode = TextureButton.STRETCH_SCALE
	button.custom_minimum_size = Vector2(350, 100)
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
	var button_width := minf(350.0, size.x * 0.82)
	var button_height := minf(100.0, maxf(52.0, size.y * 0.139))
	button_height = minf(button_height, button_width / 3.5)
	var separation := minf(20.0, size.y * 0.0278)
	menu_buttons.add_theme_constant_override("separation", int(roundf(separation)))
	for button in menu_buttons.get_children():
		button.custom_minimum_size = Vector2(button_width, button_height)
	var menu_height := button_height * 4.0 + separation * 3.0
	menu_panel.size = Vector2(button_width, menu_height)
	menu_panel.position = Vector2((size.x - button_width) * 0.5, minf(size.y * 0.32, size.y - menu_height - 12.0))
	var logo_width := minf(460.0, size.x * 0.62)
	var logo_height := minf(192.0, size.y * 0.28)
	title_logo.position = Vector2((size.x - logo_width) * 0.5, size.y * 0.01)
	title_logo.size = Vector2(logo_width, logo_height)
	credits_panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	var credits_width := minf(520.0, minf(size.x - 40.0, size.y - 40.0))
	var credits_height := minf(500.0, size.y - 40.0)
	credits_panel.size = Vector2(credits_width, credits_height)
	credits_panel.position = (size - credits_panel.size) * 0.5


func _start_game() -> void:
	get_tree().change_scene_to_file(STAGE_SELECT_SCENE)


func _open_settings() -> void:
	title_logo.hide()
	menu_panel.hide()
	sound_settings.show()


func _close_settings() -> void:
	sound_settings.hide()
	title_logo.show()
	menu_panel.show()


func _open_credits() -> void:
	_layout()
	menu_panel.hide()
	title_logo.hide()
	credits_panel.show()


func _close_credits() -> void:
	credits_panel.hide()
	title_logo.show()
	menu_panel.show()


func _exit_game() -> void:
	get_tree().quit()


func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		if sound_settings.visible:
			_close_settings()
		elif credits_panel.visible:
			_close_credits()
