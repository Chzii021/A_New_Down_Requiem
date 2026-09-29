extends Node3D

const POSES := ["ยืนพร้อมปืน", "เดิน", "วิ่ง", "กระโดด", "ยิง", "วิ่งและยิง"]
var model: Node3D
var camera: Camera3D
var pose_label: Label
var elapsed := 0.0
var shot_timer := 0.0
var manual_pose := -1
var rifle_on := true
var range_mode := false
var target: Node3D


func _ready() -> void:
	var world := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("e7dcd0")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("f1e8df")
	environment.ambient_light_energy = 0.35
	world.environment = environment
	add_child(world)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-32.0, 145.0, 0.0)
	sun.light_energy = 0.65
	sun.shadow_enabled = true
	add_child(sun)
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-15.0, -50.0, 0.0)
	fill.light_color = Color("b8cbd9")
	fill.light_energy = 0.12
	add_child(fill)
	var ground := MeshInstance3D.new()
	var floor_mesh := BoxMesh.new()
	floor_mesh.size = Vector3(10.0, 0.08, 10.0)
	ground.mesh = floor_mesh
	ground.position.y = -0.05
	var floor_material := StandardMaterial3D.new()
	floor_material.albedo_color = Color("b5a996").srgb_to_linear()
	ground.material_override = floor_material
	add_child(ground)
	model = preload("res://Vikram.tscn").instantiate()
	model.rotation.y = 0.30
	add_child(model)
	model.call("set_rifle", rifle_on)
	camera = Camera3D.new()
	camera.position = Vector3(2.8, 1.7, -3.8)
	camera.fov = 35.0
	camera.current = true
	add_child(camera)
	camera.look_at(Vector3(0.0, 1.05, 0.0))
	var ui := CanvasLayer.new()
	add_child(ui)
	var font := preload("res://PixelFont.gd").make()
	pose_label = Label.new()
	pose_label.position = Vector2(32.0, 25.0)
	pose_label.add_theme_font_override("font", font)
	pose_label.add_theme_font_size_override("font_size", 26)
	pose_label.add_theme_color_override("font_color", Color("342b2a"))
	ui.add_child(pose_label)
	var help := Label.new()
	help.text = "1–6 เลือกท่า  |  7 ดูเอฟเฟกต์ยิงเป้า  |  Tab เปลี่ยนปืน  |  ← → หมุน  |  0 เล่นวน"
	help.position = Vector2(32.0, 66.0)
	help.add_theme_font_override("font", font)
	help.add_theme_font_size_override("font_size", 18)
	help.add_theme_color_override("font_color", Color("4d4240"))
	ui.add_child(help)
	_build_target()
	for arg in OS.get_cmdline_user_args():
		if arg == "range":
			_set_range(true)
		elif arg.begins_with("pose="):
			manual_pose = clampi(int(arg.get_slice("=", 1)), 0, 5)
		elif arg == "weapon=pistol":
			rifle_on = false
			model.call("set_rifle", false)
		elif arg.begins_with("angle="):
			model.rotation.y = float(arg.get_slice("=", 1))


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	if event.keycode >= KEY_1 and event.keycode <= KEY_6:
		_set_range(false)
		manual_pose = event.keycode - KEY_1
	elif event.keycode == KEY_7:
		_set_range(true)
	elif event.keycode == KEY_0:
		_set_range(false)
		manual_pose = -1
		elapsed = 0.0
	elif event.keycode == KEY_TAB:
		rifle_on = not rifle_on
		model.call("set_rifle", rifle_on)
	elif event.keycode == KEY_LEFT and not range_mode:
		model.rotation.y -= 0.25
	elif event.keycode == KEY_RIGHT and not range_mode:
		model.rotation.y += 0.25


func _process(delta: float) -> void:
	elapsed += delta
	var pose_index := manual_pose if manual_pose >= 0 else int(elapsed / 2.0) % POSES.size()
	pose_label.text = "วิกรม  |  ตัวละครหลัก  |  %s" % POSES[pose_index]
	if range_mode:
		pose_label.text = "วิกรม  |  แสงปากกระบอก • เส้นกระสุน • ปลอกกระสุน • ประกายกระทบ"
	var walking := pose_index == 1
	var running := pose_index == 2 or pose_index == 5
	var jumping := pose_index == 3
	model.call("set_motion", 7.4 if running else (5.2 if walking else 0.0), not jumping, running, 0.0)
	model.position.y = absf(sin(elapsed * 5.0)) * 0.27 if jumping else 0.0
	if pose_index == 4 or pose_index == 5:
		shot_timer -= delta
		if shot_timer <= 0.0:
			model.call("play_shot")
			var start: Vector3 = model.call("get_muzzle_position")
			var forward: Vector3 = -model.gun.global_basis.z
			if range_mode:
				# Intersect the visual ray with the front plane of the wooden target.
				var distance := (-2.445-start.z)/minf(forward.z,-.01)
				model.call("fire_trace",start+forward*distance,Vector3.BACK,true,false)
			else:
				model.call("fire_trace",start+forward*3.5,-forward,false,false)
			shot_timer = 0.45
	else:
		shot_timer = 0.0

func _set_range(enabled: bool) -> void:
	range_mode = enabled
	target.visible = enabled
	if enabled:
		manual_pose = 4
		model.rotation.y = 0.0
		camera.position = Vector3(5.2,2.1,-1.0)
		camera.fov = 43.0
		camera.look_at(Vector3(0,1.05,-1.05))
	else:
		model.rotation.y = .30
		camera.position = Vector3(2.8,1.7,-3.8)
		camera.fov = 35.0
		camera.look_at(Vector3(0,1.05,0))

func _build_target() -> void:
	target = Node3D.new()
	target.name = "WoodenTarget"
	add_child(target)
	for side in [-1.0,1.0]:
		var post = MeshInstance3D.new()
		var mesh = BoxMesh.new()
		mesh.size = Vector3(.09,1.5,.09)
		post.mesh = mesh
		post.position = Vector3(side*.29,.75,-2.55)
		var wood = StandardMaterial3D.new()
		wood.albedo_color = Color("79563b")
		post.material_override = wood
		target.add_child(post)
	for i in range(4):
		var disc = MeshInstance3D.new()
		var mesh = CylinderMesh.new()
		mesh.top_radius = .48-i*.105
		mesh.bottom_radius = mesh.top_radius
		mesh.height = .07 if i==0 else .005
		mesh.radial_segments = 24
		disc.mesh = mesh
		disc.rotation.x = PI*.5
		disc.position = Vector3(0,1.20,-2.50 if i==0 else -2.469+i*.006)
		var paint = StandardMaterial3D.new()
		paint.albedo_color = Color(["a78055","e0c9a1","985341","e0c9a1"][i])
		disc.material_override = paint
		target.add_child(disc)
	target.hide()
