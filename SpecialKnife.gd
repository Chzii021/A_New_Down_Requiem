extends Node3D

# Spirit sickle: faceted charcoal crescent, cyan cutting edge, wood and red cloth.
@export var upright_view := false
var slash_time := 0.0

func _ready() -> void:
	var timber := _material(Color("51392d"), .0)
	var timber_light := _material(Color("73513a"), .0)
	var red := _material(Color("9d3338"), .0)
	var red_light := _material(Color("c54c4b"), .0)
	var metal := _material(Color("40464a"), .05)
	var iron := _material(Color("2c3338"), .0)
	var cyan := _material(Color("51dbd2"), .55)
	_cylinder("CarvedWoodHandle", Vector3(0, .035, 0), .047, .43, timber)
	_cylinder("WoodenPommel", Vector3(0, -.183, 0), .055, .055, timber_light)
	_cylinder("SteelCollar", Vector3(0, .243, 0), .053, .05, iron)
	for index in range(6):
		var wrap := _cylinder("RedClothWrap%02d" % index, Vector3(0, -.105 + index * .047, 0), .052, .025, red if index % 2 == 0 else red_light)
		wrap.rotation.z = .07 if index % 2 == 0 else -.08
	_cylinder("HeadBinding", Vector3(0, .275, 0), .057, .045, red)
	# Two short cloth tails hang below the sickle head.
	_ribbon("RedTasselLeft", [Vector3(-.028, .274, -.045), Vector3(-.075, .07, -.047), Vector3(-.095, .025, -.047)], [Vector3(-.005, .274, -.045), Vector3(-.028, .07, -.047), Vector3(-.039, .055, -.047)], .004, red)
	_ribbon("RedTasselRight", [Vector3(.003, .267, -.051), Vector3(.045, .10, -.051), Vector3(.053, .075, -.051)], [Vector3(.026, .267, -.051), Vector3(.083, .12, -.051), Vector3(.087, .095, -.051)], .004, red_light)
	# The camera view uses an upright blade that leans forward slightly.
	var outer: Array = []
	var inner: Array = []
	if upright_view:
		outer = [Vector3(.04, .297, -.01), Vector3(.12, .43, -.01), Vector3(.20, .59, -.015), Vector3(.25, .76, -.022), Vector3(.27, .93, -.028), Vector3(.24, 1.09, -.032), Vector3(.11, 1.23, -.035)]
		inner = [Vector3(-.02, .300, -.01), Vector3(.00, .43, -.01), Vector3(.03, .59, -.015), Vector3(.06, .76, -.022), Vector3(.08, .93, -.028), Vector3(.09, 1.09, -.032), Vector3(.11, 1.23, -.035)]
	else:
		outer = [Vector3(.01, .297, -.01), Vector3(-.105, .455, -.01), Vector3(-.26, .576, -.015), Vector3(-.43, .624, -.022), Vector3(-.59, .586, -.028), Vector3(-.725, .482, -.032), Vector3(-.815, .320, -.035)]
		inner = [Vector3(-.015, .300, -.01), Vector3(-.145, .374, -.01), Vector3(-.29, .458, -.015), Vector3(-.445, .471, -.022), Vector3(-.590, .430, -.028), Vector3(-.725, .360, -.032), Vector3(-.815, .320, -.035)]
	var band := []
	for index in range(inner.size()):
		band.append(inner[index].lerp(outer[index], .22))
	_ribbon("FacetedIronCrescent", outer, band, .028, metal)
	_ribbon("SpiritEdge", band, inner, .031, cyan)
	_cylinder("BladeTang", Vector3(.01 if upright_view else -.03, .317, -.01), .048, .115, iron).rotation.z = -.10 if upright_view else -.55
	visible = false

func _material(tint: Color, glow: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = tint
	material.metallic = .55 if glow > 0.0 else .10
	material.roughness = .43 if glow > 0.0 else .82
	if glow > 0.0:
		material.emission_enabled = true
		material.emission = tint
		material.emission_energy_multiplier = glow
	return material

func _cylinder(label: String, center: Vector3, radius: float, height: float, material: Material) -> MeshInstance3D:
	var shape := CylinderMesh.new()
	shape.top_radius = radius * .94
	shape.bottom_radius = radius
	shape.height = height
	shape.radial_segments = 7
	var piece := MeshInstance3D.new()
	piece.name = label
	piece.mesh = shape
	piece.material_override = material
	piece.position = center
	add_child(piece)
	return piece

func _triangle(tool: SurfaceTool, a: Vector3, b: Vector3, c: Vector3) -> void:
	tool.add_vertex(a)
	tool.add_vertex(b)
	tool.add_vertex(c)

func _ribbon(label: String, outer: Array, inner: Array, thickness: float, material: Material) -> void:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for index in range(outer.size() - 1):
		var a: Vector3 = outer[index]
		var b: Vector3 = outer[index + 1]
		var c: Vector3 = inner[index]
		var d: Vector3 = inner[index + 1]
		var front := Vector3(0, 0, thickness * .5)
		var back := Vector3(0, 0, -thickness * .5)
		_triangle(surface, a + front, b + front, d + front)
		_triangle(surface, a + front, d + front, c + front)
		_triangle(surface, a + back, d + back, b + back)
		_triangle(surface, a + back, c + back, d + back)
		_triangle(surface, a + front, a + back, b + back)
		_triangle(surface, a + front, b + back, b + front)
		_triangle(surface, c + front, d + back, c + back)
		_triangle(surface, c + front, d + front, d + back)
	surface.generate_normals()
	var piece := MeshInstance3D.new()
	piece.name = label
	piece.mesh = surface.commit()
	piece.material_override = material
	add_child(piece)

func slash() -> void:
	slash_time = .25

func _process(delta: float) -> void:
	slash_time = maxf(slash_time - delta, 0.0)
	var swing := sin((1.0 - slash_time / .25) * PI) if slash_time > 0.0 else 0.0
	rotation.z = -.62 * swing
	rotation.x = -.23 * swing
