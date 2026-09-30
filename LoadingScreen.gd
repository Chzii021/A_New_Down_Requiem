extends CanvasLayer

const GAME_SCENE := "res://Main.tscn"
const STAGE_PROGRESS = preload("res://StageProgress.gd")
const MENU_MUSIC = preload("res://MenuMusic.gd")

var selected_stage := 1

var screen: Control
var logo: TextureRect
var card: Panel
var progress_bar: ProgressBar
var percent_label: Label
var status_label: Label
var back_button: Button
var pixel_font: Font


func _ready() -> void:
	MENU_MUSIC.stop(get_tree())
	selected_stage = clampi(STAGE_PROGRESS.selected_stage, 1, STAGE_PROGRESS.STAGE_COUNT)
	pixel_font = preload("res://PixelFont.gd").make()
	_build_ui()
	get_viewport().size_changed.connect(_layout)
	_layout()
	set_process(false)
	call_deferred("_begin_loading")


func _build_ui() -> void:
	screen = Control.new()
	screen.name = "Screen"
	screen.mouse_filter = Control.MOUSE_FILTER_STOP
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(screen)

	var background := TextureRect.new()
	background.texture = load("res://menu/menu_background.png")
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	screen.add_child(background)

	var shade := ColorRect.new()
	shade.color = Color(0.025, 0.04, 0.03, 0.76)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	screen.add_child(shade)

	logo = TextureRect.new()
	logo.name = "TitleLogo"
	logo.texture = load("res://menu/title_logo.png")
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	screen.add_child(logo)

	card = Panel.new()
	card.name = "LoadingPanel"
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.035, 0.06, 0.045, 0.94)
	panel_style.border_color = Color("b28b4c")
	panel_style.set_border_width_all(2)
	panel_style.set_corner_radius_all(5)
	panel_style.shadow_color = Color(0, 0, 0, 0.55)
	panel_style.shadow_size = 12
	card.add_theme_stylebox_override("panel", panel_style)
	screen.add_child(card)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["margin_left", "margin_top", "margin_right", "margin_bottom"]:
		margin.add_theme_constant_override(side, 28)
	card.add_child(margin)

	var content := VBoxContainer.new()
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_theme_constant_override("separation", 14)
	margin.add_child(content)

	var heading := _label("LOADING", 36, Color("fff1c5"))
	content.add_child(heading)

	status_label = _label("กำลังเตรียมการเดินทาง...", 18, Color("eee8d7"))
	content.add_child(status_label)

	progress_bar = ProgressBar.new()
	progress_bar.name = "LoadingProgress"
	progress_bar.min_value = 0.0
	progress_bar.max_value = 100.0
	progress_bar.value = 0.0
	progress_bar.show_percentage = false
	progress_bar.custom_minimum_size = Vector2(0, 24)
	var bar_background := StyleBoxFlat.new()
	bar_background.bg_color = Color("17251b")
	bar_background.border_color = Color("907244")
	bar_background.set_border_width_all(2)
	progress_bar.add_theme_stylebox_override("background", bar_background)
	var bar_fill := StyleBoxFlat.new()
	bar_fill.bg_color = Color("d2b66e")
	progress_bar.add_theme_stylebox_override("fill", bar_fill)
	content.add_child(progress_bar)

	percent_label = _label("0%", 19, Color("d2b66e"))
	content.add_child(percent_label)

	var tip := _label("ไหว้ศาลและช่วยชาวบ้านระหว่างการเดินทาง", 15, Color("c4c8b7"))
	tip.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(tip)

	back_button = Button.new()
	back_button.text = "กลับเมนูหลัก"
	back_button.custom_minimum_size = Vector2(210, 42)
	back_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	back_button.add_theme_font_override("font", pixel_font)
	back_button.add_theme_font_size_override("font_size", 17)
	back_button.add_theme_color_override("font_color", Color("fff1c5"))
	var button_style := StyleBoxFlat.new()
	button_style.bg_color = Color("425b37")
	button_style.border_color = Color("d2b66e")
	button_style.set_border_width_all(2)
	back_button.add_theme_stylebox_override("normal", button_style)
	back_button.pressed.connect(_return_to_menu)
	back_button.hide()
	content.add_child(back_button)


func _label(caption: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = caption
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_override("font", pixel_font)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label


func _layout() -> void:
	var viewport_size := get_viewport().get_visible_rect().size
	var card_size := Vector2(minf(550.0, viewport_size.x - 32.0), minf(350.0, viewport_size.y * 0.54))
	card.size = card_size
	card.position = (viewport_size - card_size) * 0.5 + Vector2(0.0, 65.0)
	var logo_size := Vector2(minf(420.0, viewport_size.x - 48.0), minf(145.0, viewport_size.y * 0.21))
	logo.size = logo_size
	logo.position = Vector2((viewport_size.x - logo_size.x) * 0.5, card.position.y - logo_size.y - 20.0)


func _begin_loading() -> void:
	await get_tree().process_frame
	status_label.text = "กำลังโหลดแผนที่และทรัพยากร..."
	if OS.has_feature("web"):
		# Single-threaded Web exports cannot reliably complete threaded resource requests.
		await get_tree().process_frame
		var web_scene := load(GAME_SCENE) as PackedScene
		if web_scene == null:
			_show_error(ERR_CANT_OPEN)
			return
		_finish_loaded_scene(web_scene)
		return
	var result := ResourceLoader.load_threaded_request(GAME_SCENE)
	if result != OK:
		_show_error(result)
		return
	set_process(true)


func _process(_delta: float) -> void:
	var progress: Array = []
	var status := ResourceLoader.load_threaded_get_status(GAME_SCENE, progress)
	if not progress.is_empty():
		var percent := clampf(float(progress[0]) * 100.0, 0.0, 100.0)
		progress_bar.value = percent
		percent_label.text = "%d%%" % int(roundf(percent))
	match status:
		ResourceLoader.THREAD_LOAD_LOADED:
			set_process(false)
			_finish_loading()
		ResourceLoader.THREAD_LOAD_FAILED, ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
			_show_error(ERR_CANT_OPEN)


func _finish_loading() -> void:
	var game_scene := ResourceLoader.load_threaded_get(GAME_SCENE) as PackedScene
	if game_scene == null:
		_show_error(ERR_CANT_OPEN)
		return
	_finish_loaded_scene(game_scene)


func _finish_loaded_scene(game_scene: PackedScene) -> void:
	progress_bar.value = 100.0
	percent_label.text = "100%"
	status_label.text = "กำลังเข้าสู่เกม..."
	await get_tree().create_timer(0.12).timeout
	var game := game_scene.instantiate()
	if game == null:
		_show_error(ERR_CANT_CREATE)
		return
	game.set("stage", selected_stage)
	# Keep this canvas layer visible while the game builds its first map in _ready().
	get_tree().root.add_child(game)
	get_tree().current_scene = game
	queue_free()


func _show_error(code: Error) -> void:
	set_process(false)
	push_error("Could not load %s (error %d)" % [GAME_SCENE, code])
	status_label.text = "โหลดเกมไม่สำเร็จ กรุณากลับเมนูหลัก"
	back_button.show()


func _return_to_menu() -> void:
	get_tree().change_scene_to_file("res://MainMenu.tscn")
