extends Panel

@export var accent_color: Color = Color("71b958")
@export var background_color: Color = Color("454545")
@export var show_weave: bool = true

# Square bevels and hard highlights give the HUD a block-game look.
func _ready() -> void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	var style=StyleBoxFlat.new()
	style.bg_color=background_color
	style.border_color=Color("151515")
	style.set_border_width_all(3)
	style.set_corner_radius_all(0)
	style.shadow_color=Color(0,0,0,.55)
	style.shadow_size=5
	add_theme_stylebox_override("panel",style)
	resized.connect(queue_redraw)

func _draw() -> void:
	if size.x < 30 or size.y < 24:
		return
	draw_rect(Rect2(4, 4, size.x - 8, 2), Color("858585"))
	draw_rect(Rect2(4, 4, 2, size.y - 8), Color("858585"))
	draw_rect(Rect2(4, size.y - 6, size.x - 8, 2), Color("292929"))
	draw_rect(Rect2(size.x - 6, 4, 2, size.y - 8), Color("292929"))
	draw_rect(Rect2(10, 7, size.x - 20, 3), accent_color)
	if show_weave:
		draw_rect(Rect2(10, size.y - 11, size.x - 20, 2), Color("292929"))
