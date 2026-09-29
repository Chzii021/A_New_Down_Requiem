extends Node3D

var view_camera: Camera3D
var caption: Label
var views = [
	[Vector3(23,14,28), Vector3(-1,0,-13), "หมู่บ้านอีสานยามเย็น"],
	[Vector3(-1.4,3.5,18), Vector3(0,2.2,-19), "ถนนเข้าหมู่บ้าน • แนวต้นไม้และทุ่งนา"],
	[Vector3(15,9,-42), Vector3(0,2,-62), "ศาลท้ายหมู่บ้าน"]
]

func _ready() -> void:
	var game = preload("res://Main.tscn").instantiate()
	add_child(game)
	game.process_mode = Node.PROCESS_MODE_DISABLED
	for child in game.get_children():
		if child is CanvasLayer:
			child.hide()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	view_camera = Camera3D.new()
	view_camera.fov = 60
	view_camera.current = true
	add_child(view_camera)
	var ui = CanvasLayer.new()
	add_child(ui)
	var panel = ColorRect.new()
	panel.color = Color(.18, .18, .18, .94)
	panel.position = Vector2(22,615)
	panel.size = Vector2(650,80)
	ui.add_child(panel)
	caption = Label.new()
	caption.position = Vector2(40,626)
	var font = preload("res://PixelFont.gd").make()
	caption.add_theme_font_override("font",font)
	caption.add_theme_font_size_override("font_size",22)
	caption.add_theme_color_override("font_color",Color("f4f4f4"))
	ui.add_child(caption)
	_set_view(0)
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("view="):
			_set_view(clampi(int(arg.get_slice("=",1)),0,2))

func _set_view(index: int) -> void:
	view_camera.position = views[index][0]
	view_camera.look_at(views[index][1])
	caption.text = views[index][2] + "\n1–3 เปลี่ยนมุมมอง  |  Tree Collection • NicolasBrueckner"

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode >= KEY_1 and event.keycode <= KEY_3:
			_set_view(event.keycode - KEY_1)
