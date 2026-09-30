extends CanvasLayer

signal completed

const IMAGES = [
	"res://menu/exec-05b81eb4-f53f-4bda-ad66-0d39649ef2f0.png",
	"res://menu/Vikrom's Obstacle Course Training.png",
	"res://menu/exec-07653145-2f69-4949-942d-c675cabf360b.png",
	"res://menu/exec-0cd429ac-b282-45c3-a975-0e850d4b8dfe.png",
	"res://menu/exec-4348d399-61dd-4614-ac93-7271a79d3554.png",
	"res://menu/exec-2d8b2360-e45f-47ba-97b7-84d0d103e77c.png"
]
const STORY = [
	"หลังจากปราบบอสในการผจญภัยครั้งก่อน วิกรมเข้ารับราชการทหารและเริ่มต้นชีวิตบทใหม่",
	"เขาผ่านการฝึกฝนจนชำนาญการใช้อาวุธ การเล็ง การหลบหลีก และการเอาตัวรอด",
	"เมื่อมีโอกาสกลับบ้านเกิด วิกรมกลับพบว่าหมู่บ้านเงียบผิดปกติ ราวกับทุกคนกำลังหลบซ่อนบางสิ่ง",
	"ชาวบ้านบางคนถูกวิญญาณเข้าสิงและโจมตีผู้ที่เข้าใกล้ วิกรมต้องสำรวจหมู่บ้านและช่วยเหลือผู้รอดชีวิต",
	"ระหว่างทาง เขาเก็บชิ้นส่วนปืนและกระสุนที่กระจัดกระจาย เพื่อนำมาซ่อมและประกอบอาวุธสำหรับด่านถัดไป",
	"วิกรมต้องแยกวิญญาณที่กำลังโจมตีออกจากชาวบ้านที่ยังช่วยได้ ก่อนเผชิญหน้ากับวิญญาณต้นเหตุ ณ สถานที่ศักดิ์สิทธิ์ของหมู่บ้าน"
]

var page := 0
var switching := false
var screen: Control
var artwork: TextureRect
var fade_cover: ColorRect
var caption_panel: Panel
var page_label: Label
var story_label: Label
var previous_button: Button
var next_button: Button
var skip_button: Button
var pixel_font: Font


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 100
	pixel_font = preload("res://PixelFont.gd").make()
	_build_ui()
	get_viewport().size_changed.connect(_layout)
	_layout()
	_show_page(0)
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func _build_ui() -> void:
	screen = Control.new()
	screen.name = "StoryScreen"
	screen.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(screen)
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	artwork = TextureRect.new()
	artwork.name = "StoryArtwork"
	artwork.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	artwork.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	artwork.mouse_filter = Control.MOUSE_FILTER_IGNORE
	screen.add_child(artwork)
	artwork.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	fade_cover = ColorRect.new()
	fade_cover.color = Color(0.012, 0.018, 0.018, 0.0)
	fade_cover.mouse_filter = Control.MOUSE_FILTER_IGNORE
	screen.add_child(fade_cover)
	fade_cover.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	caption_panel = Panel.new()
	caption_panel.name = "StoryCaption"
	var caption_style := StyleBoxFlat.new()
	caption_style.bg_color = Color(0.025, 0.045, 0.04, 0.91)
	caption_style.border_color = Color("bd9655")
	caption_style.set_border_width(SIDE_TOP, 2)
	caption_panel.add_theme_stylebox_override("panel", caption_style)
	screen.add_child(caption_panel)

	page_label = _label("", 17, Color("d2b66e"))
	caption_panel.add_child(page_label)
	story_label = _label("", 23, Color("fff4d8"))
	story_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	story_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	caption_panel.add_child(story_label)

	previous_button = _button("ย้อนกลับ")
	previous_button.pressed.connect(_previous_page)
	caption_panel.add_child(previous_button)
	next_button = _button("ต่อไป")
	next_button.pressed.connect(_next_page)
	caption_panel.add_child(next_button)
	skip_button = _button("ข้ามเรื่อง")
	skip_button.pressed.connect(_finish)
	screen.add_child(skip_button)


func _label(value: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = value
	label.add_theme_font_override("font", pixel_font)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.85))
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	return label


func _button(value: String) -> Button:
	var button := Button.new()
	button.text = value
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.add_theme_font_override("font", pixel_font)
	button.add_theme_font_size_override("font_size", 18)
	button.add_theme_color_override("font_color", Color("fff1c5"))
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_stylebox_override("normal", _button_style(Color(0.12, 0.19, 0.15, 0.94)))
	button.add_theme_stylebox_override("hover", _button_style(Color(0.23, 0.34, 0.25, 0.98)))
	button.add_theme_stylebox_override("pressed", _button_style(Color(0.08, 0.13, 0.10, 1.0)))
	return button


func _button_style(fill: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = Color("bd9655")
	style.set_border_width_all(2)
	style.set_corner_radius_all(3)
	return style


func _layout() -> void:
	if not is_instance_valid(caption_panel):
		return
	var viewport_size := get_viewport().get_visible_rect().size
	var panel_height := clampf(viewport_size.y * 0.28, 170.0, 220.0)
	var margin := clampf(viewport_size.x * 0.05, 24.0, 72.0)
	caption_panel.position = Vector2(0.0, viewport_size.y - panel_height)
	caption_panel.size = Vector2(viewport_size.x, panel_height)
	page_label.position = Vector2(margin, 12.0)
	page_label.size = Vector2(160.0, 26.0)
	story_label.position = Vector2(margin, 37.0)
	story_label.size = Vector2(viewport_size.x - margin * 2.0, panel_height - 93.0)
	previous_button.position = Vector2(margin, panel_height - 49.0)
	previous_button.size = Vector2(144.0, 38.0)
	next_button.position = Vector2(viewport_size.x - margin - 174.0, panel_height - 49.0)
	next_button.size = Vector2(174.0, 38.0)
	skip_button.position = Vector2(viewport_size.x - margin - 135.0, 22.0)
	skip_button.size = Vector2(135.0, 40.0)


func _show_page(index: int) -> void:
	page = index
	artwork.texture = load(IMAGES[page]) as Texture2D
	page_label.text = "เรื่องราว  %02d / %02d" % [page + 1, IMAGES.size()]
	story_label.text = STORY[page]
	previous_button.disabled = page == 0
	next_button.text = "เริ่มด่าน 1" if page == IMAGES.size() - 1 else "ต่อไป"


func _change_page(index: int) -> void:
	if switching or index < 0 or index >= IMAGES.size():
		return
	switching = true
	var tween := create_tween()
	tween.tween_property(fade_cover, "color:a", 1.0, 0.15)
	tween.tween_callback(_show_page.bind(index))
	tween.tween_property(fade_cover, "color:a", 0.0, 0.2)
	tween.tween_callback(func(): switching = false)


func _previous_page() -> void:
	_change_page(page - 1)


func _next_page() -> void:
	if switching:
		return
	if page == IMAGES.size() - 1:
		_finish()
	else:
		_change_page(page + 1)


func _finish() -> void:
	get_viewport().set_input_as_handled()
	completed.emit()


func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_ENTER, KEY_KP_ENTER, KEY_SPACE, KEY_RIGHT:
				_next_page()
				get_viewport().set_input_as_handled()
			KEY_LEFT:
				_previous_page()
				get_viewport().set_input_as_handled()
			KEY_ESCAPE:
				_finish()
