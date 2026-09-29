extends Control

const MAX_MEDICINE := 5

var medicine_count := 0
var pixel_font: Font


func _ready() -> void:
	size = Vector2(108, 108)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	pixel_font = preload("res://PixelFont.gd").make()


func set_status(value: int) -> void:
	var next_count := clampi(value, 0, MAX_MEDICINE)
	if medicine_count == next_count:
		return
	medicine_count = next_count
	queue_redraw()


func _draw() -> void:
	var center := size * .5
	draw_circle(center, 50.0, Color("454545"))
	draw_arc(center, 49.0, 0.0, TAU, 64, Color("151515"), 4.0, true)
	draw_circle(center, 38.0, Color("2c2c2c"))
	draw_arc(center, 38.0, 0.0, TAU, 64, Color("888888"), 2.0, true)
	for index in range(MAX_MEDICINE):
		var begin := -PI * .5 + TAU * float(index) / MAX_MEDICINE + .06
		var end := -PI * .5 + TAU * float(index + 1) / MAX_MEDICINE - .06
		draw_arc(center, 44.0, begin, end, 12, Color("78d7a6") if index < medicine_count else Color("666666"), 6.0, true)
	# Cork, glass bottle and a small first-aid cross.
	draw_colored_polygon(PackedVector2Array([Vector2(43,27),Vector2(65,27),Vector2(63,34),Vector2(45,34)]), Color("bf9365"))
	draw_colored_polygon(PackedVector2Array([Vector2(46,34),Vector2(62,34),Vector2(62,40),Vector2(69,45),Vector2(69,72),Vector2(64,78),Vector2(44,78),Vector2(39,72),Vector2(39,45),Vector2(46,40)]), Color("a7d8da"))
	draw_colored_polygon(PackedVector2Array([Vector2(42,49),Vector2(66,49),Vector2(66,72),Vector2(63,75),Vector2(45,75),Vector2(42,72)]), Color("e65e70") if medicine_count > 0 else Color("806a71"))
	draw_rect(Rect2(51,53,6,18), Color("fff5df"))
	draw_rect(Rect2(45,59,18,6), Color("fff5df"))
	draw_string(pixel_font, Vector2(39,94), "E %d" % medicine_count, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 16, Color("ffffff"))
