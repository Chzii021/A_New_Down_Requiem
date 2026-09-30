extends Node3D

@export_range(1, 4) var map_id = 1
@export var baked_scene = false
const MAP_LAYOUT = preload("res://MapLayout.gd")
const POPULATIONS = [10, 30, 40, 35]

var shrine_places: Array[Vector3] = []
var villager_places: Array[Vector3] = []
var shrine_markers: Array[MeshInstance3D] = []
var shrine_lights: Array[OmniLight3D] = []
var pickup_places: Array[Vector3] = []
var materials = {}


func _ready() -> void:
	if baked_scene:
		_bind_baked_scene()
		return
	var landscape = preload("res://Scenery.gd").new()
	landscape.map_id = map_id
	landscape.name = "Scenery"
	add_child(landscape)
	match map_id:
		1:
			_build_morning_village()
		2:
			_build_market()
		3:
			_build_dusk_fields()
		4:
			_build_night_courtyard()
	for place in shrine_places:
		_build_spirit_shrine(place)
	villager_places = MAP_LAYOUT.villager_positions(map_id, POPULATIONS[map_id - 1])


func _bind_baked_scene() -> void:
	shrine_places.clear()
	shrine_markers.clear()
	shrine_lights.clear()
	for child in get_children():
		if child is Node3D and child.name.begins_with("Shrine_"):
			shrine_places.append(child.position)
			shrine_markers.append(child.get_node("WorshipMarker"))
			shrine_lights.append(child.get_node("WorshipLight"))
	villager_places.clear()
	var spawns = get_node_or_null("VillagerSpawns")
	if spawns != null:
		for marker in spawns.get_children():
			villager_places.append(marker.position)
	else:
		villager_places = MAP_LAYOUT.villager_positions(map_id, POPULATIONS[map_id - 1])
	pickup_places.clear()
	var pickups = get_node_or_null("PickupSpawns")
	if pickups != null:
		for marker in pickups.get_children():
			pickup_places.append(marker.position)


func _mat(color: Color, glowing: bool = false) -> StandardMaterial3D:
	var key = color.to_html(true) + ("_glow" if glowing else "_plain")
	if materials.has(key):
		return materials[key]
	var material = StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.88
	if glowing:
		material.emission_enabled = true
		material.emission = color
		material.emission_energy_multiplier = 1.7
	materials[key] = material
	return material


func _box(parent: Node3D, place: Vector3, dimensions: Vector3, color: Color, glowing: bool = false) -> MeshInstance3D:
	var mesh = MeshInstance3D.new()
	var shape = BoxMesh.new()
	shape.size = dimensions
	mesh.mesh = shape
	mesh.material_override = _mat(color, glowing)
	mesh.position = place
	parent.add_child(mesh)
	return mesh


func _post(parent: Node3D, place: Vector3, radius: float, height: float, color: Color) -> void:
	var mesh = MeshInstance3D.new()
	var shape = CylinderMesh.new()
	shape.top_radius = radius
	shape.bottom_radius = radius * 1.1
	shape.height = height
	shape.radial_segments = 8
	mesh.mesh = shape
	mesh.material_override = _mat(color)
	mesh.position = place
	parent.add_child(mesh)


func _group(place: Vector3, title: String) -> Node3D:
	var group = Node3D.new()
	group.name = title
	group.position = place
	add_child(group)
	return group


func _obstacle(parent: Node3D, place: Vector3, dimensions: Vector3) -> void:
	var body = StaticBody3D.new()
	body.position = place
	parent.add_child(body)
	var collision = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = dimensions
	collision.shape = shape
	body.add_child(collision)


func _house(place: Vector3, wall: Color, roof: Color) -> void:
	var house = _group(place, "บ้านไม้ยกพื้น")
	_obstacle(house, Vector3(0, 1.8, 0), Vector3(3.8, 3.6, 3.5))
	for x in [-1.65, 1.65]:
		for z in [-1.5, 1.5]:
			_box(house, Vector3(x, .8, z), Vector3(.24, 1.6, .24), Color("63472f"))
	_box(house, Vector3(0, 1.65, 0), Vector3(4.0, .17, 3.7), Color("775337"))
	_box(house, Vector3(0, 2.48, 0), Vector3(3.75, 1.65, 3.42), wall)
	_box(house, Vector3(0, 2.43, -1.74), Vector3(.8, 1.05, .06), Color("342b27"))
	for x in [-1.05, 1.05]:
		var panel = _box(house, Vector3(x, 3.58, 0), Vector3(2.3, .18, 4.0), roof)
		panel.rotation.z = .47 if x < 0 else -.47
	for step in range(4):
		_box(house, Vector3(0, 1.18 - step * .32, -2.0 - step * .35), Vector3(1.2, .1, .34), Color("846145"))


func _granary(place: Vector3) -> void:
	var barn = _group(place, "ยุ้งข้าว")
	_obstacle(barn, Vector3(0, 1.85, 0), Vector3(3.2, 3.7, 2.7))
	for x in [-1.5, 1.5]:
		for z in [-1.2, 1.2]:
			_box(barn, Vector3(x, .75, z), Vector3(.22, 1.5, .22), Color("735336"))
	_box(barn, Vector3(0, 1.65, 0), Vector3(3.5, .18, 2.9), Color("765439"))
	_box(barn, Vector3(0, 2.55, 0), Vector3(3.15, 1.65, 2.6), Color("a08256"))
	for x in [-.8, .8]:
		var roof = _box(barn, Vector3(x, 3.62, 0), Vector3(1.95, .24, 3.1), Color("9b8757"))
		roof.rotation.z = .48 if x < 0 else -.48
	_box(barn, Vector3(0, 2.54, -1.34), Vector3(.82, 1.2, .06), Color("5f4834"))


func _well(place: Vector3) -> void:
	var well = _group(place, "บ่อน้ำหมู่บ้าน")
	_obstacle(well, Vector3(0, .65, 0), Vector3(1.75, 1.3, 1.75))
	_post(well, Vector3(0, .42, 0), 1.05, .84, Color("8d8d82"))
	_post(well, Vector3(0, .44, 0), .75, .83, Color("425f67"))
	for x in [-.85, .85]:
		_box(well, Vector3(x, 1.43, 0), Vector3(.13, 2.1, .13), Color("664936"))
	_box(well, Vector3(0, 2.45, 0), Vector3(2.1, .16, 1.55), Color("735239"))


func _stall(place: Vector3, cloth: Color) -> void:
	var stall = _group(place, "แผงตลาด")
	_obstacle(stall, Vector3(0, 1.4, 0), Vector3(3.1, 2.8, 1.9))
	for x in [-1.5, 1.5]:
		for z in [-.9, .9]:
			_box(stall, Vector3(x, 1.3, z), Vector3(.13, 2.6, .13), Color("75543c"))
	_box(stall, Vector3(0, 1.05, 0), Vector3(3.2, .2, 2.0), Color("8c6746"))
	_box(stall, Vector3(0, 2.73, 0), Vector3(3.7, .16, 2.55), cloth)
	for x in [-1.0, 0.0, 1.0]:
		_box(stall, Vector3(x, 1.27, -.28), Vector3(.56, .24, .55), Color("9c7d4f"))
		_box(stall, Vector3(x, 1.52, -.28), Vector3(.35, .25, .35), Color("c39955"))


func _watchtower(place: Vector3) -> void:
	var tower = _group(place, "หอสังเกตการณ์")
	_obstacle(tower, Vector3(0, 2.7, 0), Vector3(3.1, 5.4, 2.9))
	for x in [-1.35, 1.35]:
		for z in [-1.15, 1.15]:
			_box(tower, Vector3(x, 2.2, z), Vector3(.24, 4.4, .24), Color("634735"))
	_box(tower, Vector3(0, 4.0, 0), Vector3(3.3, .18, 3.0), Color("7d5d42"))
	_box(tower, Vector3(0, 5.5, 0), Vector3(3.8, .19, 3.5), Color("654739"))
	for x in [-1.6, 1.6]:
		_box(tower, Vector3(x, 4.62, 0), Vector3(.1, 1.2, 2.7), Color("8c714d"))


func _pavilion(place: Vector3) -> void:
	var pavilion = _group(place, "ศาลาริมนา")
	_obstacle(pavilion, Vector3(0, .3, 0), Vector3(6.2, .6, 4.6))
	_box(pavilion, Vector3(0, .32, 0), Vector3(6.2, .55, 4.6), Color("8d785a"))
	for x in [-2.7, 2.7]:
		for z in [-1.8, 1.8]:
			_box(pavilion, Vector3(x, 2.0, z), Vector3(.23, 3.2, .23), Color("74513b"))
	_box(pavilion, Vector3(0, 3.55, 0), Vector3(6.8, .2, 5.1), Color("784e3d"))
	for x in [-1.5, 1.5]:
		var roof = _box(pavilion, Vector3(x, 4.35, 0), Vector3(3.55, .2, 5.4), Color("9b6247"))
		roof.rotation.z = .43 if x < 0 else -.43
	_box(pavilion, Vector3(0, .7, 0), Vector3(3.4, .28, 1.5), Color("98704b"))


func _pond(place: Vector3) -> void:
	var pond = _group(place, "สระน้ำยามเย็น")
	_box(pond, Vector3(0, .01, 0), Vector3(11.0, .025, 8.0), Color("4d7885"))
	for x in [-5.6, 5.6]:
		_box(pond, Vector3(x, .12, 0), Vector3(.48, .22, 8.7), Color("796955"))
	for z in [-4.2, 4.2]:
		_box(pond, Vector3(0, .12, z), Vector3(11.4, .22, .46), Color("796955"))
	for x in [-3.0, 0.0, 3.0]:
		_box(pond, Vector3(x, .035, 1.2), Vector3(.7, .03, .7), Color("7c9d72"))


func _lantern(place: Vector3, tint: Color) -> void:
	var lamp = _group(place, "โคมไฟ")
	_box(lamp, Vector3(0, 1.24, 0), Vector3(.13, 2.48, .13), Color("5c4436"))
	_box(lamp, Vector3(0, 2.47, 0), Vector3(.6, .12, .5), Color("5c4436"))
	_box(lamp, Vector3(0, 2.12, 0), Vector3(.32, .42, .31), tint, true)
	var light = OmniLight3D.new()
	light.position = Vector3(0, 2.1, 0)
	light.light_color = tint
	light.light_energy = 1.35 if map_id < 4 else 2.2
	light.omni_range = 6.5
	lamp.add_child(light)


func _memorial_stone(place: Vector3) -> void:
	var stone = _group(place, "หลักหิน")
	_box(stone, Vector3(0, .7, 0), Vector3(.95, 1.4, .55), Color("68727a"))
	_box(stone, Vector3(0, 1.44, 0), Vector3(1.12, .16, .7), Color("849098"))
	_box(stone, Vector3(0, .81, -.3), Vector3(.4, .54, .04), Color("9dcbd1"), true)


func _night_hall(place: Vector3) -> void:
	var hall = _group(place, "ศาลท้ายหมู่บ้าน")
	_obstacle(hall, Vector3(0, 2.4, 0), Vector3(11.8, 4.8, 8.6))
	_box(hall, Vector3(0, .27, 0), Vector3(12.0, .52, 8.8), Color("67676c"))
	for x in [-4.7, 4.7]:
		for z in [-3.2, 3.2]:
			_box(hall, Vector3(x, 2.1, z), Vector3(.35, 3.7, .35), Color("6f5040"))
	_box(hall, Vector3(0, 3.9, 0), Vector3(11.5, .2, 9.1), Color("4d3a3b"))
	for x in [-2.8, 2.8]:
		var roof = _box(hall, Vector3(x, 4.95, 0), Vector3(6.1, .25, 9.4), Color("613d3d"))
		roof.rotation.z = .4 if x < 0 else -.4
	_box(hall, Vector3(0, 1.15, -2.4), Vector3(3.2, 1.55, 1.3), Color("705e55"))
	for x in [-4.1, 4.1]:
		_lantern(place + Vector3(x, 0, 5.2), Color("a4d4e8"))


func _build_morning_village() -> void:
	shrine_places = [Vector3(-28, 0, -37), Vector3(28, 0, -37)]
	_house(Vector3(-9, 0, 8), Color("916a4b"), Color("8d5b41"))
	_house(Vector3(9, 0, 3), Color("805d49"), Color("8c6045"))
	_house(Vector3(-9, 0, -18), Color("a17d5b"), Color("856043"))
	_granary(Vector3(9, 0, -16))
	_well(Vector3(-7, 0, 0))
	_house(Vector3(-32, 0, -28), Color("9c7654"), Color("866041"))
	_house(Vector3(32, 0, -29), Color("82634d"), Color("86553b"))
	_granary(Vector3(-10, 0, -56))
	_well(Vector3(9, 0, -48))
	_lantern(Vector3(5.5, 0, 10), Color("f6d399"))
	_lantern(Vector3(-23, 0, -21), Color("f6d399"))
	_lantern(Vector3(23, 0, -43), Color("f6d399"))


func _build_market() -> void:
	shrine_places = [Vector3(-35, 0, -44), Vector3(20, 0, -65)]
	_stall(Vector3(-8, 0, 7), Color("b66755"))
	_stall(Vector3(8, 0, 2), Color("73907a"))
	_stall(Vector3(-8, 0, -12), Color("a88a5e"))
	_stall(Vector3(8, 0, -19), Color("797da0"))
	_watchtower(Vector3(-9, 0, -27))
	_granary(Vector3(10, 0, -27))
	_stall(Vector3(-39, 0, -30), Color("ad7655"))
	_stall(Vector3(39, 0, -32), Color("718b86"))
	_stall(Vector3(-28, 0, -62), Color("9b7489"))
	_stall(Vector3(28, 0, -62), Color("b8945f"))
	_watchtower(Vector3(-42, 0, -59))
	_watchtower(Vector3(42, 0, -59))
	_granary(Vector3(-9, 0, -76))
	_lantern(Vector3(5.6, 0, 13), Color("fff0bb"))
	_lantern(Vector3(-27, 0, -19), Color("fff0bb"))
	_lantern(Vector3(28, 0, -48), Color("fff0bb"))


func _build_dusk_fields() -> void:
	shrine_places = [Vector3(-34, 0, -20), Vector3(43, 0, -53), Vector3(-23, 0, -79)]
	_pavilion(Vector3(-9, 0, 2))
	_pond(Vector3(11, 0, -13))
	_granary(Vector3(-10, 0, -22))
	_pavilion(Vector3(-49, 0, -43))
	_pavilion(Vector3(49, 0, -42))
	_pond(Vector3(56, 0, -70))
	_granary(Vector3(-31, 0, -88))
	_granary(Vector3(31, 0, -88))
	for z in [12.0, -1.0, -13.0, -24.0]:
		_lantern(Vector3(-5.3, 0, z), Color("ffad71"))
		_lantern(Vector3(5.3, 0, z), Color("ffad71"))
	for z in [-37.0, -58.0, -79.0]:
		_lantern(Vector3(-43, 0, z), Color("ffad71"))
		_lantern(Vector3(43, 0, z), Color("ffad71"))


func _build_night_courtyard() -> void:
	shrine_places = [Vector3(-49, 0, -62)]
	_night_hall(Vector3(0, 0, -106))
	_watchtower(Vector3(-10, 0, -16))
	_watchtower(Vector3(10, 0, -16))
	_watchtower(Vector3(-56, 0, -62))
	_watchtower(Vector3(56, 0, -62))
	for z in [-4.0, -13.0, -22.0, -43.0, -65.0, -87.0]:
		_memorial_stone(Vector3(-7.3, 0, z))
		_memorial_stone(Vector3(7.3, 0, z))
	for z in [8.0, -3.0, -14.0, -25.0, -42.0, -59.0, -76.0, -93.0]:
		_lantern(Vector3(-5.6, 0, z), Color("a0d9e7"))
		_lantern(Vector3(5.6, 0, z), Color("a0d9e7"))
	for z in [-34.0, -55.0, -76.0]:
		_memorial_stone(Vector3(-53, 0, z))
		_memorial_stone(Vector3(53, 0, z))


func _build_spirit_shrine(place: Vector3) -> void:
	var shrine = _group(place, "ศาลพระภูมิ")
	shrine.name = "Shrine_%d" % shrine_places.find(place)
	_obstacle(shrine, Vector3(0, 1.25, 0), Vector3(1.3, 2.5, 1.2))
	_box(shrine, Vector3(0, .18, 0), Vector3(1.55, .34, 1.5), Color("80746d"))
	_post(shrine, Vector3(0, 1.06, 0), .15, 1.52, Color("795847"))
	_box(shrine, Vector3(0, 1.85, 0), Vector3(1.3, .16, 1.2), Color("9c744d"))
	_box(shrine, Vector3(0, 2.2, 0), Vector3(1.1, .66, 1.0), Color("b1865c"))
	_box(shrine, Vector3(0, 2.56, 0), Vector3(1.47, .15, 1.4), Color("804942"))
	for x in [-.39, .39]:
		var roof = _box(shrine, Vector3(x, 2.87, 0), Vector3(.9, .13, 1.55), Color("9b5f4d"))
		roof.rotation.z = .48 if x < 0 else -.48
	_box(shrine, Vector3(0, 2.15, -.52), Vector3(.28, .45, .06), Color("e8c580"), true)
	for x in [-.29, 0.0, .29]:
		_box(shrine, Vector3(x, .62, -.64), Vector3(.035, .42, .035), Color("e9d5a7"))
	var marker = _box(shrine, Vector3(0, 4.7, 0), Vector3(.13, 2.5, .13), Color("f3ca79"), true)
	marker.name = "WorshipMarker"
	shrine_markers.append(marker)
	var light = OmniLight3D.new()
	light.name = "WorshipLight"
	light.position = Vector3(0, 2.32, -.3)
	light.light_color = Color("f3ca79")
	light.light_energy = 1.0
	light.omni_range = 8.0
	shrine.add_child(light)
	shrine_lights.append(light)


func mark_worshipped(index: int) -> void:
	if index < 0 or index >= shrine_markers.size():
		return
	shrine_markers[index].material_override = _mat(Color("84e5dc"), true)
	shrine_lights[index].light_color = Color("84e5dc")
	shrine_lights[index].light_energy = 1.8
