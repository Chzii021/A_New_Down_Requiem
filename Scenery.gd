extends Node3D

@export_range(1, 4) var map_id = 1
@export var baked_scene = false

# Tree Collection by NicolasBrueckner (CC BY 3.0). See CREDITS.md.
const TREE_SCENES = [
	preload("res://models/trees/SimpleTree.tscn"),
	preload("res://models/trees/StylizedTree.tscn"),
	preload("res://models/trees/BirchTree.tscn"),
	preload("res://models/trees/PineTree.tscn")
]
const TREE_CENTERS = [-2.25073, -3.81709, -0.80423, 2.01726]
const TREE_HEIGHTS = [1.838065, 1.511019, 2.029097, 1.984891]
const MAP_LAYOUT = preload("res://MapLayout.gd")
var random = RandomNumberGenerator.new()


func _ready() -> void:
	if baked_scene:
		return
	random.seed = 91347 + map_id * 151
	_lighting()
	_terrain()
	_mountains()
	_road()
	var fields = []
	match map_id:
		1:
			fields = [Vector4(-14.0, 8.0, 9.0, 17.0), Vector4(14.0, 8.0, 9.0, 17.0), Vector4(-44.0, -30.0, 11.0, 28.0), Vector4(44.0, -30.0, 11.0, 28.0)]
		2:
			fields = [Vector4(-55.0, -32.0, 11.0, 30.0), Vector4(55.0, -42.0, 11.0, 30.0)]
		3:
			fields = [Vector4(-14.0, 9.0, 8.0, 16.0), Vector4(14.0, 9.0, 8.0, 16.0), Vector4(-64.0, -50.0, 10.0, 30.0), Vector4(64.0, -60.0, 10.0, 30.0)]
	for field in fields:
		_rice_field(field)
	_woodland()
	_verges()
	if map_id != 4:
		_village_details()


func _material(color: Color) -> StandardMaterial3D:
	var m = StandardMaterial3D.new()
	m.albedo_color = color.srgb_to_linear()
	m.roughness = 0.94
	return m


func _wind_material(color: Color, root_y: float) -> ShaderMaterial:
	var shader = Shader.new()
	shader.code = """shader_type spatial;
render_mode cull_disabled;
uniform vec4 plant_color : source_color;
uniform float root_height = 0.0;
void vertex() {
    float height = max(VERTEX.y - root_height, 0.0);
    float wind = sin(TIME * 1.65 + MODEL_MATRIX[3].x * 0.55 + MODEL_MATRIX[3].z * 0.26);
    VERTEX.x += wind * height * 0.14;
}
void fragment() { ALBEDO = plant_color.rgb; ROUGHNESS = 0.96; }
"""
	var material = ShaderMaterial.new()
	material.shader = shader
	material.set_shader_parameter("plant_color",color.srgb_to_linear())
	material.set_shader_parameter("root_height",root_y)
	return material


func _box(pos: Vector3, size: Vector3, color: Color) -> MeshInstance3D:
	var node = MeshInstance3D.new()
	var mesh = BoxMesh.new()
	mesh.size = size
	node.mesh = mesh
	node.material_override = _material(color)
	node.position = pos
	add_child(node)
	return node


func _lighting() -> void:
	var sky_tops = [Color("78b8e4"), Color("469fd5"), Color("34446d"), Color("0a152b")]
	var horizons = [Color("f5dbb0"), Color("d6e9de"), Color("df876e"), Color("314664")]
	var ambients = [Color("d7d7bd"), Color("c5d7d1"), Color("95829a"), Color("7387ae")]
	var sun_colors = [Color("ffdfae"), Color("fff2d0"), Color("ffc28c"), Color("9ebae4")]
	var sun_energy = [0.91, 1.12, 0.62, 0.28]
	var index = map_id - 1
	var sky_material = ProceduralSkyMaterial.new()
	sky_material.sky_top_color = sky_tops[index]
	sky_material.sky_horizon_color = horizons[index]
	sky_material.sky_curve = 0.20
	sky_material.ground_bottom_color = Color("566958") if map_id < 4 else Color("152238")
	sky_material.ground_horizon_color = horizons[index].darkened(0.35)
	sky_material.sun_angle_max = 4.0
	sky_material.sun_curve = 0.12
	var sky = Sky.new()
	sky.sky_material = sky_material
	var env = Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = ambients[index]
	env.ambient_light_energy = 0.38 if map_id < 4 else 0.24
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.fog_enabled = true
	env.fog_light_color = horizons[index]
	env.fog_light_energy = 0.7
	env.fog_density = 0.0032 if map_id < 4 else 0.006
	env.fog_sky_affect = 0.10
	var world = WorldEnvironment.new()
	world.environment = env
	add_child(world)
	var sun = DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-42.0 if map_id == 2 else (-12.0 if map_id == 3 else -24.0), -32.0, 0.0)
	sun.light_color = sun_colors[index]
	sun.light_energy = sun_energy[index]
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 95.0
	sun.shadow_bias = 0.045
	add_child(sun)
	# Soft, distant cloud banks add depth without a sky texture dependency.
	var cloud_mat = _material(Color("7b91ae") if map_id == 4 else (Color("eeb8a0") if map_id == 3 else Color("efddc1")))
	cloud_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	for i in range(18):
		var cloud = MeshInstance3D.new()
		var mesh = SphereMesh.new()
		mesh.radial_segments = 10
		mesh.rings = 4
		cloud.mesh = mesh
		cloud.material_override = cloud_mat
		cloud.position = Vector3(-105.0 + i * 13.0, 40.0 + sin(i * 1.8) * 5.0, -165.0 - (i % 3) * 20.0)
		cloud.scale = Vector3(18.0 + (i % 4) * 5.0, 2.0 + (i % 3), 7.0)
		add_child(cloud)


func _triangle(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, color: Color) -> void:
	st.set_color(color.srgb_to_linear())
	st.add_vertex(a)
	st.set_color(color.srgb_to_linear())
	st.add_vertex(b)
	st.set_color(color.srgb_to_linear())
	st.add_vertex(c)


func _surface(st: SurfaceTool) -> MeshInstance3D:
	st.generate_normals()
	var node = MeshInstance3D.new()
	node.mesh = st.commit()
	var material = _material(Color.WHITE)
	material.vertex_color_use_as_albedo = true
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	node.material_override = material
	add_child(node)
	return node


func _terrain() -> void:
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for x in range(-140, 140, 8):
		for z in range(-190, 95, 8):
			var base = Color("667c46").darkened(random.randf_range(0.0, 0.10))
			var a = Vector3(x, -0.03, z)
			var b = a + Vector3(8, 0, 0)
			var c = a + Vector3(8, 0, 8)
			var d = a + Vector3(0, 0, 8)
			_triangle(st, a, c, b, base)
			_triangle(st, a, d, c, base.lightened(0.015))
	_surface(st)


func _mountains() -> void:
	for layer in range(3):
		var st = SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		var z = -165.0 + layer * 23.0
		var base = [Color("859fa3"), Color("6e8b88"), Color("597974")][layer]
		for i in range(16):
			var x = -160.0 + i * 22.0
			var height = random.randf_range(13.0, 31.0) - layer * 2.0
			var peak = Vector3(x + 9.0, height, z - 7.0)
			_triangle(st, Vector3(x - 15, -2, z + 10), Vector3(x + 13, -2, z + 18), peak, base)
			_triangle(st, peak, Vector3(x + 13, -2, z + 18), Vector3(x + 38, -2, z + 10), base.darkened(0.065))
		_surface(st)


func _road() -> void:
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var road_colors = [Color("ad7954"), Color("b48b60"), Color("916750"), Color("69717b")]
	var roads = MAP_LAYOUT.routes(map_id)
	for segment_index in range(roads.size()):
		var segment = roads[segment_index]
		var start: Vector2 = segment[0]
		var end: Vector2 = segment[1]
		var direction = (end - start).normalized()
		var sideways = Vector2(-direction.y, direction.x) * 3.0
		var road_y = .006 + float(segment_index) * .00005
		var pieces = maxi(1, ceili(start.distance_to(end) / 2.0))
		for index in range(pieces):
			var a = start.lerp(end, float(index) / float(pieces))
			var b = start.lerp(end, float(index + 1) / float(pieces))
			var left_a = Vector3(a.x + sideways.x, road_y, a.y + sideways.y)
			var right_a = Vector3(a.x - sideways.x, road_y, a.y - sideways.y)
			var left_b = Vector3(b.x + sideways.x, road_y, b.y + sideways.y)
			var right_b = Vector3(b.x - sideways.x, road_y, b.y - sideways.y)
			var color = road_colors[map_id - 1].lightened(random.randf_range(0.0, .045))
			_triangle(st, left_a, left_b, right_b, color)
			_triangle(st, left_a, right_b, right_a, color)
	_surface(st)
	var mesh = SphereMesh.new()
	mesh.radial_segments = 5
	mesh.rings = 2
	var transforms: Array[Transform3D] = []
	for index in range(280):
		var segment = roads[index % roads.size()]
		var start: Vector2 = segment[0]
		var end: Vector2 = segment[1]
		var direction = (end - start).normalized()
		var sideways = Vector2(-direction.y, direction.x)
		var edge = start.lerp(end, random.randf()) + sideways * (random.randf_range(3.2, 4.4) * (-1.0 if index % 2 else 1.0))
		var size = random.randf_range(.07, .20)
		transforms.append(Transform3D(Basis().scaled(Vector3(size, size * .5, size)), Vector3(edge.x, .02, edge.y)))
	_instances(mesh, _material(Color("8b8670")), transforms)


func _instances(mesh: Mesh, material: Material, transforms: Array[Transform3D]) -> void:
	var mm = MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = mesh
	mm.instance_count = transforms.size()
	for i in range(transforms.size()):
		mm.set_instance_transform(i, transforms[i])
	var node = MultiMeshInstance3D.new()
	node.multimesh = mm
	node.material_override = material
	add_child(node)


func _rice_field(field: Vector4) -> void:
	var x = field.x
	var z = field.y
	var width = field.z
	var length = field.w
	_box(Vector3(x, -0.015, z), Vector3(width, 0.028, length), Color("58654d"))
	for side in [-1.0, 1.0]:
		_box(Vector3(x + side * width * 0.5, 0.06, z), Vector3(0.38, 0.15, length), Color("718047"))
		_box(Vector3(x, 0.06, z + side * length * 0.5), Vector3(width, 0.15, 0.36), Color("718047"))
	var mesh = CylinderMesh.new()
	mesh.top_radius = 0.008
	mesh.bottom_radius = 0.045
	mesh.height = 0.62
	mesh.radial_segments = 3
	var transforms: Array[Transform3D] = []
	for row in range(int(width / 0.42)):
		for col in range(int(length / 0.45)):
			var point = Vector3(x - width * 0.47 + row * 0.42, 0.25, z - length * 0.47 + col * 0.45)
			point.x += random.randf_range(-0.08, 0.08)
			point.z += random.randf_range(-0.08, 0.08)
			var basis = Basis(Vector3.FORWARD, random.randf_range(-0.2, 0.2)).scaled(Vector3(1, random.randf_range(0.7, 1.2), 1))
			transforms.append(Transform3D(basis, point))
	_instances(mesh, _wind_material(Color("b8b25b"), -0.31), transforms)
	# A narrow irrigation channel follows the paddy bund.
	_box(Vector3(x - width * 0.5 - 0.6, 0.002, z), Vector3(0.75, 0.03, length), Color("60847e"))


func _tree(place: Vector3, kind: int, height: float, solid: bool = true) -> void:
	var root = Node3D.new()
	root.name = ["SimpleTree", "StylizedTree", "BirchTree", "PineTree"][kind]
	root.position = place
	root.rotation.y = random.randf_range(-PI, PI)
	add_child(root)
	var tree = TREE_SCENES[kind].instantiate()
	var factor = height / TREE_HEIGHTS[kind]
	tree.scale = Vector3.ONE * factor
	tree.position.x = -TREE_CENTERS[kind] * factor
	if kind == 3:
		tree.position.y = -0.0036 * factor
	root.add_child(tree)
	for child in tree.find_children("*", "MeshInstance3D", true, false):
		for surface in range(child.mesh.get_surface_count()):
			var source = child.mesh.surface_get_material(surface)
			if source is StandardMaterial3D:
				var tint = source.duplicate()
				tint.albedo_color = Color(0.70, 0.73, 0.63)
				child.set_surface_override_material(surface, tint)
	if solid:
		var body = StaticBody3D.new()
		var shape = CollisionShape3D.new()
		var cylinder = CylinderShape3D.new()
		cylinder.radius = height * 0.045
		cylinder.height = height * 0.55
		shape.shape = cylinder
		shape.position.y = cylinder.height * 0.5
		body.add_child(shape)
		root.add_child(body)


func _woodland() -> void:
	# Keep the branching paths open; denser tree lines frame each larger level.
	for place in [Vector3(-6.8,0,17), Vector3(7.8,0,12), Vector3(-7,0,-1), Vector3(7.5,0,-9), Vector3(-7.1,0,-23), Vector3(8,0,-31), Vector3(-7.3,0,-48), Vector3(8.5,0,-47), Vector3(-9,0,-70), Vector3(9,0,-71)]:
		if MAP_LAYOUT.road_distance(Vector2(place.x, place.z), map_id) > 5.0:
			_tree(place, random.randi_range(0,1), random.randf_range(5.5,7.8))
	var border = MAP_LAYOUT.limits(map_id)
	for side in [-1.0, 1.0]:
		for i in range(28):
			var place = Vector3(side * random.randf_range(18, border.x + 8), 0, random.randf_range(-border.y - 3, 24))
			if MAP_LAYOUT.road_distance(Vector2(place.x, place.z), map_id) > 5.5:
				_tree(place, i % 3, random.randf_range(6.5, 10.5), false)
		for i in range(16):
			_tree(Vector3(side * random.randf_range(border.x + 9, border.x + 24), 0, random.randf_range(-border.y - 14, 26)), 3, random.randf_range(8, 12), false)
	for i in range(20):
		_tree(Vector3(random.randf_range(-border.x - 15, border.x + 15), 0, random.randf_range(-border.y - 28, -border.y - 16)), i % 3, random.randf_range(8, 12), false)


func _verges() -> void:
	var grass = SurfaceTool.new()
	grass.begin(Mesh.PRIMITIVE_TRIANGLES)
	for angle in [0.0, 1.05, 2.10]:
		var direction = Vector3(cos(angle),0,sin(angle))
		_triangle(grass, direction * -0.10, Vector3(0.05,0.29,0), direction * 0.10, Color.WHITE)
	grass.generate_normals()
	var transforms: Array[Transform3D] = []
	var roads = MAP_LAYOUT.routes(map_id)
	for i in range(1800):
		var segment = roads[i % roads.size()]
		var start: Vector2 = segment[0]
		var end: Vector2 = segment[1]
		var direction = (end - start).normalized()
		var sideways = Vector2(-direction.y, direction.x)
		var offset = random.randf_range(3.8, 6.2) * (-1.0 if i % 2 else 1.0)
		var spot = start.lerp(end, random.randf()) + sideways * offset
		var point = Vector3(spot.x, 0, spot.y)
		transforms.append(Transform3D(Basis(Vector3.UP,random.randf()*TAU).scaled(Vector3.ONE*random.randf_range(0.5,1.2)),point))
	var material = _wind_material(Color("5e6f67") if map_id == 4 else Color("758743"), 0.0)
	_instances(grass.commit(), material, transforms)


func _fence(x: float, z: float, length: float) -> void:
	for i in range(int(length / 1.5) + 1):
		_box(Vector3(x,0.50,z+i*1.5),Vector3(0.09,1.0,0.09),Color("82704c"))
	for y in [0.36,0.76]:
		_box(Vector3(x,y,z+length*0.5),Vector3(0.06,0.065,length),Color("a38a58"))


func _village_details() -> void:
	var border = MAP_LAYOUT.limits(map_id)
	for side in [-1.0,1.0]:
		_fence(side * 7.2,-4.0,10.0)
		_fence(side * (border.x - 4.0),-border.y * .72,22.0)
	# Small front-yard paths connect the raised wooden houses to the main road.
	for point in [Vector3(-6.2,0.015,6),Vector3(6.2,0.015,0),Vector3(-6.2,0.015,-14),Vector3(6.2,0.015,-22),Vector3(-6.5,0.015,-43)]:
		_box(point,Vector3(5.4,0.015,1.15),Color("9e8059"))
	# Straw stacks beside the paddy fields.
	for point in [Vector3(-20,0,15),Vector3(20,0,-23),Vector3(-20,0,-62)]:
		var node = MeshInstance3D.new()
		var mesh = CylinderMesh.new()
		mesh.top_radius = 0.25
		mesh.bottom_radius = 1.05
		mesh.height = 1.55
		mesh.radial_segments = 10
		node.mesh = mesh
		node.material_override = _material(Color("ac9457"))
		node.position = point + Vector3(0,0.77,0)
		add_child(node)
		_box(point+Vector3(0,1.65,0),Vector3(0.09,0.55,0.09),Color("665139"))
