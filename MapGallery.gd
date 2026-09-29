extends Node3D

const MAP_LAYOUT = preload("res://MapLayout.gd")
const MAP_SCENES = [
	preload("res://Map1Morning.tscn"),
	preload("res://Map2LateMorning.tscn"),
	preload("res://Map3Dusk.tscn"),
	preload("res://Map4Night.tscn")
]
const MAP_NAMES = ["หมู่บ้านทุ่งนา", "ตลาดและลานฝึก", "ศาลาริมนา", "ศาลท้ายหมู่บ้าน"]
const TIMES = ["เช้า", "สาย", "ใกล้ค่ำ", "ดึก"]

var current_map: Node3D
var camera: Camera3D
var caption: Label


func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	camera = Camera3D.new()
	camera.current = true
	camera.fov = 58.0
	camera.far = 400.0
	add_child(camera)
	var ui = CanvasLayer.new()
	add_child(ui)
	var band = ColorRect.new()
	band.color = Color(.18, .18, .18, .94)
	band.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	band.offset_top = -66
	band.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(band)
	caption = Label.new()
	caption.position = Vector2(24, 6)
	caption.size = Vector2(1100, 52)
	var font = preload("res://PixelFont.gd").make()
	caption.add_theme_font_override("font", font)
	caption.add_theme_font_size_override("font_size", 21)
	caption.add_theme_color_override("font_color", Color("f4f4f4"))
	band.add_child(caption)
	var requested = 1
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("map="):
			requested = clampi(int(arg.get_slice("=", 1)), 1, 4)
	show_map(requested)


func show_map(number: int) -> void:
	if current_map != null:
		remove_child(current_map)
		current_map.queue_free()
	current_map = MAP_SCENES[number - 1].instantiate()
	add_child(current_map)
	var factor = .78 if number == 4 else 1.0
	current_map.scale = Vector3.ONE * factor
	var boundary = MAP_LAYOUT.limits(number) * factor
	camera.position = Vector3(boundary.x * .72, boundary.y * .58, boundary.y * .54)
	camera.look_at(Vector3(0, 0, -boundary.y * .4))
	caption.text = "แผนที่ %d/4 • %s (%s)    กด 1–4 เพื่อเปลี่ยนแผนที่" % [number, MAP_NAMES[number - 1], TIMES[number - 1]]


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode >= KEY_1 and event.keycode <= KEY_4:
			show_map(event.keycode - KEY_1 + 1)
