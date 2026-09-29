extends Control

signal volume_changed(category: String, level: float)
signal sensitivity_changed(level: float)
signal close_requested

var panel: Panel
var sliders = {}
var values = {}
var pixel_font: Font


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	pixel_font = preload("res://PixelFont.gd").make()
	var shade := ColorRect.new()
	shade.color = Color(.04, .04, .04, .75)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(shade)
	panel = Panel.new()
	panel.size = Vector2(460, 410)
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
	top_line.size = Vector2(454, 76)
	panel.add_child(top_line)
	_label("GAME SETTINGS", Vector2(28, 18), Vector2(390, 34), 25, Color("ffffff"), true)
	_label("ปรับระดับเสียงและความไวเมาส์", Vector2(30, 54), Vector2(390, 24), 14, Color("d4d4d4"))
	_add_slider("music", "เพลงประกอบ", 90)
	_add_slider("gun", "เสียงปืน", 157)
	_add_slider("effects", "เอฟเฟกต์เกม", 224)
	_add_slider("sensitivity", "ความไวเมาส์", 291)
	_label("Esc  กลับไปเล่น", Vector2(30, 370), Vector2(210, 24), 13, Color("d4d4d4"))
	var close_button := Button.new()
	close_button.text = "CLOSE"
	close_button.position = Vector2(285, 361)
	close_button.size = Vector2(145, 36)
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
	close_button.pressed.connect(func(): close_requested.emit())
	resized.connect(_layout)
	_layout()


func _label(content: String, pos: Vector2, dimensions: Vector2, font_size: int, tint: Color, pixel: bool = false) -> Label:
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
	var value_label := _label("100%", Vector2(354, top), Vector2(74, 24), 17, Color("ffffff"), true)
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	var slider := HSlider.new()
	slider.position = Vector2(30, top + 26)
	slider.size = Vector2(398, 28)
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
		panel.position = (size - panel.size) * .5


func _unhandled_key_input(event: InputEvent) -> void:
	if visible and event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		close_requested.emit()
		get_viewport().set_input_as_handled()
