extends CanvasLayer

signal restart_requested
signal menu_requested

const BACKGROUND = preload("res://menu/Dawn of the Freed Isan Village.png")
const WIN_IMAGE = preload("res://menu/Retro pixel-art WIN wordmark.png")
const RESTART_IMAGE = preload("res://menu/Rustic teak pixel-art Restart button.png")
const MENU_IMAGE = preload("res://menu/Rustic Thai stilt-house menu button.png")

const WIN_REGION = Rect2(93, 136, 1758, 560)
const RESTART_REGION = Rect2(55, 100, 1957, 561)
const MENU_REGION = Rect2(53, 108, 1967, 557)

var screen: Control
var win_logo: TextureRect
var story_panel: Panel
var story_heading: Label
var story_text: Label
var restart_button: TextureButton
var menu_button: TextureButton
var pixel_font: Font


func _ready() -> void:
	layer = 100
	pixel_font = preload("res://PixelFont.gd").make()
	_build_ui()
	get_viewport().size_changed.connect(_layout)
	_layout()
	screen.modulate.a = 0.0
	create_tween().tween_property(screen, "modulate:a", 1.0, 0.7)


func _build_ui() -> void:
	screen = Control.new()
	screen.name = "VictoryScreen"
	screen.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(screen)
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var background := TextureRect.new()
	background.name = "FreedVillage"
	background.texture = BACKGROUND
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	screen.add_child(background)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var shade := ColorRect.new()
	shade.color = Color(0.045, 0.035, 0.025, 0.14)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	screen.add_child(shade)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	win_logo = TextureRect.new()
	win_logo.name = "WinLogo"
	win_logo.texture = _crop(WIN_IMAGE, WIN_REGION)
	win_logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	win_logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	win_logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	screen.add_child(win_logo)

	story_panel = Panel.new()
	story_panel.name = "AftermathStory"
	story_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var frame := StyleBoxFlat.new()
	frame.bg_color = Color(0.025, 0.05, 0.04, 0.88)
	frame.border_color = Color("c09b5c")
	frame.set_border_width_all(2)
	frame.set_corner_radius_all(5)
	frame.shadow_color = Color(0, 0, 0, 0.55)
	frame.shadow_size = 8
	story_panel.add_theme_stylebox_override("panel", frame)
	screen.add_child(story_panel)

	story_heading = _label("บ้านเกิดที่เป็นอิสระ", 25, Color("ffe5a5"))
	story_panel.add_child(story_heading)
	story_text = _label(
		"เมื่อวิกรมปราบวิญญาณต้นเหตุได้ พลังมืดที่ปกคลุมหมู่บ้านก็ค่อย ๆ สลาย ชาวบ้านที่ถูกสิงกลับมามีสติ และยายจ่อยเป็นอิสระ\n\nรุ่งอรุณใหม่ส่องลงบนบ้านเกิด วิกรมได้กลับมาพบทุกคนอีกครั้ง หมู่บ้านที่เคยเงียบงันกลับเต็มไปด้วยรอยยิ้มและเสียงหัวเราะ",
		20, Color("fff4dd"))
	story_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	story_panel.add_child(story_text)

	restart_button = _image_button("RestartButton", RESTART_IMAGE, RESTART_REGION)
	restart_button.pressed.connect(func(): restart_requested.emit())
	screen.add_child(restart_button)
	menu_button = _image_button("MainMenuButton", MENU_IMAGE, MENU_REGION)
	menu_button.pressed.connect(func(): menu_requested.emit())
	screen.add_child(menu_button)


func _crop(source: Texture2D, region: Rect2) -> AtlasTexture:
	var cropped := AtlasTexture.new()
	cropped.atlas = source
	cropped.region = region
	return cropped


func _label(value: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = value
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_override("font", pixel_font)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.85))
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	return label


func _image_button(node_name: String, source: Texture2D, region: Rect2) -> TextureButton:
	var button := TextureButton.new()
	button.name = node_name
	button.texture_normal = _crop(source, region)
	button.texture_hover = button.texture_normal
	button.texture_pressed = button.texture_normal
	button.ignore_texture_size = true
	button.stretch_mode = TextureButton.STRETCH_SCALE
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.mouse_entered.connect(func(): button.self_modulate = Color(1.15, 1.15, 1.15))
	button.mouse_exited.connect(func(): button.self_modulate = Color.WHITE)
	return button


func _layout() -> void:
	if not is_instance_valid(story_panel):
		return
	var viewport_size := get_viewport().get_visible_rect().size
	var scale := clampf(minf(viewport_size.x / 1280.0, viewport_size.y / 720.0), 0.65, 1.5)
	var left := maxf(20.0, viewport_size.x * 0.045)
	win_logo.position = Vector2(left + 22.0 * scale, 22.0 * scale)
	win_logo.size = Vector2(430.0, 137.0) * scale
	story_panel.position = Vector2(left, 181.0 * scale)
	story_panel.size = Vector2(minf(500.0 * scale, viewport_size.x - left * 2.0), 298.0 * scale)
	story_heading.position = Vector2(22.0, 15.0) * scale
	story_heading.size = Vector2(story_panel.size.x - 44.0 * scale, 36.0 * scale)
	story_heading.add_theme_font_size_override("font_size", roundi(25.0 * scale))
	story_text.position = Vector2(22.0, 58.0) * scale
	story_text.size = Vector2(story_panel.size.x - 44.0 * scale, story_panel.size.y - 75.0 * scale)
	story_text.add_theme_font_size_override("font_size", roundi(20.0 * scale))
	var button_size := Vector2((story_panel.size.x - 20.0 * scale) * 0.5, 69.0 * scale)
	var button_y := story_panel.position.y + story_panel.size.y + 18.0 * scale
	restart_button.position = Vector2(left, button_y)
	restart_button.size = button_size
	menu_button.position = Vector2(left + button_size.x + 20.0 * scale, button_y)
	menu_button.size = button_size


func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER:
			get_viewport().set_input_as_handled()
			restart_requested.emit()
		elif event.keycode == KEY_ESCAPE:
			get_viewport().set_input_as_handled()
			menu_requested.emit()
