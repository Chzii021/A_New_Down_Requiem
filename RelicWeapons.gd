extends RefCounted

# Shared geometry for the equipped relics and the eight collectible components.
# Both weapons point down local -Z, matching the existing shot and hand sockets.
const WICKER = "a87a43"
const WICKER_LIGHT = "c59a58"
const WICKER_DARK = "80562f"
const WOOD = "563727"
const WOOD_LIGHT = "835536"
const INDIGO = "163b5c"
const INDIGO_LIGHT = "2b6280"
const RED = "913a39"
const CRYSTAL = "38c5d1"

static func _material(hex: String, glow := false) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(hex)
	material.roughness = .83 if not glow else .32
	material.metallic = .04 if not glow else .28
	if glow:
		material.emission_enabled = true
		material.emission = Color(hex)
		material.emission_energy_multiplier = .55
	return material

static func _node(parent: Node3D, label: String, offset := Vector3.ZERO) -> Node3D:
	var node := Node3D.new()
	node.name = label
	node.position = offset
	parent.add_child(node)
	return node

static func _box(parent: Node3D, label: String, offset: Vector3, size: Vector3, hex: String) -> MeshInstance3D:
	var piece := MeshInstance3D.new()
	piece.name = label
	var mesh := BoxMesh.new()
	mesh.size = size
	piece.mesh = mesh
	piece.material_override = _material(hex)
	piece.position = offset
	parent.add_child(piece)
	return piece

static func _tube(parent: Node3D, label: String, offset: Vector3, radius: float, length: float, hex: String, along_z := true) -> MeshInstance3D:
	var piece := MeshInstance3D.new()
	piece.name = label
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = length
	mesh.radial_segments = 8
	piece.mesh = mesh
	piece.material_override = _material(hex)
	piece.position = offset
	if along_z:
		piece.rotation.x = PI * .5
	parent.add_child(piece)
	return piece

static func _crystal(parent: Node3D, label: String, offset: Vector3, radius: float) -> void:
	var holder := _node(parent, label, offset)
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 1.5
	mesh.radial_segments = 8
	mesh.rings = 4
	var gem := MeshInstance3D.new()
	gem.name = "TurquoiseCrystal"
	gem.mesh = mesh
	gem.material_override = _material(CRYSTAL, true)
	holder.add_child(gem)
	_box(holder, "CrystalSeat", Vector3(0, 0, radius * .62), Vector3(radius * 1.4, radius * 1.4, .012), INDIGO)

static func short_component(parent: Node3D, index: int) -> Node3D:
	var piece := _node(parent, ["WickerReceiver", "CarvedGripAndCell", "CrystalMuzzle"][index])
	match index:
		0:
			piece.position = Vector3(0, 0, -.045)
			_tube(piece, "KratipWickerChamber", Vector3.ZERO, .098, .275, WICKER)
			for slat in range(10):
				var angle := TAU * float(slat) / 10.0
				var slat_mesh := _box(piece, "WickerSlat%02d" % slat, Vector3(sin(angle) * .094, cos(angle) * .094, 0), Vector3(.024, .013, .246), WICKER_LIGHT if slat % 2 == 0 else WICKER_DARK)
				slat_mesh.rotation.z = -angle
			_tube(piece, "RearWoodRim", Vector3(0, 0, .135), .109, .027, WOOD_LIGHT)
			_tube(piece, "IndigoBinding", Vector3(0, 0, .079), .108, .024, INDIGO)
			_box(piece, "IvoryDiamond", Vector3(0, -.101, -.002), Vector3(.048, .012, .048), WICKER_LIGHT).rotation.y = PI * .25
			_box(piece, "RearSight", Vector3(0, .095, .112), Vector3(.040, .025, .032), INDIGO)
		1:
			piece.position = Vector3(0, -.125, .025)
			_box(piece, "CarvedWoodGrip", Vector3(0, -.027, 0), Vector3(.083, .250, .102), WOOD)
			_box(piece, "GripFace", Vector3(0, -.031, -.054), Vector3(.066, .190, .009), WOOD_LIGHT)
			_box(piece, "IvoryInlay", Vector3(0, -.025, -.061), Vector3(.039, .039, .008), WICKER_LIGHT).rotation.z = PI * .25
			_box(piece, "IndigoHeel", Vector3(0, -.150, 0), Vector3(.094, .024, .108), INDIGO)
			_box(piece, "TriggerGuard", Vector3(0, .085, -.073), Vector3(.075, .016, .095), WICKER_DARK)
			_box(piece, "RedTrigger", Vector3(0, .044, -.069), Vector3(.018, .087, .018), RED)
		2:
			piece.position = Vector3(0, 0, -.184)
			_tube(piece, "CarvedNozzle", Vector3(0, 0, -.016), .068, .072, WOOD_LIGHT)
			_tube(piece, "OchreFrontRim", Vector3(0, 0, -.055), .074, .025, WICKER_LIGHT)
			_crystal(piece, "SpiritCrystal", Vector3(0, 0, -.096), .042)
			_box(piece, "IndigoTopLatch", Vector3(0, .076, .023), Vector3(.048, .030, .068), INDIGO)
	return piece

static func short_magazine(parent: Node3D) -> Node3D:
	var piece := _node(parent, "SpiritCellMagazine", Vector3(0, -.315, .025))
	_box(piece, "CarvedCellCase", Vector3.ZERO, Vector3(.058, .160, .076), WOOD_LIGHT)
	_box(piece, "IndigoMagazineBase", Vector3(0, -.081, 0), Vector3(.075, .026, .090), INDIGO)
	_box(piece, "WickerLatch", Vector3(0, .072, 0), Vector3(.067, .022, .084), WICKER_LIGHT)
	_box(piece, "SpiritCellWindow", Vector3(0, .012, -.041), Vector3(.035, .071, .009), CRYSTAL)
	return piece

static func rapid_component(parent: Node3D, index: int) -> Node3D:
	var piece := _node(parent, ["KhaenReedReceiver", "ForwardReedBarrels", "CurvedWoodMagazine", "CarvedGripAndTrigger", "IndigoBindings"][index])
	match index:
		0:
			piece.position = Vector3(0, 0, .065)
			_tube(piece, "WoodenCore", Vector3(0, 0, 0), .066, .385, WOOD_LIGHT)
			for row in range(3):
				for column in range(3):
					var x := (float(column) - 1.0) * .052
					var y := (float(row) - 1.0) * .052
					_tube(piece, "KhaenReed%d%d" % [row, column], Vector3(x, y, 0), .019, .405, WICKER_LIGHT if (row + column) % 2 == 0 else WICKER)
			_box(piece, "TopGuide", Vector3(0, .080, .035), Vector3(.063, .021, .300), WICKER_DARK)
		1:
			piece.position = Vector3(0, 0, -.390)
			for row in range(3):
				for column in range(3):
					var x := (float(column) - 1.0) * .046
					var y := (float(row) - 1.0) * .046
					var length := .37 + float((row + column) % 3) * .045
					_tube(piece, "ForwardBamboo%d%d" % [row, column], Vector3(x, y, .01), .017, length, WICKER if (row + column) % 2 == 0 else WICKER_LIGHT)
			_tube(piece, "MuzzleCollar", Vector3(0, 0, -.235), .053, .028, INDIGO)
			_crystal(piece, "MuzzleCrystal", Vector3(0, 0, -.270), .027)
		2:
			piece.position = Vector3(0, -.060, -.089)
			_box(piece, "MagazineUpper", Vector3(0, -.072, .009), Vector3(.080, .170, .090), WOOD_LIGHT).rotation.x = -.17
			_box(piece, "MagazineLower", Vector3(0, -.202, -.036), Vector3(.078, .150, .086), WOOD).rotation.x = -.42
			_box(piece, "MagazineTip", Vector3(0, -.268, -.070), Vector3(.087, .030, .095), INDIGO)
			_box(piece, "MagazineIvoryInlay", Vector3(0, -.170, -.084), Vector3(.037, .039, .008), WICKER_LIGHT).rotation.z = PI * .25
		3:
			piece.position = Vector3(0, -.102, .080)
			_box(piece, "CarvedGrip", Vector3(0, -.033, 0), Vector3(.090, .211, .098), WOOD)
			_box(piece, "GripPanel", Vector3(0, -.045, -.053), Vector3(.071, .130, .008), WOOD_LIGHT)
			_box(piece, "IvoryInlay", Vector3(0, -.043, -.060), Vector3(.034, .034, .008), WICKER_LIGHT).rotation.z = PI * .25
			_box(piece, "TriggerBridge", Vector3(0, .080, -.083), Vector3(.105, .018, .130), WICKER_DARK)
			_box(piece, "RedTrigger", Vector3(0, .031, -.067), Vector3(.017, .080, .019), RED)
		4:
			for z in [.218, -.165, -.474]:
				_tube(piece, "IndigoReedBand", Vector3(0, 0, z), .088 if z > -.3 else .077, .029, INDIGO)
				_box(piece, "BandEdge", Vector3(0, -.087 if z > -.3 else -.076, z), Vector3(.055, .009, .031), INDIGO_LIGHT)
			_box(piece, "WovenCord", Vector3(0, -.090, -.085), Vector3(.018, .085, .019), INDIGO)
			_box(piece, "RedTassel", Vector3(.055, -.120, -.478), Vector3(.022, .145, .012), RED)
	return piece
