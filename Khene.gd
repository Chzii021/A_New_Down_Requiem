extends Node3D

# Low-poly Isan khaen held in both hands during special-power activation.
# All pieces are built from simple meshes so the prop works without external files.
var breath: Node3D
var breath_age := 0.0
var blowing := false

func _ready() -> void:
	_build()
	set_blowing(false)

func _mat(color: Color, translucent := false) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.9
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED if translucent else BaseMaterial3D.SHADING_MODE_PER_PIXEL
	if translucent:
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.no_depth_test = true
	return material

func _box(parent: Node3D, label: String, center: Vector3, size: Vector3, material: Material) -> MeshInstance3D:
	var piece := MeshInstance3D.new()
	piece.name = label
	var shape := BoxMesh.new()
	shape.size = size
	piece.mesh = shape
	piece.material_override = material
	piece.position = center
	parent.add_child(piece)
	return piece

func _tube(parent: Node3D, label: String, center: Vector3, radius: float, length: float, material: Material) -> MeshInstance3D:
	var piece := MeshInstance3D.new()
	piece.name = label
	var shape := CylinderMesh.new()
	shape.top_radius = radius
	shape.bottom_radius = radius
	shape.height = length
	shape.radial_segments = 8
	piece.mesh = shape
	piece.material_override = material
	piece.position = center
	parent.add_child(piece)
	return piece

func _build() -> void:
	var bamboo := _mat(Color("c99c55"))
	var bamboo_light := _mat(Color("e0b773"))
	var bamboo_dark := _mat(Color("8d673b"))
	var hollow := _mat(Color("342c25"))
	var timber := _mat(Color("5c3829"))
	var timber_light := _mat(Color("86543a"))
	var cord := _mat(Color("8e3437"))
	var cord_light := _mat(Color("bb5550"))
	var pipe_heights := [.98, .91, .83, .77, .69, .63, .57, .52]
	for i in range(pipe_heights.size()):
		var x := (float(i) - 3.5) * .069
		var z := .018 if i % 2 == 0 else -.018
		var height: float = pipe_heights[i]
		var outer := bamboo_light if i % 3 == 0 else bamboo
		_tube(self, "BambooPipe%02d" % i, Vector3(x, height * .5 - .07, z), .026, height, outer)
		_tube(self, "HollowOpening%02d" % i, Vector3(x, height - .068, z), .019, .003, hollow)
		_tube(self, "BambooLip%02d" % i, Vector3(x, height - .081, z), .027, .013, bamboo_dark)
		for knot in [.18, .48]:
			_tube(self, "PipeJoint%02d" % i, Vector3(x, knot, z), .027, .009, bamboo_dark)
	# The bound bamboo bundle, dark wooden wind chamber, and rear mouthpiece.
	for y in [.48, .515]:
		var rope := _tube(self, "RedBinding", Vector3(0, y, -.047), .012, .57, cord)
		rope.rotation.z = PI * .5
	for x in [-.255, .255]:
		_tube(self, "BindingTurn", Vector3(x, .497, -.016), .016, .07, cord_light)
	_box(self, "WoodenWindChamber", Vector3(0, .31, .0), Vector3(.67, .14, .16), timber)
	_box(self, "WindChamberTop", Vector3(0, .385, .0), Vector3(.61, .028, .14), timber_light)
	_box(self, "WindChamberInset", Vector3(0, .31, -.083), Vector3(.18, .042, .009), hollow)
	for x in [-.316, .316]:
		_tube(self, "ChamberCap", Vector3(x, .31, 0), .087, .04, timber_light).rotation.z = PI * .5
	var mouthpiece := _tube(self, "Mouthpiece", Vector3(0, .315, .145), .036, .19, timber)
	mouthpiece.rotation.x = PI * .5
	_tube(self, "MouthpieceTip", Vector3(0, .315, .237), .023, .016, hollow).rotation.x = PI * .5
	# Small hanging diamond charm from the red cord.
	_tube(self, "CharmCord", Vector3(.26, .40, -.057), .007, .20, cord)
	var charm := _box(self, "CarvedWoodCharm", Vector3(.26, .292, -.058), Vector3(.09, .09, .025), timber_light)
	charm.rotation.z = PI * .25
	_box(self, "CharmEngraving", Vector3(.26, .292, -.074), Vector3(.032, .032, .004), timber).rotation.z = PI * .25
	breath = Node3D.new()
	breath.name = "BlueBreath"
	add_child(breath)
	var mist := _mat(Color(.55, .88, 1.0, .40), true)
	for i in range(10):
		var puff := MeshInstance3D.new()
		puff.name = "BreathPuff%02d" % i
		var sphere := SphereMesh.new()
		sphere.radius = .018 + float(i % 3) * .005
		sphere.height = sphere.radius * 2.0
		sphere.radial_segments = 6
		sphere.rings = 4
		puff.mesh = sphere
		puff.material_override = mist
		breath.add_child(puff)

func set_blowing(active: bool) -> void:
	blowing = active
	if breath != null:
		breath.visible = active

func _process(delta: float) -> void:
	if not blowing or breath == null:
		return
	breath_age += delta
	for i in range(breath.get_child_count()):
		var puff := breath.get_child(i) as Node3D
		var pipe := i % 5
		var rise := fposmod(breath_age * (.22 + float(i % 3) * .05) + float(i) * .16, .30)
		puff.position = Vector3((float(pipe) - 2.0) * .07 + sin(breath_age * 4.0 + i) * .018, .88 - float(pipe) * .07 + rise, -.03 - rise * .15)
