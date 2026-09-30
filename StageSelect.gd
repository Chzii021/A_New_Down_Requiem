extends Control

const STAGE_PROGRESS = preload("res://StageProgress.gd")
const MENU_MUSIC = preload("res://MenuMusic.gd")
const STAGE_IMAGES = [
	"res://menu/ChatGPT Image Oct 1, 2026, 03_42_21 AM.png",
	"res://menu/ChatGPT Image Oct 1, 2026, 03_42_25 AM.png",
	"res://menu/ChatGPT Image Oct 1, 2026, 03_42_28 AM.png",
	"res://menu/ChatGPT Image Oct 1, 2026, 03_42_30 AM.png"
]
# Each image has different transparent padding; these regions contain the visible card art.
const STAGE_IMAGE_REGIONS = [
	Rect2(16, 24, 1055, 1389),
	Rect2(28, 43, 1031, 1346),
	Rect2(19, 8, 1048, 1377),
	Rect2(27, 51, 1036, 1355)
]

var pixel_font: Font
var logo: TextureRect
var heading: Label
var subtitle: Label
var stage_row: HBoxContainer
var back_button: Button


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	pixel_font = preload("res://PixelFont.gd").make()
	_build_background()
	_build_title()
	_build_stages()
	_build_back_button()
	MENU_MUSIC.ensure(get_tree(), self)
	resized.connect(_layout)
	_layout()


func _build_background() -> void:
	var background := TextureRect.new()
	background.name = "MenuBackground"
	background.texture = load("res://menu/ChatGPT Image Oct 1, 2026, 02_58_31 AM.png")
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var background_material := ShaderMaterial.new()
	background_material.shader = preload("res://menu/main_menu_sunset.gdshader")
	background.material = background_material
	add_child(background)
	move_child(background, 0)

	var shade := ColorRect.new()
	shade.color = Color(0.035, 0.045, 0.035, 0.45)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)


func _build_title() -> void:
	logo = TextureRect.new()
	logo.texture = load("res://menu/title_logo.png")
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(logo)

	heading = _label("เลือกด่าน", 31, Color("fff1c5"))
	add_child(heading)
	subtitle = _label("เลือกด่านที่ปลดล็อกแล้วเพื่อเริ่มเล่น", 16, Color("e2ddc9"))
	add_child(subtitle)


func _build_stages() -> void:
	stage_row = HBoxContainer.new()
	stage_row.name = "StageCards"
	stage_row.add_theme_constant_override("separation", 16)
	add_child(stage_row)
	var highest := STAGE_PROGRESS.highest_unlocked()
	for stage_number in range(1, STAGE_PROGRESS.STAGE_COUNT + 1):
		stage_row.add_child(_stage_card(stage_number, stage_number <= highest))


func _stage_card(stage_number: int, unlocked: bool) -> TextureButton:
	var card := TextureButton.new()
	card.name = "Stage%d" % stage_number
	var image := AtlasTexture.new()
	image.atlas = load(STAGE_IMAGES[stage_number - 1]) as Texture2D
	image.region = STAGE_IMAGE_REGIONS[stage_number - 1]
	card.texture_normal = image
	card.texture_hover = card.texture_normal
	card.texture_pressed = card.texture_normal
	card.texture_disabled = card.texture_normal
	card.ignore_texture_size = true
	card.stretch_mode = TextureButton.STRETCH_SCALE
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.size_flags_vertical = Control.SIZE_EXPAND_FILL
	card.disabled = not unlocked
	if unlocked:
		card.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		card.mouse_entered.connect(func(): card.self_modulate = Color(1.12, 1.12, 1.12))
		card.mouse_exited.connect(func(): card.self_modulate = Color.WHITE)
		card.pressed.connect(_choose_stage.bind(stage_number))
	else:
		card.self_modulate = Color(0.34, 0.34, 0.34)
		_add_locked_label(card)
	return card


func _add_locked_label(card: TextureButton) -> void:
	var center := CenterContainer.new()
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	card.add_child(center)
	var label_panel := PanelContainer.new()
	label_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.02, 0.025, 0.02, 0.85)
	panel_style.set_corner_radius_all(4)
	label_panel.add_theme_stylebox_override("panel", panel_style)
	center.add_child(label_panel)
	var label := _label("ยังไม่ปลดล็อก", 17, Color("fff1c5"))
	label.name = "LockedLabel"
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.custom_minimum_size = Vector2(150, 42)
	label_panel.add_child(label)


func _build_back_button() -> void:
	back_button = Button.new()
	back_button.text = "กลับเมนูหลัก"
	back_button.add_theme_font_override("font", pixel_font)
	back_button.add_theme_font_size_override("font_size", 18)
	back_button.add_theme_color_override("font_color", Color("fff1c5"))
	back_button.add_theme_stylebox_override("normal", _button_style(Color("334735"), Color("b28b4c")))
	back_button.add_theme_stylebox_override("hover", _button_style(Color("4e684a"), Color("d2b66e")))
	back_button.add_theme_stylebox_override("pressed", _button_style(Color("263629"), Color("b28b4c")))
	back_button.pressed.connect(_return_to_menu)
	add_child(back_button)


func _label(caption: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = caption
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_override("font", pixel_font)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label


func _button_style(fill: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(2)
	style.set_corner_radius_all(3)
	return style


func _layout() -> void:
	if not is_instance_valid(stage_row):
		return
	var logo_size := Vector2(minf(420.0, size.x * 0.64), minf(145.0, size.y * 0.21))
	logo.size = logo_size
	logo.position = Vector2((size.x - logo_size.x) * 0.5, maxf(12.0, size.y * 0.025))
	heading.size = Vector2(size.x, 46)
	heading.position = Vector2(0, size.y * 0.26)
	subtitle.size = Vector2(size.x, 28)
	subtitle.position = Vector2(0, heading.position.y + 46)
	var row_width := minf(1120.0, size.x - 48.0)
	var row_height := minf(360.0, size.y * 0.50)
	stage_row.size = Vector2(row_width, row_height)
	stage_row.position = Vector2((size.x - row_width) * 0.5, minf(size.y * 0.41, size.y - row_height - 88.0))
	back_button.size = Vector2(220, 44)
	back_button.position = Vector2((size.x - back_button.size.x) * 0.5, stage_row.position.y + row_height + 18.0)


func _choose_stage(stage_number: int) -> void:
	if stage_number > STAGE_PROGRESS.highest_unlocked():
		return
	var result := STAGE_PROGRESS.start_stage(get_tree(), stage_number)
	if result != OK:
		push_error("Could not start stage %d (error %d)" % [stage_number, result])


func _return_to_menu() -> void:
	get_tree().change_scene_to_file("res://MainMenu.tscn")


func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		_return_to_menu()
