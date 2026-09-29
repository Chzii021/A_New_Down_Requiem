extends Control

var bullets = false
var dash = false

func _ready() -> void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE

func _draw() -> void:
	if bullets:
		for i in range(3):
			var x=i*10.0+3.0
			draw_colored_polygon(PackedVector2Array([Vector2(x,25),Vector2(x,9),Vector2(x+3,1),Vector2(x+6,9),Vector2(x+6,25)]),Color("ffe1a5"))
			draw_line(Vector2(x,12),Vector2(x+6,12),Color("b86758"),2)
	elif dash:
		draw_line(Vector2(1,9),Vector2(9,9),Color("8ed9dd"),2.0)
		draw_line(Vector2(0,15),Vector2(7,15),Color("8ed9dd"),2.0)
		draw_line(Vector2(3,21),Vector2(8,21),Color("8ed9dd"),2.0)
		draw_colored_polygon(PackedVector2Array([Vector2(16,2),Vector2(28,2),Vector2(20,12),Vector2(27,12),Vector2(12,27),Vector2(16,17),Vector2(10,17)]),Color("a8f0ed"))
	else:
		draw_colored_polygon(PackedVector2Array([Vector2(3,9),Vector2(6,6),Vector2(11,6),Vector2(14,9),Vector2(17,6),Vector2(22,6),Vector2(25,9),Vector2(25,15),Vector2(14,27),Vector2(3,15)]),Color("ff6976"))
		draw_rect(Rect2(6,9,4,3),Color("ffb7a4"))
