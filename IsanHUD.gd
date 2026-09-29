extends Control

signal restart_requested

var ammo_label: Label
var objective_label: Label
var prompt_label: Label
var message_label: Label
var mode_label: Label
var end_panel: Control
var end_heading: Label
var end_label: Label
var crosshair
var health_bar: ProgressBar
var target_label: Label
var rescued_label: Label
var damage_flash: Control
var quest: Control
var help: Control
var status: Control
var dash_panel: Control
var weapon: Control
var prompt_panel: Control
var help_hint: Label
var reserve_label: Label
var fire_mode_label: Label
var dash_bar: ProgressBar
var special_meter: Control
var medicine_meter: Control
var sound_settings: Control
var help_hint_panel: Control
var save_panel: Control
var save_label: Label
var restart_button: Button
var pixel_font: Font
var previous_prompt_text: String = ""

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	pixel_font=preload("res://PixelFont.gd").make()
	damage_flash=preload("res://DamageFlash.gd").new()
	add_child(damage_flash)
	quest=_panel(Vector2(360,196),Color("6cbd50"))
	_pixel_label(quest,"BAN KERD",Vector2(18,16),Vector2(320,27),24,Color("ffffff"))
	_label(quest,"สี่ช่วงเวลา • หมู่บ้านอีสาน",Vector2(18,45),Vector2(324,21),14,Color("d4d4d4"))
	objective_label=_label(quest,"",Vector2(18,69),Vector2(324,91),14,Color("f5f5f5"))
	rescued_label=_label(quest,"",Vector2(18,148),Vector2(324,21),13,Color("b3ec9f"))
	help_hint_panel=_panel(Vector2(205,36),Color("7a7a7a"))
	help_hint=_pixel_label(help_hint_panel,"H HELP  /  ESC SOUND",Vector2(12,10),Vector2(184,22),13,Color("ffffff"))
	save_panel=_panel(Vector2(130,36),Color("a270d5"))
	save_label=_pixel_label(save_panel,"SAVE 2/2",Vector2(11,10),Vector2(108,22),14,Color("ffffff"))
	help=_panel(Vector2(350,310),Color("a270d5"))
	_pixel_label(help,"CONTROLS",Vector2(16,15),Vector2(316,24),21,Color("ffffff"))
	_label(help,"WASD  เดิน     Shift  วิ่ง     Ctrl  Dash\nSpace  กระโดด     คลิกซ้าย  ยิง     คลิกขวา  เล็ง\nR  บรรจุ     E  ใช้ยา / เก็บของ / ไหว้ศาล\nยาเก็บอัตโนมัติเมื่อเดินเข้าใกล้ ฟื้นเลือด 50\nQ  สลับไหล่     V  FPS / TPS / สำรวจ\nB  ปืนลำแคน: ทีละนัด / ยิงรัว\nF  ใช้พลังเคียว 10 วิ เมื่อเต็ม 15 หน่วย\nP  เติมพลังเคียวทันทีเพื่อทดสอบ\nโหมดเคียว: Space กระโดด 12 ม. เล็งจุดหมาย+คลิกพุ่ง\nด่านบอส: พักพลัง 2 วิ; ช่วยครบ 35 คนใช้ไม่จำกัด\nEsc  ตั้งค่าเสียง     H  ซ่อนวิธีเล่น",Vector2(16,44),Vector2(320,194),13,Color("f1f1f1"))
	help.hide()
	quest.show()
	help_hint.show()
	status=_panel(Vector2(304,58),Color("ec6969"))
	status.show_weave=false
	status.queue_redraw()
	var heart=preload("res://HUDIcon.gd").new()
	heart.position=Vector2(12,16)
	heart.size=Vector2(30,28)
	status.add_child(heart)
	_pixel_label(status,"HP",Vector2(50,20),Vector2(58,23),18,Color("ffffff"))
	health_bar=ProgressBar.new()
	health_bar.position=Vector2(118,16)
	health_bar.show_percentage=false
	health_bar.add_theme_font_size_override("font_size",1)
	health_bar.mouse_filter=Control.MOUSE_FILTER_IGNORE
	var background=StyleBoxFlat.new()
	background.bg_color=Color("252525")
	background.border_color=Color("111111")
	background.set_border_width_all(2)
	var fill=StyleBoxFlat.new()
	fill.bg_color=Color("e6535c")
	health_bar.add_theme_stylebox_override("background",background)
	health_bar.add_theme_stylebox_override("fill",fill)
	status.add_child(health_bar)
	health_bar.size=Vector2(168,26)
	dash_panel=_panel(Vector2(304,58),Color("6dc9e4"))
	dash_panel.show_weave=false
	dash_panel.queue_redraw()
	var dash_icon=preload("res://HUDIcon.gd").new()
	dash_icon.dash=true
	dash_icon.position=Vector2(12,16)
	dash_icon.size=Vector2(30,28)
	dash_panel.add_child(dash_icon)
	_pixel_label(dash_panel,"DASH",Vector2(48,20),Vector2(67,23),17,Color("ffffff"))
	dash_bar=ProgressBar.new()
	dash_bar.min_value=0.0
	dash_bar.max_value=1.0
	dash_bar.step=0.001
	dash_bar.value=1.0
	dash_bar.show_percentage=false
	dash_bar.add_theme_font_size_override("font_size",1)
	dash_bar.mouse_filter=Control.MOUSE_FILTER_IGNORE
	var dash_background=StyleBoxFlat.new()
	dash_background.bg_color=Color("252525")
	dash_background.border_color=Color("111111")
	dash_background.set_border_width_all(2)
	var dash_fill=StyleBoxFlat.new()
	dash_fill.bg_color=Color("57bddd")
	dash_bar.add_theme_stylebox_override("background",dash_background)
	dash_bar.add_theme_stylebox_override("fill",dash_fill)
	dash_panel.add_child(dash_bar)
	dash_bar.position=Vector2(118,16)
	dash_bar.size=Vector2(168,26)
	weapon=_panel(Vector2(224,88),Color("e1bc6b"))
	var cartridges=preload("res://HUDIcon.gd").new()
	cartridges.bullets=true
	cartridges.position=Vector2(12,21)
	cartridges.size=Vector2(36,28)
	weapon.add_child(cartridges)
	_pixel_label(weapon,"AMMO",Vector2(56,13),Vector2(150,20),15,Color("ffffff"))
	ammo_label=_pixel_label(weapon,"",Vector2(53,34),Vector2(153,31),25,Color("ffffff"))
	ammo_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
	fire_mode_label=_label(weapon,"",Vector2(14,57),Vector2(195,17),12,Color("dfdfdf"))
	mode_label=_label(help,"",Vector2(16,250),Vector2(320,20),12,Color("d9c4f6"))
	reserve_label=_label(help,"",Vector2(16,272),Vector2(320,20),12,Color("efefef"))
	special_meter=preload("res://SpecialMeter.gd").new()
	add_child(special_meter)
	special_meter.visible=false
	medicine_meter=preload("res://MedicineMeter.gd").new()
	add_child(medicine_meter)
	message_label=Label.new()
	message_label.hide()
	add_child(message_label)
	prompt_panel=_panel(Vector2(370,42),Color("9cec81"),Color("3b9237"))
	prompt_label=_label(prompt_panel,"",Vector2(12,8),Vector2(346,28),16,Color("ffffff"))
	prompt_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	crosshair=preload("res://Crosshair.gd").new()
	add_child(crosshair)
	target_label=_label(self,"",Vector2.ZERO,Vector2(240,24),13,Color("ffffff"))
	target_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	end_panel=_panel(Vector2(560,230),Color("a270d5"))
	end_heading=_pixel_label(end_panel,"",Vector2(24,20),Vector2(512,36),28,Color("ffffff"))
	end_label=_label(end_panel,"",Vector2(24,66),Vector2(512,87),20,Color("eeeeee"))
	end_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	end_label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
	restart_button=Button.new()
	restart_button.text="RESTART"
	restart_button.position=Vector2(190,170)
	restart_button.size=Vector2(180,42)
	restart_button.mouse_filter=Control.MOUSE_FILTER_STOP
	restart_button.add_theme_font_override("font",pixel_font)
	restart_button.add_theme_font_size_override("font_size",19)
	restart_button.add_theme_color_override("font_color",Color("ffffff"))
	restart_button.add_theme_color_override("font_hover_color",Color("ffffff"))
	restart_button.add_theme_color_override("font_pressed_color",Color("ffffff"))
	var button_style=StyleBoxFlat.new()
	button_style.bg_color=Color("3b9a35")
	button_style.border_color=Color("191919")
	button_style.set_border_width_all(3)
	button_style.set_corner_radius_all(0)
	restart_button.add_theme_stylebox_override("normal",button_style)
	var hover_style=button_style.duplicate() as StyleBoxFlat
	hover_style.bg_color=Color("55b74b")
	restart_button.add_theme_stylebox_override("hover",hover_style)
	var pressed_style=button_style.duplicate() as StyleBoxFlat
	pressed_style.bg_color=Color("2b7228")
	restart_button.add_theme_stylebox_override("pressed",pressed_style)
	end_panel.add_child(restart_button)
	restart_button.pressed.connect(func(): restart_requested.emit())
	end_panel.hide()
	sound_settings=preload("res://SoundSettings.gd").new()
	add_child(sound_settings)
	sound_settings.hide()
	resized.connect(_layout)
	_layout()

func _panel(dimensions: Vector2, accent: Color = Color("71b958"), background: Color = Color("454545")) -> Control:
	var p=preload("res://WovenPanel.gd").new()
	p.size=dimensions
	p.accent_color=accent
	p.background_color=background
	add_child(p)
	return p

func _label(parent: Control, text_value: String, pos: Vector2, dimensions: Vector2, font_size: int, tint: Color = Color("e1e1cd")) -> Label:
	var l=Label.new()
	l.text=text_value
	l.position=pos
	l.size=dimensions
	l.mouse_filter=Control.MOUSE_FILTER_IGNORE
	l.add_theme_font_override("font",pixel_font)
	l.add_theme_font_size_override("font_size",font_size)
	l.add_theme_color_override("font_color",tint)
	l.add_theme_color_override("font_shadow_color",Color(0,0,0,.65))
	l.add_theme_constant_override("shadow_offset_y",1)
	parent.add_child(l)
	return l

func _pixel_label(parent: Control, text_value: String, pos: Vector2, dimensions: Vector2, font_size: int, tint: Color) -> Label:
	var label=_label(parent,text_value,pos,dimensions,font_size,tint)
	label.add_theme_font_override("font",pixel_font)
	return label

func _layout() -> void:
	if not is_instance_valid(quest):
		return
	quest.position=Vector2(20,20)
	help_hint_panel.position=Vector2(size.x-help_hint_panel.size.x-20,20)
	save_panel.position=Vector2(help_hint_panel.position.x-save_panel.size.x-8,20)
	help.position=Vector2(size.x-help.size.x-20,64)
	status.position=Vector2(20,size.y-status.size.y-20)
	dash_panel.position=Vector2(20,status.position.y-dash_panel.size.y-8)
	weapon.position=Vector2(size.x-weapon.size.x-20,size.y-weapon.size.y-20)
	prompt_panel.position=Vector2((size.x-prompt_panel.size.x)*.5,size.y-178)
	_fit_text_panel(prompt_panel,prompt_label,140.0,370.0)
	special_meter.position=Vector2((size.x-special_meter.size.x)*.5,size.y-125)
	medicine_meter.position=Vector2((size.x-medicine_meter.size.x)*.5+(118.0 if special_meter.visible else 0.0),size.y-125)
	target_label.position=size*.5+Vector2(-120,32)
	end_panel.position=(size-end_panel.size)*.5

func _process(_delta: float) -> void:
	medicine_meter.position.x=(size.x-medicine_meter.size.x)*.5+(118.0 if special_meter.visible else 0.0)
	if prompt_label.text != previous_prompt_text:
		previous_prompt_text=prompt_label.text
		_fit_text_panel(prompt_panel,prompt_label,140.0,370.0)
	prompt_panel.visible=not prompt_label.text.is_empty() and not end_panel.visible
	if not crosshair.visible:
		target_label.text=""

func _fit_text_panel(panel: Control, label: Label, minimum_width: float, maximum_width: float) -> void:
	var font: Font=label.get_theme_font("font")
	var text_width: float=font.get_string_size(label.text,HORIZONTAL_ALIGNMENT_LEFT,-1.0,label.get_theme_font_size("font_size")).x
	var padding: float=label.position.x
	var available_width: float=maxf(minimum_width,minf(maximum_width,size.x-32.0))
	var panel_width: float=clampf(ceilf(text_width+padding*2.0+16.0),minimum_width,available_width)
	panel.size=Vector2(panel_width,panel.size.y)
	label.size=Vector2(panel_width-padding*2.0,label.size.y)
	panel.position.x=(size.x-panel_width)*.5

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode==KEY_H:
		help.visible=not help.visible
		get_viewport().set_input_as_handled()
