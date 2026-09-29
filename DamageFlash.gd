extends Control

var intensity := 0.0


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func flash(damage: int) -> void:
	intensity = maxf(intensity, clampf(.58 + float(damage) * .026, 0.0, 1.0))
	queue_redraw()


func _process(delta: float) -> void:
	if intensity <= 0.0:
		return
	intensity = maxf(intensity - delta * 1.7, 0.0)
	queue_redraw()


func _draw() -> void:
	if intensity <= 0.0:
		return
	var width := size.x
	var height := size.y
	var edge := minf(width, height) * .08
	draw_rect(Rect2(Vector2.ZERO, size), Color(.73, .06, .11, .10 * intensity))
	for layer in range(4):
		var inset := edge * float(layer) * .18
		var thickness := edge * .24
		var tint := Color(.89, .06, .13, (.22 - float(layer) * .035) * intensity)
		draw_rect(Rect2(inset, inset, width - inset * 2.0, thickness), tint)
		draw_rect(Rect2(inset, height - inset - thickness, width - inset * 2.0, thickness), tint)
		draw_rect(Rect2(inset, inset, thickness, height - inset * 2.0), tint)
		draw_rect(Rect2(width - inset - thickness, inset, thickness, height - inset * 2.0), tint)
