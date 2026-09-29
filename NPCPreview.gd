extends Node3D

var villagers = []
var elapsed = 0.0
var demo_effects = false
var demo_phase = 0
var caption: Label

func _ready() -> void:
	var world=WorldEnvironment.new()
	var environment=Environment.new()
	environment.background_mode=Environment.BG_COLOR
	environment.background_color=Color("e4d9c5")
	environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color=Color("ece6db")
	environment.ambient_light_energy=.4
	world.environment=environment
	add_child(world)
	var light=DirectionalLight3D.new()
	light.rotation_degrees=Vector3(-32,145,0)
	light.light_energy=.68
	light.shadow_enabled=true
	add_child(light)
	var floor_mesh=MeshInstance3D.new()
	var plane=BoxMesh.new()
	plane.size=Vector3(16,.08,10)
	floor_mesh.mesh=plane
	floor_mesh.position.y=-.06
	var mat=StandardMaterial3D.new()
	mat.albedo_color=Color("b7aa91").srgb_to_linear()
	floor_mesh.material_override=mat
	add_child(floor_mesh)
	var scenes=[preload("res://models/npcs/Farmer.tscn"),preload("res://models/npcs/Vendor.tscn"),preload("res://models/npcs/Elder.tscn"),preload("res://models/npcs/YoungWoman.tscn")]
	for i in range(4):
		var npc=scenes[i].instantiate()
		npc.position=Vector3((1.5-i)*1.48,0,0)
		npc.rotation.y=-.14
		add_child(npc)
		villagers.append(npc)
	var camera=Camera3D.new()
	camera.position=Vector3(0,1.9,-5.4)
	camera.fov=40
	add_child(camera)
	camera.look_at(Vector3(0,1.08,0))
	var layer=CanvasLayer.new()
	add_child(layer)
	caption=Label.new()
	caption.position=Vector2(32,24)
	caption.add_theme_color_override("font_color",Color("293e44"))
	var font=preload("res://PixelFont.gd").make()
	caption.add_theme_font_override("font",font)
	caption.add_theme_font_size_override("font_size",23)
	caption.text="ชาวบ้านใต้เงาวิญญาณ  |  ชาวนา • แม่ค้า • ชายสูงวัย • หญิงสาว\n1–4 โดนยิง   •   Space ปลดปล่อยวิญญาณทั้งหมด   •   R เริ่มใหม่"
	layer.add_child(caption)
	for arg in OS.get_cmdline_user_args():
		if arg=="effects":
			demo_effects=true

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode>=KEY_1 and event.keycode<=KEY_4:
			villagers[event.keycode-KEY_1].receive_hit(4,5)
		elif event.keycode==KEY_SPACE:
			for npc in villagers:
				npc.release_spirit()
		elif event.keycode==KEY_R:
			get_tree().reload_current_scene()

func _process(delta: float) -> void:
	elapsed+=delta
	if demo_effects and elapsed>1.0 and demo_phase==0:
		demo_phase=1
		for npc in villagers:
			npc.receive_hit(4,5)
	if demo_effects and elapsed>2.2 and demo_phase==1:
		demo_phase=2
		for npc in villagers:
			npc.receive_hit(0,5)
			npc.release_spirit()
