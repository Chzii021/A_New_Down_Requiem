extends Control

const MAX_CHARGE = 15
const DURATION = 10.0

var charge = 0
var active = false
var unlimited = false
var time_left = 0.0


func _ready() -> void:
	size = Vector2(108, 108)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func set_status(value: int, is_active: bool, unlocked: bool, remaining: float, is_unlimited: bool) -> void:
	visible = unlocked
	if charge == value and active == is_active and unlimited == is_unlimited and absf(time_left - remaining) < .01:
		return
	charge = clampi(value, 0, MAX_CHARGE)
	active = is_active
	unlimited = is_unlimited
	time_left = clampf(remaining, 0.0, DURATION)
	queue_redraw()


func _draw() -> void:
	var center = size * .5
	draw_circle(center, 50.0, Color("454545"))
	draw_arc(center, 49.0, 0.0, TAU, 64, Color("151515"), 4.0, true)
	draw_circle(center, 38.0, Color("2c2c2c"))
	draw_arc(center, 38.0, 0.0, TAU, 64, Color("888888"), 2.0, true)
	for index in range(MAX_CHARGE):
		var begin = -PI * .5 + TAU * float(index) / MAX_CHARGE + .035
		var end = -PI * .5 + TAU * float(index + 1) / MAX_CHARGE - .035
		var lit = unlimited or (index < ceili(time_left / DURATION * MAX_CHARGE) if active else index < charge)
		var tint = Color("a777de") if active or charge == MAX_CHARGE or unlimited else Color("71c95c")
		draw_arc(center, 44.0, begin, end, 6, tint if lit else Color("666666"), 6.0, true)
	# A compact icon of the same curved spirit sickle used by the character.
	var steel = Color("4b5356") if active or charge == MAX_CHARGE or unlimited else Color("697477")
	var edge = Color("62e5dc") if active or charge == MAX_CHARGE or unlimited else Color("78bbb8")
	draw_line(Vector2(68, 44), Vector2(78, 62), Color("5d4133"), 9.0, true)
	draw_line(Vector2(70, 48), Vector2(74, 55), Color("a43a40"), 5.0, true)
	draw_line(Vector2(73, 54), Vector2(77, 60), Color("b84a4b"), 5.0, true)
	draw_colored_polygon(PackedVector2Array([Vector2(72,45),Vector2(66,33),Vector2(57,24),Vector2(47,21),Vector2(37,23),Vector2(29,30),Vector2(24,41),Vector2(23,49),Vector2(30,40),Vector2(39,34),Vector2(49,33),Vector2(59,37),Vector2(67,47)]), steel)
	draw_colored_polygon(PackedVector2Array([Vector2(67,47),Vector2(59,37),Vector2(49,33),Vector2(39,34),Vector2(30,40),Vector2(23,49),Vector2(31,43),Vector2(40,38),Vector2(49,37),Vector2(58,40),Vector2(64,49)]), edge)
	draw_line(Vector2(66,47), Vector2(72,45), Color("98363d"), 5.0, true)
