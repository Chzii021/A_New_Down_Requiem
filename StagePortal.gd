extends Node3D

const PORTAL_SHADER = preload("res://StagePortal.gdshader")

var elapsed := 0.0
var surface: MeshInstance3D
var portal_light: OmniLight3D
var sparks: Array[MeshInstance3D] = []
var banners: Array[Node3D] = []
var wood: StandardMaterial3D
var dark_wood: StandardMaterial3D
var bamboo: StandardMaterial3D
var bamboo_light: StandardMaterial3D
var roof_red: StandardMaterial3D
var indigo: StandardMaterial3D
var woven_gold: StandardMaterial3D
var spirit: StandardMaterial3D
var firefly: StandardMaterial3D


func _ready() -> void:
	wood = _material(Color("563727"))
	dark_wood = _material(Color("3d2b25"))
	bamboo = _material(Color("80562f"))
	bamboo_light = _material(Color("b1865c"))
	roof_red = _material(Color("713e39"))
	indigo = _material(Color("163b5c"))
	woven_gold = _material(Color("c59a58"))
	spirit = _material(Color("a4dfa7"), 2.0)
	firefly = _material(Color("fff0bb"), 3.0)
	_build_ground()
	_build_surface()
	_build_gateway()
	_build_fireflies()
	_build_light()


func _material(color: Color, glow: float = 0.0) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.83
	if glow > 0.0:
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		material.emission_enabled = true
		material.emission = color
		material.emission_energy_multiplier = glow
	return material


func _block(parent: Node3D, part_name: String, place: Vector3, dimensions: Vector3, material: Material) -> MeshInstance3D:
	var part := MeshInstance3D.new()
	part.name = part_name
	var shape := BoxMesh.new()
	shape.size = dimensions
	part.mesh = shape
	part.material_override = material
	part.position = place
	parent.add_child(part)
	return part


func _tube(parent: Node3D, part_name: String, place: Vector3, radius: float, height: float, material: Material) -> MeshInstance3D:
	var part := MeshInstance3D.new()
	part.name = part_name
	var shape := CylinderMesh.new()
	shape.top_radius = radius
	shape.bottom_radius = radius * 1.04
	shape.height = height
	shape.radial_segments = 8
	part.mesh = shape
	part.material_override = material
	part.position = place
	parent.add_child(part)
	return part


func _build_ground() -> void:
	var mat := Node3D.new()
	mat.name = "WovenMat"
	add_child(mat)
	_block(mat, "ReedMat", Vector3(0.0, 0.055, 0.34),
		Vector3(3.3, 0.09, 1.55), dark_wood)
	for index in range(17):
		var x := (float(index) - 8.0) * 0.18
		_block(mat, "Warp%d" % index, Vector3(x, 0.108, 0.34),
			Vector3(0.048, 0.012, 1.40), bamboo_light if index % 2 == 0 else bamboo)
	for index in range(8):
		var z := -0.30 + float(index) * 0.18
		_block(mat, "Weft%d" % index, Vector3(0.0, 0.119, z),
			Vector3(3.05, 0.012, 0.048), bamboo if index % 2 == 0 else woven_gold)
	for side in [-1.0, 1.0]:
		_block(mat, "MatBinding", Vector3(side * 1.58, 0.126, 0.34),
			Vector3(0.11, 0.03, 1.55), indigo)


func _build_surface() -> void:
	surface = MeshInstance3D.new()
	surface.name = "PortalSurface"
	var quad := QuadMesh.new()
	quad.size = Vector2(2.75, 3.58)
	surface.mesh = quad
	surface.position = Vector3(0.0, 1.62, 0.07)
	surface.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var material := ShaderMaterial.new()
	material.shader = PORTAL_SHADER
	surface.material_override = material
	add_child(surface)
	surface.scale = Vector3(0.08, 0.08, 1.0)


func _build_gateway() -> void:
	var gateway := Node3D.new()
	gateway.name = "BambooGateway"
	add_child(gateway)
	for side in [-1.0, 1.0]:
		_block(gateway, "WoodenFoot", Vector3(side * 1.24, 0.25, 0.22),
			Vector3(0.48, 0.46, 0.58), dark_wood)
		_tube(gateway, "BambooPost", Vector3(side * 1.24, 1.55, 0.22),
			0.13, 2.75, bamboo_light)
		for band in range(5):
			_tube(gateway, "PostJoint", Vector3(side * 1.24, 0.58 + float(band) * 0.5, 0.22),
				0.145, 0.045, bamboo)
		var brace := _block(gateway, "BambooBrace",
			Vector3(side * 1.03, 2.75, 0.22), Vector3(0.66, 0.09, 0.30), bamboo)
		brace.rotation.z = -side * 0.66
	_block(gateway, "WoodenLintel", Vector3(0.0, 3.01, 0.18),
		Vector3(2.95, 0.22, 0.64), wood)
	_block(gateway, "LintelBinding", Vector3(0.0, 2.99, 0.52),
		Vector3(2.62, 0.07, 0.05), bamboo_light)
	for side in [-1.0, 1.0]:
		var roof := _block(gateway, "GableRoof", Vector3(side * 0.75, 3.38, 0.18),
			Vector3(1.82, 0.20, 0.94), roof_red)
		roof.rotation.z = -side * 0.44
		var trim := _block(gateway, "BambooRoofEdge", Vector3(side * 0.75, 3.38, 0.67),
			Vector3(1.83, 0.052, 0.05), bamboo_light)
		trim.rotation.z = -side * 0.44
	_block(gateway, "RidgeCap", Vector3(0.0, 3.76, 0.18),
		Vector3(0.32, 0.19, 1.05), dark_wood)
	_build_khaen_crest(gateway)
	_build_textile(gateway)
	_build_lanterns(gateway)


func _build_khaen_crest(gateway: Node3D) -> void:
	var crest := Node3D.new()
	crest.name = "KhaenCrest"
	gateway.add_child(crest)
	for index in range(7):
		var distance := absi(index - 3)
		var height := 0.42 + float(3 - distance) * 0.085
		_tube(crest, "KhaenReed%d" % index,
			Vector3((float(index) - 3.0) * 0.092, 3.52 + height * 0.23, 0.78),
			0.032, height, bamboo_light if index % 2 == 0 else bamboo)
	_block(crest, "ReedBinding", Vector3(0.0, 3.49, 0.82),
		Vector3(0.72, 0.12, 0.13), dark_wood)


func _build_textile(gateway: Node3D) -> void:
	var cloth := Node3D.new()
	cloth.name = "PhaKhitBanners"
	gateway.add_child(cloth)
	for index in range(7):
		var x := (float(index) - 3.0) * 0.33
		var diamond := _block(cloth, "LintelDiamond%d" % index,
			Vector3(x, 3.04, 0.565), Vector3(0.105, 0.105, 0.026),
			woven_gold if index % 2 == 0 else roof_red)
		diamond.rotation.z = PI * 0.25
	for side in [-1.0, 1.0]:
		var banner := Node3D.new()
		banner.name = "HangingCloth"
		banner.position = Vector3(side * 1.24, 2.82, 0.60)
		cloth.add_child(banner)
		banners.append(banner)
		_block(banner, "IndigoFabric", Vector3(0.0, -0.40, 0.0),
			Vector3(0.26, 0.79, 0.055), indigo)
		for stripe in [0.10, 0.68]:
			_block(banner, "RedClothBand", Vector3(0.0, -stripe, 0.036),
				Vector3(0.27, 0.065, 0.018), roof_red)
		for motif in range(3):
			var diamond := _block(banner, "KhitDiamond%d" % motif,
				Vector3(0.0, -0.23 - float(motif) * 0.18, 0.045),
				Vector3(0.105, 0.105, 0.019), woven_gold)
			diamond.rotation.z = PI * 0.25


func _build_lanterns(gateway: Node3D) -> void:
	for side in [-1.0, 1.0]:
		var x: float = side * 1.51
		_block(gateway, "LampBracket", Vector3(side * 1.41, 2.38, 0.49),
			Vector3(0.35, 0.07, 0.32), wood)
		_block(gateway, "LanternFrame", Vector3(x, 2.12, 0.58),
			Vector3(0.28, 0.43, 0.30), dark_wood)
		_block(gateway, "LanternFlame", Vector3(x, 2.13, 0.755),
			Vector3(0.16, 0.26, 0.04), firefly)
		_block(gateway, "LanternRoof", Vector3(x, 2.38, 0.58),
			Vector3(0.37, 0.08, 0.37), roof_red)
		var lamp_light := OmniLight3D.new()
		lamp_light.name = "LanternLight"
		lamp_light.position = Vector3(x, 2.13, 0.78)
		lamp_light.light_color = Color("f3ca79")
		lamp_light.light_energy = 0.85
		lamp_light.omni_range = 2.8
		gateway.add_child(lamp_light)


func _build_fireflies() -> void:
	var motes := Node3D.new()
	motes.name = "SpiritFireflies"
	add_child(motes)
	for index in range(20):
		var spark := _block(motes, "Firefly%d" % index, Vector3.ZERO,
			Vector3(0.06, 0.06, 0.06), firefly if index % 3 == 0 else spirit)
		spark.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		sparks.append(spark)


func _build_light() -> void:
	portal_light = OmniLight3D.new()
	portal_light.name = "PortalLight"
	portal_light.position = Vector3(0.0, 1.58, 0.61)
	portal_light.light_color = Color("b7dd9a")
	portal_light.light_energy = 2.1
	portal_light.omni_range = 5.7
	add_child(portal_light)


func _process(delta: float) -> void:
	elapsed += delta
	var opening := clampf(elapsed / 0.75, 0.0, 1.0)
	opening = 1.0 - pow(1.0 - opening, 3.0)
	surface.scale = Vector3(maxf(opening, 0.08), maxf(opening, 0.08), 1.0)
	portal_light.light_energy = 2.0 + 0.32 * sin(elapsed * 2.6)
	for index in range(banners.size()):
		banners[index].rotation.z = sin(elapsed * 1.25 + float(index) * 1.7) * 0.075
	for index in range(sparks.size()):
		var seed := float(index)
		var travel := fposmod(elapsed * (0.22 + 0.05 * sin(seed * 2.7)) + seed * 0.618, 1.0)
		var angle := seed * 2.399 + elapsed * 0.35
		sparks[index].position = Vector3(
			sin(angle) * (0.7 + 0.42 * travel),
			0.20 + travel * 2.95,
			0.70 + cos(angle) * 0.23
		)
		var size := (1.0 - travel) * (0.72 + 0.25 * sin(elapsed * 5.0 + seed))
		sparks[index].scale = Vector3.ONE * maxf(size, 0.16)
