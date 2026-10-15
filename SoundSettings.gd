extends Control

signal volume_changed(category: String, level: float)
signal sensitivity_changed(level: float)
signal video_changed(key: String, value: Variant)
signal close_requested
signal start_menu_requested

var panel: Panel
var sliders = {}
var values = {}
var video_controls = {}
var pixel_font: Font
var show_game_return_hint := true
var backdrop_alpha := 0.75


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	pixel_font = preload("res://PixelFont.gd").make()
	var shade := ColorRect.new()
	shade.color = Color(.04, .04, .04, backdrop_alpha)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(shade)
	panel = Panel.new()
	panel.size = Vector2(730, 530)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	var frame := StyleBoxFlat.new()
	frame.bg_color = Color("454545")
	frame.border_color = Color("151515")
	frame.set_border_width_all(3)
	frame.set_corner_radius_all(0)
	frame.shadow_color = Color(0, 0, 0, .6)
	frame.shadow_size = 8
	panel.add_theme_stylebox_override("panel", frame)
	add_child(panel)
	var top_line := ColorRect.new()
	top_line.color = Color("303030")
	top_line.position = Vector2(3, 3)
	top_line.size = Vector2(724, 76)
	panel.add_child(top_line)
	_label("GAME SETTINGS", Vector2(28, 18), Vector2(670, 34), 25, Color("ffffff"), true)
	_label("เสียง • การควบคุม • ภาพ", Vector2(30, 54), Vector2(670, 24), 14, Color("d4d4d4"))
	_label("AUDIO / CONTROL", Vector2(30, 89), Vector2(290, 25), 18, Color("d9bc75"))
	_label("GRAPHICS / DISPLAY", Vector2(390, 89), Vector2(290, 25), 18, Color("d9bc75"))
	_add_slider("music", "เพลงประกอบ", 120)
	_add_slider("gun", "เสียงปืน", 200)
	_add_slider("effects", "เอฟเฟกต์เกม", 280)
	_add_slider("sensitivity", "ความไวเมาส์", 360)
	_add_option("quality", "คุณภาพภาพ", 121, ["ประหยัด (เว็บ)", "สมดุล", "สวย"])
	_add_option("fps_limit", "จำกัด FPS", 201, ["30 FPS", "60 FPS", "ไม่จำกัด"])
	_add_check("fullscreen", "เต็มจอ", 288)
	_add_check("vsync", "V-Sync", 343)
	_add_check("camera_shake", "กล้องสั่นเมื่อบาดเจ็บ", 398)
	if show_game_return_hint:
		_label("Esc  กลับไปเล่น", Vector2(30, 482), Vector2(210, 24), 13, Color("d4d4d4"))
	var close_button := Button.new()
	close_button.text = "MAIN MENU"
	close_button.position = Vector2(525, 473)
	close_button.size = Vector2(175, 38)
	close_button.add_theme_font_override("font", pixel_font)
	close_button.add_theme_font_size_override("font_size", 19)
	close_button.add_theme_color_override("font_color", Color("ffffff"))
	close_button.add_theme_color_override("font_hover_color", Color("ffffff"))
	close_button.add_theme_color_override("font_pressed_color", Color("ffffff"))
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color("3b9a35")
	normal.border_color = Color("151515")
	normal.set_border_width_all(3)
	normal.set_corner_radius_all(0)
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color("55b74b")
	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = Color("2b7228")
	close_button.add_theme_stylebox_override("normal", normal)
	close_button.add_theme_stylebox_override("hover", hover)
	close_button.add_theme_stylebox_override("pressed", pressed)
	panel.add_child(close_button)
	close_button.pressed.connect(func(): start_menu_requested.emit())
	resized.connect(_layout)
	_layout()


func _label(content: String, pos: Vector2, dimensions: Vector2, font_size: int, tint: Color, _pixel: bool = false) -> Label:
	var label := Label.new()
	label.text = content
	label.position = pos
	label.size = dimensions
	label.add_theme_font_override("font", pixel_font)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", tint)
	panel.add_child(label)
	return label


func _add_slider(category: String, caption: String, top: float) -> void:
	_label(caption, Vector2(30, top), Vector2(300, 24), 16, Color("f2f2f2"))
	var value_label := _label("100%", Vector2(275, top), Vector2(74, 24), 17, Color("ffffff"), true)
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	var slider := HSlider.new()
	slider.position = Vector2(30, top + 26)
	slider.size = Vector2(318, 28)
	slider.min_value = 25.0 if category == "sensitivity" else 0.0
	slider.max_value = 200.0 if category == "sensitivity" else 100.0
	slider.step = 5.0 if category == "sensitivity" else 1.0
	slider.value = 100.0
	var track := StyleBoxFlat.new()
	track.bg_color = Color("242424")
	track.border_color = Color("151515")
	track.set_border_width_all(2)
	track.set_corner_radius_all(0)
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color("60b54c") if category == "music" else (Color("a470da") if category == "gun" else (Color("a7d35b") if category == "sensitivity" else Color("68bfdd")))
	fill.set_corner_radius_all(0)
	slider.add_theme_stylebox_override("slider", track)
	slider.add_theme_stylebox_override("grabber_area", fill)
	slider.add_theme_stylebox_override("grabber_area_highlight", fill)
	panel.add_child(slider)
	slider.value_changed.connect(_on_slider_changed.bind(category))
	sliders[category] = slider
	values[category] = value_label


func _add_option(key: String, caption: String, top: float, choices: Array) -> void:
	_label(caption, Vector2(390, top), Vector2(300, 24), 16, Color("f2f2f2"))
	var option := OptionButton.new()
	option.position = Vector2(390, top + 26)
	option.size = Vector2(310, 37)
	option.add_theme_font_override("font", pixel_font)
	option.add_theme_font_size_override("font_size", 16)
	for choice in choices:
		option.add_item(choice)
	panel.add_child(option)
	option.item_selected.connect(_on_option_selected.bind(key))
	video_controls[key] = option


func _add_check(key: String, caption: String, top: float) -> void:
	var check := CheckButton.new()
	check.text = caption
	check.position = Vector2(390, top)
	check.size = Vector2(310, 35)
	check.add_theme_font_override("font", pixel_font)
	check.add_theme_font_size_override("font_size", 16)
	check.add_theme_color_override("font_color", Color("f2f2f2"))
	panel.add_child(check)
	check.toggled.connect(_on_check_toggled.bind(key))
	video_controls[key] = check


func set_video_settings(settings: Dictionary) -> void:
	(video_controls["quality"] as OptionButton).select(int(settings.get("quality", 0)))
	var fps_index := [30, 60, 0].find(int(settings.get("fps_limit", 60)))
	(video_controls["fps_limit"] as OptionButton).select(maxi(fps_index, 0))
	for key in ["fullscreen", "vsync", "camera_shake"]:
		(video_controls[key] as CheckButton).set_pressed_no_signal(bool(settings.get(key, false)))


func _on_option_selected(index: int, key: String) -> void:
	video_changed.emit(key, [30, 60, 0][index] if key == "fps_limit" else index)


func _on_check_toggled(value: bool, key: String) -> void:
	video_changed.emit(key, value)


func set_levels(levels: Dictionary) -> void:
	for category in sliders.keys():
		if category == "sensitivity":
			continue
		var percent: float = clampf(float(levels.get(category, 1.0)), 0.0, 1.0) * 100.0
		sliders[category].set_value_no_signal(percent)
		values[category].text = "%d%%" % int(round(percent))


func set_sensitivity(level: float) -> void:
	var percent := clampf(level, 0.25, 2.0) * 100.0
	sliders["sensitivity"].set_value_no_signal(percent)
	values["sensitivity"].text = "%d%%" % int(round(percent))


func _on_slider_changed(percent: float, category: String) -> void:
	values[category].text = "%d%%" % int(round(percent))
	if category == "sensitivity":
		sensitivity_changed.emit(percent / 100.0)
	else:
		volume_changed.emit(category, percent / 100.0)


func _layout() -> void:
	if is_instance_valid(panel):
		panel.scale = Vector2.ONE * minf(1.0, minf(size.x / 750.0, size.y / 550.0))
		panel.position = (size - panel.size * panel.scale) * .5


func _unhandled_key_input(event: InputEvent) -> void:
	if visible and event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		close_requested.emit()
		get_viewport().set_input_as_handled()
