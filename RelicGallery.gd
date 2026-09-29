extends Node3D

const RELICS = preload("res://RelicWeapons.gd")
var turntables: Array[Node3D] = []

func _ready() -> void:
	var world := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("ddd4c0")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("d8e2dd")
	environment.ambient_light_energy = .7
	world.environment = environment
	add_child(world)
	var sunlight := DirectionalLight3D.new()
	sunlight.rotation_degrees = Vector3(-42, -30, 0)
	sunlight.light_energy = 1.5
	add_child(sunlight)
	var camera := Camera3D.new()
	camera.position = Vector3(0, 3.0, 8.2)
	add_child(camera)
	camera.look_at(Vector3(0, 1.45, 0))
	camera.fov = 50.0
	camera.current = true
	_box(self, "Backdrop", Vector3(0, -.18, 0), Vector3(11.0, .22, 5.0), Color("e7dbc3"))
	_display_weapon(-2.35, false)
	_display_weapon(2.35, true)
	var short_x = [-3.35, -2.35, -1.35]
	for i in range(3):
		_display_component(Vector3(short_x[i], .65, .95), false, i)
	var rapid_x = [.75, 1.55, 2.35, 3.15, 3.95]
	for i in range(5):
		_display_component(Vector3(rapid_x[i], .65, .95), true, i)
	_label("ปืนสั้นกระติบ • 3 ชิ้น", Vector3(-2.35, 3.25, 0))
	_label("ปืนลำแคนยิงรัว • 5 ชิ้น", Vector3(2.35, 3.25, 0))

func _display_weapon(x: float, rapid: bool) -> void:
	_box(self, "DisplayPlinth", Vector3(x, .2, -.35), Vector3(3.45, .35, 1.65), Color("75543b"))
	var turntable := Node3D.new()
	turntable.position = Vector3(x, 1.82, -.35)
	turntable.rotation.y = -.45
	turntable.scale = Vector3.ONE * (3.0 if rapid else 3.8)
	add_child(turntable)
	for i in range(5 if rapid else 3):
		if rapid:
			RELICS.rapid_component(turntable, i)
		else:
			RELICS.short_component(turntable, i)
	turntables.append(turntable)

func _display_component(place: Vector3, rapid: bool, index: int) -> void:
	_box(self, "PartTray", Vector3(place.x, .08, place.z), Vector3(.68, .12, .78), Color("b59770"))
	var model := Node3D.new()
	model.position = place
	model.scale = Vector3.ONE * (1.35 if rapid else 1.5)
	add_child(model)
	var component: Node3D = RELICS.rapid_component(model, index) if rapid else RELICS.short_component(model, index)
	component.position = Vector3(0, 0, .12 if rapid and index == 4 else 0)
	turntables.append(model)

func _box(parent: Node3D, label: String, place: Vector3, dimensions: Vector3, color: Color) -> void:
	var mesh := BoxMesh.new()
	mesh.size = dimensions
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	var piece := MeshInstance3D.new()
	piece.name = label
	piece.mesh = mesh
	piece.material_override = material
	piece.position = place
	parent.add_child(piece)

func _label(content: String, place: Vector3) -> void:
	var label := Label3D.new()
	label.text = content
	label.position = place
	label.font_size = 42
	label.pixel_size = .0035
	label.modulate = Color("1c3037")
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	var typeface := preload("res://PixelFont.gd").make()
	label.font = typeface
	add_child(label)

func _process(delta: float) -> void:
	for model in turntables:
		model.rotation.y += delta * .25
