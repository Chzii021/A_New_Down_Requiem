extends Control

var aiming = false
var movement = 0.0
var on_enemy = false
var obstructed = false
var kick = 0.0
var hit_time = 0.0
var gap = 9.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func set_state(is_aiming: bool, speed: float, enemy: bool, blocked: bool) -> void:
	aiming = is_aiming
	movement = clampf(speed/7.4,0.0,1.0)
	on_enemy = enemy
	obstructed = blocked

func shot() -> void:
	kick = minf(kick+7.0,15.0)

func hit() -> void:
	hit_time = .18

func _process(delta: float) -> void:
	kick = move_toward(kick,0.0,delta*38.0)
	hit_time = maxf(hit_time-delta,0.0)
	gap = lerpf(gap,(4.0 if aiming else 9.0)+movement*5.0+kick,1.0-exp(-delta*20.0))
	queue_redraw()

func _stroke(a: Vector2, b: Vector2, color: Color, width: float = 2.0) -> void:
	draw_line(a,b,Color(0.015,.025,.025,.8),width+2.0,true)
	draw_line(a,b,color,width,true)

func _draw() -> void:
	var center = size*.5
	var color = Color("ffbd72") if obstructed else (Color("8bf2ce") if on_enemy else Color("eefbf7"))
	draw_circle(center,3.1,Color(0.015,.025,.025,.85))
	draw_circle(center,1.5,color)
	for direction in [Vector2.LEFT,Vector2.RIGHT,Vector2.UP,Vector2.DOWN]:
		_stroke(center+direction*gap,center+direction*(gap+6.0),color)
	if obstructed:
		_stroke(center+Vector2(-4,23),center+Vector2(4,31),color)
		_stroke(center+Vector2(4,23),center+Vector2(-4,31),color)
	if hit_time>0:
		var hit_color = Color(1.0,.91,.65,hit_time/.18)
		for x in [-1.0,1.0]:
			for y in [-1.0,1.0]:
				_stroke(center+Vector2(x,y)*13.0,center+Vector2(x,y)*19.0,hit_color)
