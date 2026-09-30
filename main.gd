extends Node3D

const MAX_HP = 100
const MEDICINE_HEAL = 50
const MAX_MEDICINE = 5
const VILLAGER_COUNT = 115
const MAP_VILLAGER_COUNTS = [10, 30, 40, 35]
const BOSS_ATTACK_DURATION = 10.0
const BOSS_VULNERABLE_DURATION = 3.0
const BOSS_SPIRIT_INTERVAL = 1.5
const BOSS_SPIRIT_SPEED = 16.0
const BOSS_MAP_SCALE = 0.78
const VILLAGER_HP = 5
const RUN_SPEED = 7.4
const VILLAGER_SPEED = RUN_SPEED
const VILLAGER_AGGRO_RANGE = 30.0
const PORTAL_TRIGGER_RANGE = 1.7
const STAGE_SPAWN = Vector3(0.0, 0.2, 15.0)
const RESPAWNS_PER_STAGE = 2
const RESPAWN_PROTECTION = 3.0
const RELOAD_DURATION = 1.0
const WALK_SPEED = 5.2
const DASH_SPEED = 17.0
const DASH_DURATION = 0.24
const DASH_COOLDOWN = 2.0
const GRAVITY = 18.0
const SPECIAL_MAX = 15
const SPECIAL_DURATION = 10.0
const KHENE_PREP_DURATION: float = 1.8
const SPECIAL_JUMP_HEIGHT = 12.0
const SPECIAL_LUNGE_SPEED = 55.0
const SPECIAL_KNIFE_DAMAGE = 5
const SPECIAL_AIM_DISTANCE = 10000.0
const BOSS_SPECIAL_COOLDOWN = 2.0
const MAP_LAYOUT = preload("res://MapLayout.gd")
const RELICS = preload("res://RelicWeapons.gd")

var rng = RandomNumberGenerator.new()
var material_cache = {}
var player: CharacterBody3D
var avatar: Node3D
var camera: Camera3D
var first_weapon: Node3D
var first_person = true
var yaw = 0.0
var pitch = -0.04
var tps_mode = true
var aiming = false
var aim_blend = 0.0
var shoulder_side = 1.0
var camera_offset = Vector3(.72,0.0,3.25)
var camera_probe: SphereShape3D
var shot_requested = false
var trigger_held = false
var full_auto = false
var last_empty_notice = -2.0
var has_pistol = false
var special_item_found = false
var special_charge: int = 0
var special_active: bool = false
var special_preparing: bool = false
var special_prepare_elapsed: float = 0.0
var special_unlimited: bool = false
var special_time_left: float = 0.0
var special_cooldown_remaining: float = 0.0
var special_jump_grace = 0.0
var special_lunging = false
var special_lunge_remaining = 0.0
var special_lunge_target = -1
var special_lunge_point = Vector3.ZERO
var special_lunge_timeout = 0.0
var first_knife: Node3D
var third_knife: Node3D
var crosshair
var mode_label: Label
var health = MAX_HP
var damage_shake := 0.0
var medicine_count = 0
var medicines = []
var respawns_left = RESPAWNS_PER_STAGE
var respawn_protection = 0.0
var ammo = 0
var reserve = 0
var reload_remaining = 0.0
var last_shot = 0.0
var stage = 1
var assembled = false
var finished = false
var won = false
var parts_found = 0
var parts = []
var enemies = []
var current_map
var shrines = []
var worshipped_count = 0
var rescued_stage = 0
var rescued_total = 0
var boss_enemy_index = -1
var boss_vulnerable = false
var boss_phase_remaining = 0.0
var boss_phase_label: Label3D
var boss_shield: MeshInstance3D
var boss_spirit_cooldown = 2.4
var boss_spirits = []
var dash_remaining = 0.0
var dash_cooldown = 0.0
var dash_direction = Vector3.ZERO
var transition_pending = false
var portal_open = false
var portal_node: Node3D
var bench_position = Vector3(-4.0, 0.0, 9.0)
var gate_barrier: MeshInstance3D
var message_time = 0.0
var world_time = 0.0

var ammo_label: Label
var objective_label: Label
var prompt_label: Label
var message_label: Label
var end_panel: Control
var end_label: Label
var ui_font: SystemFont
var hud
var game_audio: Node
var sound_settings: Control
var victory_pending = false


func _ready() -> void:
	rng.seed = 2047
	_make_world()
	_make_player()
	_make_pickups()
	_make_enemies()
	_make_ui()
	game_audio = preload("res://GameAudio.gd").new()
	game_audio.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(game_audio)
	sound_settings = hud.sound_settings
	sound_settings.connect("volume_changed", Callable(game_audio, "set_volume_level"))
	sound_settings.connect("sensitivity_changed", Callable(game_audio, "set_look_sensitivity"))
	sound_settings.connect("close_requested", Callable(self, "_close_sound_settings"))
	sound_settings.connect("start_menu_requested", Callable(self, "_return_to_start_menu"))
	sound_settings.call("set_levels", game_audio.call("get_volume_levels"))
	sound_settings.call("set_sensitivity", game_audio.call("get_look_sensitivity"))
	_update_camera(0.0)
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	_show_message("บันทึกจุดเกิดแล้ว • เก็บชิ้นส่วนปืนกระติบ ไหว้ศาลและช่วยชาวบ้าน", 7.0)


func _mat(color: Color, luminous: bool = false) -> StandardMaterial3D:
	var key = color.to_html(true) + ("_light" if luminous else "_plain")
	if material_cache.has(key):
		return material_cache[key]
	var material = StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.92
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	if color.a < 1.0:
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	if luminous:
		material.emission_enabled = true
		material.emission = Color(color.r, color.g, color.b)
		material.emission_energy_multiplier = 2.0
	material_cache[key] = material
	return material


func _box(parent: Node3D, pos: Vector3, size: Vector3, color: Color) -> MeshInstance3D:
	var mesh = BoxMesh.new()
	mesh.size = size
	var node = MeshInstance3D.new()
	node.mesh = mesh
	node.material_override = _mat(color)
	node.position = pos
	parent.add_child(node)
	return node


func _sphere(parent: Node3D, pos: Vector3, scale_size: Vector3, color: Color, luminous: bool = false) -> MeshInstance3D:
	var mesh = SphereMesh.new()
	mesh.radius = 1.0
	mesh.height = 2.0
	mesh.radial_segments = 8
	mesh.rings = 4
	var node = MeshInstance3D.new()
	node.mesh = mesh
	node.material_override = _mat(color, luminous)
	node.position = pos
	node.scale = scale_size
	parent.add_child(node)
	return node


func _cylinder(parent: Node3D, pos: Vector3, top_radius: float, bottom_radius: float, height: float, color: Color) -> MeshInstance3D:
	var mesh = CylinderMesh.new()
	mesh.top_radius = top_radius
	mesh.bottom_radius = bottom_radius
	mesh.height = height
	mesh.radial_segments = 8
	var node = MeshInstance3D.new()
	node.mesh = mesh
	node.material_override = _mat(color)
	node.position = pos
	parent.add_child(node)
	return node


func _make_world() -> void:
	var floor_body = StaticBody3D.new()
	var floor_collision = CollisionShape3D.new()
	var floor_shape = BoxShape3D.new()
	floor_shape.size = Vector3(190.0, 0.3, 250.0)
	floor_collision.shape = floor_shape
	floor_collision.position = Vector3(0.0, -0.18, -55.0)
	floor_body.add_child(floor_collision)
	add_child(floor_body)
	_load_map()


func _load_map() -> void:
	var map_scenes = [
		preload("res://Map1Morning.tscn"), preload("res://Map2LateMorning.tscn"),
		preload("res://Map3Dusk.tscn"), preload("res://Map4Night.tscn")
	]
	current_map = map_scenes[stage - 1].instantiate()
	add_child(current_map)
	if stage == 4:
		current_map.scale = Vector3.ONE * BOSS_MAP_SCALE
	shrines.clear()
	worshipped_count = 0
	for place in current_map.shrine_places:
		shrines.append({"place": current_map.to_global(place), "worshipped": false})
	_make_save_point()


func _make_save_point() -> void:
	var marker = Node3D.new()
	marker.name = "SpawnSavePoint"
	marker.position = current_map.to_local(Vector3(STAGE_SPAWN.x, 0.0, STAGE_SPAWN.z))
	marker.scale = Vector3.ONE / current_map.scale.x
	current_map.add_child(marker)
	_cylinder(marker, Vector3(0.0, 0.02, 0.0), 0.95, 0.95, 0.04, Color("5b816b"))
	_cylinder(marker, Vector3(0.0, 0.05, 0.0), 0.75, 0.75, 0.035, Color("bfe2bc"))
	var post = Node3D.new()
	post.position = Vector3(-1.55, 0.0, 0.0)
	marker.add_child(post)
	_cylinder(post, Vector3(0.0, 0.61, 0.0), 0.075, 0.09, 1.2, Color("775137"))
	_box(post, Vector3(0.0, 1.23, 0.0), Vector3(0.44, 0.13, 0.22), Color("9b7448"))
	_sphere(post, Vector3(0.0, 1.52, 0.0), Vector3(0.18, 0.23, 0.14), Color("72d8c8"), true)
	var light = OmniLight3D.new()
	light.position = Vector3(0.0, 1.45, 0.0)
	light.light_color = Color("8ce7cd")
	light.light_energy = 0.8
	light.omni_range = 3.0
	post.add_child(light)
	var title = Label3D.new()
	title.text = "จุดเซฟ"
	title.position = Vector3(0.0, 1.88, 0.0)
	title.font_size = 30
	title.pixel_size = 0.004
	title.modulate = Color("d7fff0")
	title.font = preload("res://PixelFont.gd").make()
	title.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	post.add_child(title)


func _make_house(place: Vector3, wall_color: Color) -> void:
	var house = Node3D.new()
	house.position = place
	add_child(house)
	var wood = Color("674932")
	var roof = Color("644538")
	for sx in [-1.7, 1.7]:
		for sz in [-1.55, 1.55]:
			_box(house, Vector3(sx, 0.8, sz), Vector3(0.23, 1.6, 0.23), wood)
	_box(house, Vector3(0.0, 1.62, 0.0), Vector3(4.1, 0.18, 3.7), wood)
	_box(house, Vector3(0.0, 2.52, 0.0), Vector3(3.8, 1.7, 3.5), wall_color)
	_box(house, Vector3(0.0, 2.45, -1.79), Vector3(0.8, 1.1, 0.06), Color("2d2d29"))
	for sx in [-1.06, 1.06]:
		var panel = _box(house, Vector3(sx, 3.62, 0.0), Vector3(2.35, 0.18, 4.0), roof)
		panel.rotation.z = 0.48 if sx < 0.0 else -0.48
	_box(house, Vector3(0.0, 0.48, -2.07), Vector3(1.0, 0.22, 1.25), wood)
	_box(house, Vector3(0.0, 0.20, -2.68), Vector3(1.0, 0.20, 0.9), wood)
	for side in [-1.0, 1.0]:
		_box(house, Vector3(side * 1.92, 2.65, 0.0), Vector3(0.045, 0.77, 0.86), Color("302b28"))
		_box(house, Vector3(side * 1.95, 2.65, 0.0), Vector3(0.05, 0.06, 0.84), wood)
		_box(house, Vector3(side * 1.95, 2.65, 0.0), Vector3(0.05, 0.75, 0.055), wood)
		_box(house, Vector3(side * 2.0, 1.87, -1.6), Vector3(0.08, 0.65, 0.08), wood)
	for level in range(6):
		_box(house, Vector3(0, 1.84 + level * 0.25, 1.755), Vector3(3.8, 0.022, 0.022), wall_color.darkened(0.18))
		for side in [-1.0, 1.0]:
			_box(house, Vector3(side * 1.908, 1.84 + level * 0.25, 0), Vector3(0.022, 0.022, 3.5), wall_color.darkened(0.18))
	_box(house, Vector3(0,4.15,0),Vector3(0.14,0.14,4.1),roof.darkened(0.12))
	for sx in [-1.1, 1.1]:
		_box(house, Vector3(sx, 2.62, 1.78), Vector3(0.68, 0.75, 0.045), Color("383729"))
		_box(house, Vector3(sx, 2.62, 1.81), Vector3(0.045, 0.77, 0.05), wood)
		_box(house, Vector3(sx, 2.62, 1.81), Vector3(0.70, 0.045, 0.05), wood)



func _make_lantern(place: Vector3) -> void:
	var lantern = Node3D.new()
	lantern.position = place
	add_child(lantern)
	_box(lantern, Vector3(0.0, 1.2, 0.0), Vector3(0.11, 2.4, 0.11), Color("493b32"))
	_box(lantern, Vector3(0.0, 2.45, 0.0), Vector3(0.6, 0.12, 0.38), Color("493b32"))
	_box(lantern, Vector3(0.2, 2.16, 0.0), Vector3(0.28, 0.4, 0.28), Color("f1af55"))
	var light = OmniLight3D.new()
	light.position = Vector3(0.2, 2.12, 0.0)
	light.light_color = Color("ffc57b")
	light.light_energy = 1.5
	light.omni_range = 6.5
	lantern.add_child(light)


func _make_bench() -> void:
	var bench = Node3D.new()
	bench.position = bench_position
	add_child(bench)
	_box(bench, Vector3(0.0, 0.76, 0.0), Vector3(2.1, 0.18, 1.1), Color("805136"))
	for sx in [-0.78, 0.78]:
		for sz in [-0.36, 0.36]:
			_box(bench, Vector3(sx, 0.37, sz), Vector3(0.16, 0.76, 0.16), Color("62412f"))
	_box(bench, Vector3(-0.45, 0.95, 0.0), Vector3(0.6, 0.2, 0.45), Color("a7774b"))
	_box(bench, Vector3(0.44, 0.96, -0.1), Vector3(0.54, 0.1, 0.34), Color("394a46"))
	_make_lantern(bench_position + Vector3(1.4, 0.0, -0.4))


func _make_shrine() -> void:
	var shrine = Node3D.new()
	shrine.position = Vector3(0.0, 0.0, -61.0)
	add_child(shrine)
	_box(shrine, Vector3(0.0, 0.28, 0.0), Vector3(13.0, 0.55, 11.0), Color("70706d"))
	for sx in [-3.7, 3.7]:
		_box(shrine, Vector3(sx, 2.15, -1.7), Vector3(0.42, 3.4, 0.42), Color("8e6349"))
		_box(shrine, Vector3(sx, 2.15, 1.7), Vector3(0.42, 3.4, 0.42), Color("8e6349"))
	_box(shrine, Vector3(0.0, 3.88, 0.0), Vector3(8.9, 0.22, 6.0), Color("5d453d"))
	var left_roof = _box(shrine, Vector3(-2.1, 4.8, 0.0), Vector3(5.0, 0.22, 6.4), Color("713e39"))
	left_roof.rotation.z = 0.45
	var right_roof = _box(shrine, Vector3(2.1, 4.8, 0.0), Vector3(5.0, 0.22, 6.4), Color("713e39"))
	right_roof.rotation.z = -0.45
	_box(shrine, Vector3(0.0, 1.2, -2.0), Vector3(2.6, 1.3, 1.2), Color("6e584b"))
	_box(shrine, Vector3(0.0, 0.13, 6.0), Vector3(4.0, 0.25, 2.0), Color("777571"))
	for sx in [-5.1, 5.1]:
		_make_lantern(Vector3(sx, 0.0, -56.0))
	var ghost_light = OmniLight3D.new()
	ghost_light.position = Vector3(0.0, 3.0, -62.0)
	ghost_light.light_color = Color("81d6ed")
	ghost_light.light_energy = 1.9
	ghost_light.omni_range = 8.0
	add_child(ghost_light)


func _make_player() -> void:
	player = CharacterBody3D.new()
	player.name = "Vikram"
	player.collision_layer = 2
	player.collision_mask = 1
	player.position = STAGE_SPAWN
	var body_collision = CollisionShape3D.new()
	var capsule = CapsuleShape3D.new()
	capsule.radius = 0.33
	capsule.height = 2.05
	body_collision.shape = capsule
	body_collision.position.y = 1.02
	player.add_child(body_collision)
	add_child(player)

	avatar = preload("res://Vikram.tscn").instantiate()
	player.add_child(avatar)
	avatar.gun.visible = false

	camera = Camera3D.new()
	camera.fov = 68.0
	camera.near = .06
	camera.current = true
	add_child(camera)
	first_weapon=preload("res://FirstPersonWeapon.gd").new()
	first_weapon.name="FirstPersonArms"
	camera.add_child(first_weapon)
	var third_knife_mount := Node3D.new()
	third_knife_mount.name = "ForwardSickleMount"
	third_knife_mount.rotation.x = -PI * .5
	avatar.get_node("RightGripHand").add_child(third_knife_mount)
	third_knife = preload("res://SpecialKnife.gd").new()
	third_knife_mount.add_child(third_knife)
	third_knife.scale = Vector3.ONE * .77
	var first_knife_mount := Node3D.new()
	first_knife_mount.name = "CompactForwardSickleMount"
	first_knife_mount.position = Vector3(.015, -.015, -.07)
	first_knife_mount.rotation = Vector3(-.18, -.06, -.10)
	first_weapon.get_node("RightGripHand").add_child(first_knife_mount)
	first_knife = preload("res://SpecialKnife.gd").new()
	first_knife.upright_view = true
	first_knife_mount.add_child(first_knife)
	first_knife.scale = Vector3.ONE * .58
	avatar.visible=not first_person
	first_weapon.visible=first_person and has_pistol
	camera_probe = SphereShape3D.new()
	camera_probe.radius = .20


func _make_pickups() -> void:
	match stage:
		1:
			_add_part("ตัวเรือนสานกระติบ", current_map.pickup_places[0], 0)
			_add_part("ด้ามไม้แกะและแกนพลัง", current_map.pickup_places[1], 1)
			_add_part("หัวคริสตัลปืนสั้น", current_map.pickup_places[2], 2)
		2:
			_add_part("เรือนลำแคน", current_map.pickup_places[0], 3)
			_add_part("ชุดปลายลำแคน", current_map.pickup_places[1], 4)
			_add_part("แม็กกาซีนไม้โค้ง", current_map.pickup_places[2], 5)
			_add_part("ด้ามจับและไก", current_map.pickup_places[3], 6)
			_add_part("สายรัดคราม", current_map.pickup_places[4], 7)
		3:
			_add_part("เครื่องรางพลังพิเศษ", current_map.pickup_places[0], 8)
	_make_medicines()


func _make_medicines() -> void:
	var route_choices := [0, 3, 7, 10]
	var fractions := [.25, .53, .57, .64]
	var amount := 4 if stage >= 3 else 3
	var routes = MAP_LAYOUT.routes(stage)
	for index in range(amount):
		var segment = routes[route_choices[index]]
		var start: Vector2 = segment[0]
		var end: Vector2 = segment[1]
		var place: Vector2 = start.lerp(end, fractions[index])
		_add_medicine(Vector3(place.x, 0.0, place.y))


func _add_medicine(place: Vector3) -> void:
	var item := Node3D.new()
	item.name = "HealingMedicine"
	item.position = place
	current_map.add_child(item)
	_cylinder(item, Vector3(0.0, .03, 0.0), .44, .50, .06, Color("49624d"))
	_cylinder(item, Vector3(0.0, .07, 0.0), .36, .40, .03, Color("b4deb2"))
	var bottle := Node3D.new()
	bottle.name = "FloatingMedicineBottle"
	bottle.position.y = .61
	item.add_child(bottle)
	_cylinder(bottle, Vector3(0.0, .0, 0.0), .18, .20, .44, Color("dc5266"))
	_cylinder(bottle, Vector3(0.0, .25, 0.0), .085, .09, .13, Color("b7dce0"))
	_cylinder(bottle, Vector3(0.0, .36, 0.0), .13, .12, .12, Color("aa7552"))
	_box(bottle, Vector3(0.0, .0, -.205), Vector3(.22, .20, .025), Color("fff3d7"))
	_box(bottle, Vector3(0.0, .0, -.225), Vector3(.05, .15, .025), Color("d34857"))
	_box(bottle, Vector3(0.0, .0, -.227), Vector3(.15, .05, .025), Color("d34857"))
	var glow := OmniLight3D.new()
	glow.position = Vector3(0.0, .68, 0.0)
	glow.light_color = Color("ec8792")
	glow.light_energy = .65
	glow.omni_range = 2.5
	item.add_child(glow)
	medicines.append({"node": item, "bottle": bottle, "taken": false})


func _add_part(label_text: String, place: Vector3, part_type: int) -> void:
	var item = Node3D.new()
	item.name = "SpecialCharmPickup" if part_type == 8 else "RelicGunPart"
	item.position = place
	add_child(item)
	_box(item, Vector3(0.0, .14, 0.0), Vector3(1.15, .20, 1.00), Color("4b5147"))
	_box(item, Vector3(0.0, .255, 0.0), Vector3(.98, .030, .84), Color("b99661"))
	for rail in [-.39, .39]:
		_box(item, Vector3(rail, .277, 0), Vector3(.025, .014, .78), Color("173d5c"))
	var display = Node3D.new()
	display.name = "FloatingModelPart"
	var display_y = .75 if part_type != 8 else .62
	display.position = Vector3(0, display_y, 0)
	display.rotation.y = PI * .22
	item.add_child(display)
	if part_type < 3:
		var component = RELICS.short_component(display, part_type)
		component.position = Vector3.ZERO
		display.scale = Vector3.ONE * 1.9
	elif part_type < 8:
		var component = RELICS.rapid_component(display, part_type - 3)
		component.position = Vector3.ZERO
		if part_type == 7:
			component.position.z = .12
		display.scale = Vector3.ONE * 1.65
	else:
		var charm = preload("res://SpecialCharm.tscn").instantiate()
		charm.scale *= .9
		display.add_child(charm)
	var marker_y = 1.43 if part_type == 8 else 1.25
	var marker_size = Vector3.ONE * (.08 if part_type == 8 else .09)
	var marker = _sphere(item, Vector3(0.0, marker_y, 0.0), marker_size, Color(.62, .85, .86, .45) if part_type == 8 else Color("f4ce72"), true)
	var pickup_light = OmniLight3D.new()
	pickup_light.position = Vector3(0,1.2,0)
	pickup_light.light_color = Color("a9e9e7") if part_type == 2 or part_type == 4 or part_type == 8 else Color("f4ce72")
	pickup_light.light_energy = 1.1
	pickup_light.omni_range = 4.0
	item.add_child(pickup_light)
	parts.append({"node": item, "display": display, "display_y": display_y, "marker": marker, "marker_y": marker_y, "label": label_text, "taken": false})


func _make_enemies() -> void:
	var names = ["ชาวนา", "แม่ค้า", "ผู้ดูแลหมู่บ้าน", "หญิงสาว"]
	var places = current_map.villager_places
	if stage == 4:
		boss_vulnerable = false
		boss_phase_remaining = BOSS_ATTACK_DURATION
		boss_spirit_cooldown = 1.4
		boss_enemy_index = enemies.size()
		_add_villager(current_map.to_global(Vector3(0.0, 0.0, -96.0)), "ยายจ่อย", true, stage)
		boss_phase_label = Label3D.new()
		boss_phase_label.name = "BossPhase"
		boss_phase_label.position = Vector3(0, 2.7, 0)
		boss_phase_label.font_size = 36
		boss_phase_label.pixel_size = .0025
		boss_phase_label.modulate = Color("a9dce8")
		boss_phase_label.font = preload("res://PixelFont.gd").make()
		boss_phase_label.text = "ช่วยชาวบ้านก่อน"
		enemies[boss_enemy_index]["node"].add_child(boss_phase_label)
		boss_shield = MeshInstance3D.new()
		boss_shield.name = "SpiritShield"
		var shield_mesh = SphereMesh.new()
		shield_mesh.radius = 1.15
		shield_mesh.height = 2.3
		shield_mesh.radial_segments = 16
		shield_mesh.rings = 8
		boss_shield.mesh = shield_mesh
		boss_shield.position.y = 1.15
		var shield_material = StandardMaterial3D.new()
		shield_material.albedo_color = Color(.47, .84, 1.0, .19)
		shield_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		shield_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		shield_material.cull_mode = BaseMaterial3D.CULL_DISABLED
		boss_shield.material_override = shield_material
		enemies[boss_enemy_index]["node"].add_child(boss_shield)
	for index in range(places.size()):
		_add_villager(current_map.to_global(places[index]), "%s %d" % [names[(index + stage - 1) % names.size()], rescued_total + index + 1], false, stage)


func _add_villager(place: Vector3, villager_name: String, boss: bool, encounter_stage: int) -> void:
	var scenes = [preload("res://models/npcs/Farmer.tscn"),preload("res://models/npcs/Vendor.tscn"),preload("res://models/npcs/Elder.tscn"),preload("res://models/npcs/YoungWoman.tscn"),preload("res://models/npcs/Grandmother.tscn")]
	var root = scenes[4 if boss else enemies.size() % 4].instantiate()
	root.name = villager_name
	root.position = place
	add_child(root)
	var target_area = Area3D.new()
	target_area.name = "SpiritTarget"
	target_area.collision_layer = 1
	target_area.collision_mask = 0
	var target_collision = CollisionShape3D.new()
	var target_shape = CapsuleShape3D.new()
	target_shape.radius = .31
	target_shape.height = 1.42
	target_collision.shape = target_shape
	target_collision.position.y = .72
	target_area.add_child(target_collision)
	root.add_child(target_area)
	target_area.set_meta("enemy_id", enemies.size())
	var head_area = Area3D.new()
	head_area.name = "HeadshotTarget"
	head_area.collision_layer = 1
	head_area.collision_mask = 0
	head_area.set_meta("enemy_id", enemies.size())
	head_area.set_meta("headshot", true)
	var head_collision = CollisionShape3D.new()
	var head_shape = SphereShape3D.new()
	head_shape.radius = .23
	head_collision.shape = head_shape
	head_area.add_child(head_collision)
	root.get_node("ClothesAndHead/FaceAndHair").add_child(head_area)
	var maximum = 13 if boss else VILLAGER_HP
	root.call("set_health",maximum,maximum)
	enemies.append({"node":root,"area":target_area,"head_area":head_area,"name":villager_name,"boss":boss,"hp":maximum,"max_hp":maximum,"alive":true,"aggroed":encounter_stage == 4 and not boss,"speed":1.05 if boss else VILLAGER_SPEED,"stage":encounter_stage,"next_attack":0.0,"attack_remaining":0.0,"attack_landed":false})


func _make_ui() -> void:
	var canvas = CanvasLayer.new()
	add_child(canvas)
	hud = preload("res://IsanHUD.gd").new()
	canvas.add_child(hud)
	hud.connect("restart_requested", Callable(self, "_restart_game"))
	ammo_label = hud.ammo_label
	objective_label = hud.objective_label
	prompt_label = hud.prompt_label
	message_label = hud.message_label
	mode_label = hud.mode_label
	end_panel = hud.end_panel
	end_label = hud.end_label
	crosshair = hud.crosshair
	_update_ui()


func _ui_label(parent: Control, content: String, pos: Vector2, dimensions: Vector2, font_size: int) -> Label:
	var label = Label.new()
	label.text = content
	label.position = pos
	label.size = dimensions
	label.add_theme_font_override("font", ui_font)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color("edf3ef"))
	label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.75))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	parent.add_child(label)
	return label


func _input(event: InputEvent) -> void:
	if sound_settings != null and sound_settings.visible:
		return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and not finished:
		var sensitivity = .65 if aiming else 1.0
		var look_sensitivity = game_audio.call("get_look_sensitivity")
		yaw -= event.relative.x * 0.0035 * sensitivity * look_sensitivity
		pitch = clamp(pitch - event.relative.y * 0.0028 * sensitivity * look_sensitivity, -1.43, 0.60)
		if first_person:
			first_weapon.call("add_sway",event.relative)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not finished:
		if event.pressed:
			if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
				Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			else:
				trigger_held = true
				shot_requested = true
		else:
			trigger_held = false
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			_open_sound_settings()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_V and not finished:
			_cycle_view()
		elif event.keycode == KEY_Q and not finished:
			shoulder_side *= -1.0
		elif event.keycode == KEY_E and not finished:
			_interact()
		elif event.keycode == KEY_R and not finished:
			_reload()
		elif event.keycode == KEY_B and not finished and assembled:
			_toggle_fire_mode()
		elif event.keycode == KEY_F and not finished:
			_toggle_special()
		elif event.keycode == KEY_P and not finished:
			_prepare_special_test()
		elif event.keycode == KEY_CTRL and not finished:
			_start_dash()
		elif event.keycode == KEY_ENTER and finished:
			_restart_game()


func _restart_game() -> void:
	if finished:
		get_tree().reload_current_scene()


func _prepare_special_test() -> void:
	if transition_pending:
		return
	if not has_pistol:
		has_pistol = true
		avatar.gun.visible = true
		first_weapon.gun.visible = true
		first_weapon.visible = first_person
		ammo = 8
		reserve = 160
	special_item_found = true
	special_charge = SPECIAL_MAX
	special_cooldown_remaining = 0.0
	_show_message("พร้อมทดสอบพลังเคียว • กด F เพื่อเป่าแคน แล้วเล็งคลิกพุ่ง", 3.0)


func _open_sound_settings() -> void:
	shot_requested = false
	trigger_held = false
	aiming = false
	sound_settings.show()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	get_tree().paused = true


func _close_sound_settings() -> void:
	sound_settings.hide()
	get_tree().paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE if finished else Input.MOUSE_MODE_CAPTURED)


func _return_to_start_menu() -> void:
	get_tree().paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	get_tree().change_scene_to_file("res://MainMenu.tscn")


func _start_dash() -> void:
	if transition_pending or special_preparing or special_lunging or Input.mouse_mode != Input.MOUSE_MODE_CAPTURED or dash_cooldown > 0.0 or dash_remaining > 0.0:
		return
	var forward = Vector3(-sin(yaw), 0.0, -cos(yaw))
	var right = Vector3(cos(yaw), 0.0, -sin(yaw))
	dash_direction = Vector3.ZERO
	if Input.is_key_pressed(KEY_W):
		dash_direction += forward
	if Input.is_key_pressed(KEY_S):
		dash_direction -= forward
	if Input.is_key_pressed(KEY_A):
		dash_direction -= right
	if Input.is_key_pressed(KEY_D):
		dash_direction += right
	if dash_direction.is_zero_approx():
		dash_direction = forward
	dash_direction = dash_direction.normalized()
	dash_remaining = DASH_DURATION
	dash_cooldown = DASH_COOLDOWN


func _toggle_special() -> void:
	if special_preparing:
		return
	if special_active:
		if special_lunging:
			return
		_end_special()
		_show_message("ยกเลิกโหมดเคียวแล้ว", 1.4)
		return
	if not special_item_found or transition_pending:
		return
	if stage == 4 and special_cooldown_remaining > 0.0 and not special_unlimited:
		_show_message("รอพลังเคียวอีก %.1f วินาที" % special_cooldown_remaining, 1.2)
		return
	if special_charge < SPECIAL_MAX and not special_unlimited:
		_show_message("ต้องสะสมพลังวิญญาณให้ครบ %d/%d" % [special_charge, SPECIAL_MAX], 1.5)
		return
	_cancel_reload()
	special_preparing = true
	special_prepare_elapsed = 0.0
	special_jump_grace = 0.0
	dash_remaining = 0.0
	shot_requested = false
	trigger_held = false
	avatar.gun.visible = false
	first_weapon.gun.visible = false
	third_knife.visible = false
	first_knife.visible = false
	first_weapon.visible = first_person
	_show_message("วิกรมกำลังเป่าแคนเรียกพลัง...", KHENE_PREP_DURATION)


func _update_khene_preparation(delta: float) -> void:
	special_prepare_elapsed = minf(special_prepare_elapsed + delta, KHENE_PREP_DURATION)
	var progress: float = special_prepare_elapsed / KHENE_PREP_DURATION
	var pose: float = 1.0
	if progress < .25:
		pose = smoothstep(0.0, .25, progress)
	elif progress > .82:
		pose = 1.0 - smoothstep(.82, 1.0, progress)
	var blowing := progress >= .25 and progress <= .82
	avatar.call("set_khene_pose", pose, blowing)
	first_weapon.call("set_khene_pose", pose, blowing)
	if special_prepare_elapsed >= KHENE_PREP_DURATION:
		_complete_special_activation()


func _complete_special_activation() -> void:
	special_preparing = false
	special_prepare_elapsed = 0.0
	avatar.call("set_khene_pose", 0.0, false)
	first_weapon.call("set_khene_pose", 0.0, false)
	if not special_unlimited:
		special_charge = 0
	special_active = true
	special_time_left = 0.0 if special_unlimited else SPECIAL_DURATION
	third_knife.visible = true
	first_knife.visible = true
	avatar.call("set_sickle_equipped", true)
	first_weapon.call("set_sickle_equipped", true)
	_show_message("โหมดเคียว%s • Space กระโดด 12 ม. • เล็งจุดหมายแล้วคลิกเพื่อพุ่ง" % ("ไม่จำกัด" if special_unlimited else " 10 วินาที"), 3.0)


func _end_special() -> void:
	if not special_active and not special_preparing:
		return
	var was_active: bool = special_active
	if was_active and stage == 4 and not special_unlimited and not transition_pending and not finished:
		special_cooldown_remaining = BOSS_SPECIAL_COOLDOWN
	special_preparing = false
	special_prepare_elapsed = 0.0
	avatar.call("set_khene_pose", 0.0, false)
	first_weapon.call("set_khene_pose", 0.0, false)
	avatar.call("set_sickle_equipped", false)
	first_weapon.call("set_sickle_equipped", false)
	special_active = false
	for enemy in enemies:
		if is_instance_valid(enemy["node"]):
			enemy["node"].call("set_special_health_reveal", false)
	special_time_left = 0.0
	special_jump_grace = 0.0
	special_lunging = false
	avatar.call("set_lunge_pose", false)
	first_weapon.call("set_lunge_pose", false)
	special_lunge_remaining = 0.0
	special_lunge_target = -1
	special_lunge_point = Vector3.ZERO
	special_lunge_timeout = 0.0
	player.velocity.x = 0.0
	player.velocity.z = 0.0
	avatar.gun.visible = has_pistol
	first_weapon.gun.visible = has_pistol
	third_knife.visible = false
	first_knife.visible = false
	trigger_held = false


func _special_attack() -> void:
	if special_lunging:
		return
	if aiming:
		_start_special_lunge()
	else:
		_knife_melee()


func _knife_melee() -> void:
	var origin = player.global_position + Vector3(0.0, 1.35, 0.0)
	var target = _camera_target().point
	var direction = (target - origin).normalized()
	var hit = _ray(origin, origin + direction * 2.7)
	first_knife.call("slash")
	third_knife.call("slash")
	if _is_enemy_hit(hit):
		var enemy_id = int(hit.collider.get_meta("enemy_id"))
		_hit_enemy(enemy_id, SPECIAL_KNIFE_DAMAGE, false)


func _start_special_lunge() -> void:
	var sight = _camera_target(SPECIAL_AIM_DISTANCE)
	special_lunge_target = int(sight.hit.collider.get_meta("enemy_id")) if _is_enemy_hit(sight.hit) else -1
	special_lunge_point = _special_lunge_destination(sight)
	if special_lunge_target >= 0:
		special_lunge_point = enemies[special_lunge_target]["node"].global_position
	special_lunge_remaining = player.global_position.distance_to(special_lunge_point)
	special_lunge_timeout = maxf(1.5, special_lunge_remaining / SPECIAL_LUNGE_SPEED + 1.0)
	special_lunging = true
	avatar.call("set_lunge_pose", true)
	first_weapon.call("set_lunge_pose", true)
	dash_remaining = 0.0
	first_knife.call("slash")
	third_knife.call("slash")
	if special_lunge_remaining <= (2.0 if special_lunge_target >= 0 else 1.2):
		_finish_special_lunge(true)


func _special_lunge_destination(sight: Dictionary) -> Vector3:
	var bounds = MAP_LAYOUT.limits(stage) * (BOSS_MAP_SCALE if stage == 4 else 1.0)
	var point: Vector3 = sight.point
	if sight.hit.is_empty():
		# The sky has no surface to hit; use the map's far side at current height.
		var center = get_viewport().get_visible_rect().size * .5
		var direction = camera.project_ray_normal(center)
		point = camera.global_position + direction * Vector2(bounds.x, bounds.y).length() * 2.0
		point.y = player.global_position.y
	point.x = clampf(point.x, -bounds.x + .5, bounds.x - .5)
	point.z = clampf(point.z, -bounds.y + .5, 19.5)
	return point


func _finish_special_lunge(reached: bool) -> void:
	if reached and special_lunge_target >= 0 and special_lunge_target < enemies.size():
		var enemy = enemies[special_lunge_target]
		if enemy["alive"] and player.global_position.distance_to(enemy["node"].global_position) < 2.5:
			_hit_enemy(special_lunge_target, SPECIAL_KNIFE_DAMAGE, false)
	special_lunging = false
	avatar.call("set_lunge_pose", false)
	first_weapon.call("set_lunge_pose", false)
	special_lunge_remaining = 0.0
	special_lunge_target = -1
	special_lunge_point = Vector3.ZERO
	special_lunge_timeout = 0.0
	player.velocity = Vector3.ZERO


func _physics_process(delta: float) -> void:
	respawn_protection = maxf(respawn_protection - delta, 0.0)
	damage_shake = maxf(damage_shake - delta * 2.6, 0.0)
	if special_preparing and not finished and not transition_pending:
		_update_khene_preparation(delta)
	var controls_active = not finished and not transition_pending and not special_preparing and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED
	dash_cooldown = maxf(dash_cooldown - delta, 0.0)
	special_cooldown_remaining = maxf(special_cooldown_remaining - delta, 0.0)
	if special_active and not special_unlimited and not finished and not transition_pending:
		special_time_left = maxf(special_time_left - delta, 0.0)
		if special_time_left <= 0.0:
			_end_special()
			_show_message("พลังเคียวหมดเวลา", 1.5)
	if not finished:
		_update_reload(delta)
	aiming = controls_active and reload_remaining <= 0.0 and dash_remaining <= 0.0 and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT)
	if not finished:
		var forward = Vector3(-sin(yaw), 0.0, -cos(yaw))
		var right = Vector3(cos(yaw), 0.0, -sin(yaw))
		var move_dir = Vector3.ZERO
		if controls_active and Input.is_key_pressed(KEY_W):
			move_dir += forward
		if controls_active and Input.is_key_pressed(KEY_S):
			move_dir -= forward
		if controls_active and Input.is_key_pressed(KEY_A):
			move_dir -= right
		if controls_active and Input.is_key_pressed(KEY_D):
			move_dir += right
		move_dir = move_dir.normalized()
		var speed = 2.8 if aiming else (RUN_SPEED if controls_active and Input.is_key_pressed(KEY_SHIFT) else WALK_SPEED)
		var dashing = dash_remaining > 0.0 and controls_active
		var lunging_now = special_lunging
		if lunging_now and special_lunge_target >= 0:
			if special_lunge_target >= enemies.size() or not enemies[special_lunge_target]["alive"]:
				special_lunge_target = -1
			else:
				special_lunge_point = enemies[special_lunge_target]["node"].global_position
		var lunge_stop := 2.0 if special_lunge_target >= 0 else 1.2
		if lunging_now and player.global_position.distance_to(special_lunge_point) <= lunge_stop:
			_finish_special_lunge(true)
			lunging_now = false
		var travel_dir = dash_direction if dashing else move_dir
		var travel_speed = DASH_SPEED if dashing else speed
		var lunge_step = 0.0
		if lunging_now:
			var to_target = special_lunge_point - player.global_position
			special_lunge_remaining = to_target.length()
			travel_dir = to_target.normalized()
			lunge_step = minf(SPECIAL_LUNGE_SPEED * delta, maxf(special_lunge_remaining - lunge_stop, 0.0))
			player.velocity = travel_dir * (lunge_step / maxf(delta, .001))
		else:
			player.velocity.x = travel_dir.x * travel_speed
			player.velocity.z = travel_dir.z * travel_speed
		dash_remaining = maxf(dash_remaining - delta, 0.0)
		special_jump_grace = maxf(special_jump_grace - delta, 0.0)
		if not lunging_now:
			if player.is_on_floor():
				player.velocity.y = 0.0
				if controls_active and Input.is_key_pressed(KEY_SPACE):
					player.velocity.y = sqrt(2.0 * GRAVITY * SPECIAL_JUMP_HEIGHT) if special_active else 6.2
					special_jump_grace = .35 if special_active else 0.0
			elif special_active and aiming and special_jump_grace <= 0.0 and player.velocity.y <= 0.0:
				player.velocity.y = maxf(minf(player.velocity.y, 0.0) - 1.5 * delta, -1.0)
			else:
				player.velocity.y -= GRAVITY * delta
		var position_before_move = player.position
		player.move_and_slide()
		var bounds = MAP_LAYOUT.limits(stage) * (BOSS_MAP_SCALE if stage == 4 else 1.0)
		player.global_position.z = clampf(player.global_position.z, -bounds.y, 20.0)
		player.global_position.x = clampf(player.global_position.x, -bounds.x, bounds.x)
		if portal_open and is_instance_valid(portal_node):
			var portal_offset = player.global_position - portal_node.global_position
			portal_offset.y = 0.0
			if portal_offset.length() <= PORTAL_TRIGGER_RANGE:
				_advance_stage()
				return
		if lunging_now:
			var lunge_moved = player.global_position.distance_to(position_before_move)
			special_lunge_timeout = maxf(special_lunge_timeout - delta, 0.0)
			var distance_after = player.global_position.distance_to(special_lunge_point)
			if distance_after <= lunge_stop + .05:
				_finish_special_lunge(true)
			elif special_lunge_timeout <= 0.0 or lunge_moved < lunge_step * .2:
				_finish_special_lunge(false)
				_show_message("ทางพุ่งถูกขวาง ลองเล็งจากมุมอื่น", 1.2)
		avatar.rotation.y = yaw
		var actual_motion = (player.position - position_before_move) / maxf(delta, 0.001)
		actual_motion.y = 0.0
		avatar.call("set_motion", actual_motion.length(), player.is_on_floor(), speed == RUN_SPEED or dashing or lunging_now, pitch)
		avatar.call("set_lunge_pose", special_lunging)
		first_weapon.call("set_lunge_pose", special_lunging)
		avatar.call("set_move_direction", avatar.global_basis.inverse() * Vector3(travel_dir.x, 0.0, travel_dir.z))
		_update_enemies(delta)
		_update_boss_spirits(delta)
	_update_camera(delta)
	if not finished:
		var sight = _camera_target(SPECIAL_AIM_DISTANCE if special_active else 65.0)
		avatar.call("set_aim_target",sight.point,aiming)
		first_weapon.call("set_aim_target",sight.point,aiming)
		first_weapon.call("set_view_motion",Vector2(player.velocity.x,player.velocity.z).length(),aiming,player.global_position.y)
		if first_person:
			first_weapon.call("_update_pose",0.0)
		var solution = {"hit": sight.hit, "blocked": false} if special_active else _shot_solution(sight)
		hud.target_label.text = ""
		if _is_enemy_hit(solution.hit):
			var target_enemy = enemies[int(solution.hit.collider.get_meta("enemy_id"))]
			hud.target_label.text = target_enemy.name
			target_enemy.node.call("focus_health")
		crosshair.set_state(aiming,Vector2(player.velocity.x,player.velocity.z).length(),_is_enemy_hit(solution.hit),solution.blocked)
		if controls_active and (shot_requested or (assembled and full_auto and trigger_held)):
			_shoot()
	shot_requested = false
	crosshair.visible = not finished and not transition_pending and not special_preparing and has_pistol and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED
	_update_ui()


func _process(delta: float) -> void:
	world_time += delta
	if not finished and not transition_pending:
		for medicine in medicines:
			if not medicine["taken"] and medicine_count < MAX_MEDICINE and player.global_position.distance_to(medicine["node"].global_position) < 1.45:
				medicine["taken"] = true
				medicine["node"].visible = false
				medicine_count += 1
				game_audio.call("play_item_pickup")
				_show_message("เก็บยาแล้ว • มี %d/%d ขวด • กด E เพื่อฟื้นเลือด 50" % [medicine_count, MAX_MEDICINE], 2.4)
	for index in range(medicines.size()):
		var medicine = medicines[index]
		if not medicine["taken"]:
			medicine["bottle"].position.y = .61 + .09 * sin(world_time * 2.6 + index)
			medicine["bottle"].rotation.y += delta * .75
	for index in range(parts.size()):
		var part = parts[index]
		if not part["taken"]:
			part["marker"].position.y = part["marker_y"] + 0.12 * sin(world_time * 2.4 + index)
			part["display"].position.y = part["display_y"] + 0.07 * sin(world_time * 2.4 + index)
			part["display"].rotation.y += delta * 0.55
	if message_time > 0.0:
		message_time -= delta
		if message_time <= 0.0:
			message_label.text = ""


func _update_camera(delta: float) -> void:
	var weight = 1.0-exp(-delta*12.0) if delta>0 else 1.0
	aim_blend = lerpf(aim_blend,1.0 if aiming else 0.0,weight)
	if first_person:
		camera.global_transform=Transform3D(Basis.from_euler(Vector3(pitch,yaw,0)),player.global_position+Vector3(0,1.68,0))
		camera.fov=lerpf(camera.fov,84.0 if special_lunging else lerpf(74.0,56.0,aim_blend),weight)
		_apply_camera_shake()
		return
	var distance = lerpf(3.25 if tps_mode else 5.3,1.85,aim_blend)
	var shoulder = lerpf(.72 if tps_mode else 1.15,.52,aim_blend)*shoulder_side
	camera_offset = camera_offset.lerp(Vector3(shoulder,0,distance),weight)
	var pivot = player.global_position+Vector3(0,1.62,0)
	var rotation_basis = Basis.from_euler(Vector3(pitch,yaw,0))
	var motion = rotation_basis*camera_offset
	# Sweep a sphere so the camera near plane stays clear of walls and trees.
	var query = PhysicsShapeQueryParameters3D.new()
	query.shape = camera_probe
	query.transform = Transform3D(Basis.IDENTITY,pivot)
	query.motion = motion
	query.margin = .04
	query.collision_mask = 1
	query.collide_with_areas = false
	query.exclude = [player.get_rid()]
	var fractions = get_world_3d().direct_space_state.cast_motion(query)
	var fraction = fractions[0] if not fractions.is_empty() else 1.0
	camera.global_transform = Transform3D(rotation_basis,pivot+motion*fraction)
	camera.fov = lerpf(camera.fov,81.0 if special_lunging else lerpf(68.0 if tps_mode else 75.0,49.0,aim_blend),weight)
	_apply_camera_shake()


func _apply_camera_shake() -> void:
	if damage_shake > 0.0:
		camera.global_position += Vector3(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0), 0.0) * damage_shake * .075


func _cycle_view() -> void:
	if first_person:
		first_person=false
		tps_mode=true
	elif tps_mode:
		tps_mode=false
	else:
		first_person=true
	avatar.visible=not first_person
	first_weapon.visible=first_person and (has_pistol or special_preparing or special_active)
	first_weapon.recoil=0.0
	first_weapon.fire_time=0.0
	_update_camera(0.0)
	_show_message("มุมกล้อง: "+("FPS" if first_person else ("TPS" if tps_mode else "สำรวจ")),1.5)


func _active_weapon() -> Node3D:
	return first_weapon if first_person else avatar


func _ray(start: Vector3, end: Vector3) -> Dictionary:
	var query = PhysicsRayQueryParameters3D.create(start,end,1,[player.get_rid()])
	query.collide_with_areas = true
	query.hit_from_inside = true
	return get_world_3d().direct_space_state.intersect_ray(query)


func _camera_target(max_distance: float = 65.0) -> Dictionary:
	var center = get_viewport().get_visible_rect().size*.5
	var origin = camera.project_ray_origin(center)
	var endpoint = origin+camera.project_ray_normal(center)*max_distance
	var hit = _ray(origin,endpoint)
	return {"point":hit.position if not hit.is_empty() else endpoint,"hit":hit}


func _shot_solution(sight: Dictionary) -> Dictionary:
	var weapon_model=_active_weapon()
	var muzzle: Vector3 = weapon_model.call("get_muzzle_position")
	var target: Vector3 = sight.point
	var direction = target-muzzle
	# Cast from the weapon too: the camera may see around cover while the gun cannot.
	var hit = _ray(camera.global_position if first_person else weapon_model.call("get_weapon_origin"),muzzle)
	if hit.is_empty() and direction.length()>.001:
		hit = _ray(muzzle,target+direction.normalized()*.025)
	var point: Vector3 = hit.position if not hit.is_empty() else target
	return {"point":point,"hit":hit,"blocked":not hit.is_empty() and point.distance_to(target)>.08}


func _is_enemy_hit(hit: Dictionary) -> bool:
	if hit.is_empty():
		return false
	var collider = hit.get("collider")
	if not is_instance_valid(collider) or not collider.has_meta("enemy_id"):
		return false
	var index = int(collider.get_meta("enemy_id"))
	return index>=0 and index<enemies.size() and enemies[index].alive and enemies[index].stage<=stage


func _update_enemies(delta: float) -> void:
	if victory_pending or transition_pending:
		return
	var now = float(Time.get_ticks_msec()) / 1000.0
	var reveal_health = special_active and not player.is_on_floor()
	for enemy in enemies:
		if enemy["stage"] > stage:
			continue
		var enemy_node: Node3D = enemy["node"]
		enemy_node.call("set_special_health_reveal", reveal_health and enemy["alive"] and enemy["stage"] == stage)
		if not enemy["alive"]:
			enemy_node.call("set_nearby", player.global_position.distance_to(enemy_node.global_position) < 24.0)
			continue
		var displacement = player.global_position - enemy_node.global_position
		displacement.y = 0.0
		var distance = displacement.length()
		var in_aggro_range = distance <= VILLAGER_AGGRO_RANGE
		if not enemy["boss"] and in_aggro_range:
			enemy["aggroed"] = true
		var chasing = not enemy["boss"] and bool(enemy["aggroed"])
		var nearby = distance < 34.0 or chasing
		enemy_node.call("set_nearby", nearby)
		if enemy["attack_remaining"] > 0.0:
			enemy_node.call("set_walking", false)
			enemy["attack_remaining"] = maxf(enemy["attack_remaining"] - delta, 0.0)
			if not enemy["attack_landed"] and enemy["attack_remaining"] <= 0.30:
				enemy["attack_landed"] = true
				if distance <= 2.0 and dash_remaining <= 0.0 and not special_lunging and respawn_protection <= 0.0:
					_apply_player_damage(16 if enemy["boss"] else 9, "วิกรมถูกชาวบ้านที่ถูกสิงโจมตี!")
					if finished or respawn_protection > 0.0:
						return
			continue
		if not nearby:
			enemy_node.call("set_walking", false)
			continue
		if chasing and distance <= 2.0 and now >= enemy["next_attack"]:
			enemy_node.call("set_walking", false)
			if distance > 0.001:
				enemy_node.rotation.y = atan2(-displacement.x, -displacement.z)
			enemy_node.call("start_attack")
			enemy["attack_remaining"] = 0.62
			enemy["attack_landed"] = false
			enemy["next_attack"] = now + 1.35
			continue
		var approaching = chasing and distance > 1.45
		enemy_node.call("set_walking", approaching, float(enemy["speed"]))
		if approaching:
			enemy_node.global_position += displacement.normalized() * minf(float(enemy["speed"]) * delta, distance - 1.45)
			enemy_node.rotation.y = atan2(-displacement.x, -displacement.z)


func _apply_player_damage(amount: int, notice: String) -> void:
	health = maxi(health - amount, 0)
	damage_shake = minf(damage_shake + .55, 1.0)
	hud.damage_flash.flash(amount)
	_show_message(notice, 1.3)
	if health == 0:
		_handle_player_death()


func _spawn_boss_spirit(origin: Vector3, offset: float) -> void:
	var spirit = Node3D.new()
	spirit.name = "GrandmotherSpiritAttack"
	spirit.global_position = origin + Vector3(offset, 1.65, 0.0)
	add_child(spirit)
	_sphere(spirit, Vector3.ZERO, Vector3(.44, .56, .30), Color(.62, .84, .98, .50), true)
	_sphere(spirit, Vector3(0.0, -.25, .07), Vector3(.28, .37, .22), Color(.72, .91, 1.0, .22), true)
	_sphere(spirit, Vector3(-.15, .10, -.26), Vector3(.055, .08, .025), Color(.22, .42, .58, .75), true)
	_sphere(spirit, Vector3(.15, .10, -.26), Vector3(.055, .08, .025), Color(.22, .42, .58, .75), true)
	for side in [-1.0, 1.0]:
		_sphere(spirit, Vector3(side * .34, -.28, .04), Vector3(.11, .34, .12), Color(.67, .87, .98, .28), true).rotation.z = side * .48
	var glow = OmniLight3D.new()
	glow.light_color = Color(.56, .80, 1.0)
	glow.light_energy = 1.1
	glow.omni_range = 3.5
	spirit.add_child(glow)
	var direction = ((player.global_position + Vector3(0.0, 1.0, 0.0)) - spirit.global_position).normalized()
	boss_spirits.append({"node": spirit, "direction": direction, "age": 0.0})


func _clear_boss_spirits() -> void:
	for spirit in boss_spirits:
		spirit["node"].queue_free()
	boss_spirits.clear()


func _update_boss_spirits(delta: float) -> void:
	if finished or stage != 4 or transition_pending or victory_pending:
		return
	if boss_enemy_index >= 0 and boss_enemy_index < enemies.size():
		var boss = enemies[boss_enemy_index]
		if boss["alive"]:
			var boss_position: Vector3 = boss["node"].global_position
			boss_phase_remaining = maxf(boss_phase_remaining - delta, 0.0)
			if boss_phase_remaining <= 0.0:
				if rescued_stage < MAP_VILLAGER_COUNTS[3]:
					boss_phase_remaining = BOSS_ATTACK_DURATION
				elif not boss_vulnerable:
					_open_boss_window()
					_show_message("เกราะวิญญาณของยายจ่อยเปิด! โจมตีได้ 3 วินาที", 2.0)
				else:
					boss_vulnerable = false
					boss_phase_remaining = BOSS_ATTACK_DURATION
					boss_spirit_cooldown = .3
					boss_phase_label.text = "เกราะวิญญาณ"
					boss_phase_label.modulate = Color("a9dce8")
					boss_shield.visible = true
					_show_message("ยายจ่อยเริ่มปล่อยวิญญาณอีกครั้ง", 1.5)
			if not boss_vulnerable:
				boss_spirit_cooldown -= delta
				if boss_spirit_cooldown <= 0.0:
					_spawn_boss_spirit(boss_position, -0.85)
					_spawn_boss_spirit(boss_position, 0.85)
					boss_spirit_cooldown = BOSS_SPIRIT_INTERVAL
	for index in range(boss_spirits.size() - 1, -1, -1):
		var spirit = boss_spirits[index]
		var node: Node3D = spirit["node"]
		spirit["age"] += delta
		node.global_position += spirit["direction"] * BOSS_SPIRIT_SPEED * delta
		node.position.y += sin(spirit["age"] * 9.0) * .004
		node.rotation.y += delta * 2.8
		var target = player.global_position + Vector3(0.0, 1.0, 0.0)
		if node.global_position.distance_to(target) < 1.0:
			if dash_remaining <= 0.0 and not special_lunging and respawn_protection <= 0.0:
				_apply_player_damage(12, "วิญญาณของยายจ่อยโจมตีวิกรม!")
				if finished or respawn_protection > 0.0:
					return
			node.queue_free()
			boss_spirits.remove_at(index)
			if finished:
				return
		elif spirit["age"] > 7.0:
			node.queue_free()
			boss_spirits.remove_at(index)


func _open_boss_window() -> void:
	if boss_enemy_index < 0 or boss_enemy_index >= enemies.size() or not enemies[boss_enemy_index]["alive"]:
		return
	boss_vulnerable = true
	boss_phase_remaining = BOSS_VULNERABLE_DURATION
	boss_phase_label.text = "โจมตีได้!"
	boss_phase_label.modulate = Color("f8d38b")
	boss_shield.visible = false
	_clear_boss_spirits()


func _shoot() -> void:
	if special_preparing:
		return
	if special_active:
		trigger_held = false
		_special_attack()
		return
	if reload_remaining > 0.0:
		return
	if not has_pistol:
		_show_message("เก็บชิ้นส่วนปืนกระติบ 3 ชิ้นก่อน", 1.2)
		return
	var now = float(Time.get_ticks_msec()) / 1000.0
	var shot_interval = 0.12 if assembled and full_auto else (0.24 if assembled else 0.42)
	if now - last_shot < shot_interval:
		return
	if ammo <= 0:
		if now - last_empty_notice > 1.0:
			_show_message("กระสุนหมด! กด R เพื่อบรรจุ", 1.4)
			last_empty_notice = now
		return
	last_shot = now
	ammo -= 1
	game_audio.call("play_shot")
	var weapon_model=_active_weapon()
	weapon_model.call("play_shot")
	crosshair.shot()
	var solution = _shot_solution(_camera_target())
	var result: Dictionary = solution.hit
	var end_point: Vector3 = solution.point
	var impact_normal = Vector3.UP
	var spirit_hit = false
	if not result.is_empty():
		end_point = result["position"]
		impact_normal = result["normal"]
		var collider = result["collider"]
		if _is_enemy_hit(result):
			var enemy_id = int(collider.get_meta("enemy_id"))
			var guarded = enemies[enemy_id]["boss"] and (rescued_stage < MAP_VILLAGER_COUNTS[3] or not boss_vulnerable)
			spirit_hit = not guarded
			if not guarded:
				crosshair.hit()
			var damage = int(enemies[enemy_id]["hp"]) if collider.get_meta("headshot", false) else (2 if assembled else 1)
			_hit_enemy(enemy_id, damage)
	weapon_model.call("fire_trace",end_point,impact_normal,not result.is_empty(),spirit_hit)


func _toggle_fire_mode() -> void:
	full_auto = not full_auto
	_show_message("ปืนลำแคน: %s" % ("ยิงรัว" if full_auto else "ยิงทีละนัด"), 1.4)


func _hit_enemy(index: int, damage: int, award_charge: bool = true) -> void:
	if index < 0 or index >= enemies.size():
		return
	var enemy = enemies[index]
	if not enemy["alive"] or enemy["stage"] > stage:
		return
	if enemy["boss"] and rescued_stage < MAP_VILLAGER_COUNTS[3]:
		_show_message("ต้องช่วยชาวบ้านให้ครบก่อนจึงโจมตียายจ่อยได้ (%d/%d)" % [rescued_stage, MAP_VILLAGER_COUNTS[3]], 1.6)
		return
	if enemy["boss"] and not boss_vulnerable:
		_show_message("ยายจ่อยมีเกราะวิญญาณ รออีก %.1f วินาที" % boss_phase_remaining, 1.2)
		return
	game_audio.call("play_hit")
	enemy["hp"] = maxi(enemy["hp"]-damage,0)
	enemy["node"].call("receive_hit",enemy["hp"],enemy["max_hp"])
	if enemy["hp"] <= 0:
		_exorcise(enemy, award_charge)
	else:
		_show_message("โดนวิญญาณ %s" % enemy["name"], 0.8)


func _exorcise(enemy: Dictionary, award_charge: bool) -> void:
	enemy["alive"] = false
	game_audio.call("play_spirit", enemy["node"].global_position)
	enemy["node"].call("release_spirit")
	enemy["area"].collision_layer = 0
	enemy["head_area"].collision_layer = 0
	if enemy["boss"]:
		_clear_boss_spirits()
		boss_phase_label.visible = false
		boss_shield.visible = false
		_show_message("ผีทะนงทวยออกจากร่างยายจ่อยแล้ว", 2.3)
	else:
		rescued_stage += 1
		rescued_total += 1
		if stage == 4 and rescued_stage >= MAP_VILLAGER_COUNTS[3] and not special_unlimited:
			special_unlimited = true
			special_cooldown_remaining = 0.0
			_open_boss_window()
			_show_message("ช่วยชาวบ้านครบแล้ว! พลังเคียวไม่จำกัด • เกราะยายจ่อยเปิด 3 วินาที", 3.0)
		var just_filled = special_item_found and award_charge and special_charge == SPECIAL_MAX - 1
		if special_item_found and award_charge:
			special_charge = mini(special_charge + 1, SPECIAL_MAX)
		if just_filled and not special_unlimited:
			_show_message("พลังวิญญาณเต็มแล้ว กด F เพื่อใช้เคียว", 2.4)
		elif not special_unlimited:
			_show_message("ปลดปล่อย %s จากวิญญาณแล้ว" % enemy["name"], 2.2)
	_check_stage_clear()


func _check_stage_clear() -> void:
	if transition_pending or portal_open or finished or worshipped_count < shrines.size():
		return
	if stage == 2 and not assembled:
		return
	if stage == 3 and not special_item_found:
		return
	if stage == 4 and rescued_stage < MAP_VILLAGER_COUNTS[3]:
		return
	for enemy in enemies:
		if enemy["alive"]:
			return
	_end_special()
	_cancel_reload()
	shot_requested = false
	trigger_held = false
	if stage == 4:
		transition_pending = true
		victory_pending = true
		_show_message("ไหว้ศาลและช่วยทุกคนครบแล้ว ยายจ่อยเป็นอิสระ!", 2.6)
		get_tree().create_timer(2.6).timeout.connect(func():
			if not finished:
				_finish(true))
	else:
		_make_stage_portal()
		portal_open = true
		game_audio.call("play_portal")
		_show_message("ภารกิจแผนที่ %d สำเร็จ ประตูมิติปรากฏขึ้นแล้ว เดินเข้าไปเพื่อไปต่อ" % stage, 4.0)


func _make_stage_portal() -> void:
	portal_node = Node3D.new()
	portal_node.name = "StagePortal"
	add_child(portal_node)
	var hub: Vector2 = MAP_LAYOUT.routes(stage)[0][1]
	portal_node.global_position = current_map.to_global(Vector3(hub.x, 0.0, hub.y))
	var surface = MeshInstance3D.new()
	surface.name = "PortalSurface"
	var surface_mesh = QuadMesh.new()
	surface_mesh.size = Vector2(1.6, 2.35)
	surface.mesh = surface_mesh
	surface.position = Vector3(0.0, 1.08, 0.0)
	var portal_shader = Shader.new()
	portal_shader.code = """
	shader_type spatial;
	render_mode unshaded, cull_disabled, blend_mix, depth_draw_never;

	float hash_cell(vec2 cell) {
		return fract(sin(dot(cell, vec2(127.1, 311.7))) * 43758.5453);
	}

	void fragment() {
		vec2 point = UV * 2.0 - 1.0;
		float radius = length(point);
		float angle = atan(point.y, point.x);
		float edge_wobble = sin(angle * 7.0 + TIME * 0.16) * 0.055 + sin(angle * 13.0 - TIME * 0.21) * 0.035 + sin(angle * 23.0 + TIME * 0.12) * 0.018;
		float edge_distance = 1.0 + edge_wobble - radius;
		float turbulence = sin(angle * 3.0 + radius * 12.0 + TIME * 0.35) * 0.32;
		float spiral = sin(radius * 34.0 - angle * 3.4 + turbulence + TIME * 0.55);
		float bands = smoothstep(-0.48, 0.28, spiral);
		vec3 color = mix(vec3(0.035, 0.39, 0.19), vec3(0.19, 0.61, 0.24), bands);
		color = mix(color, vec3(0.66, 0.84, 0.29), smoothstep(0.48, 0.82, spiral));
		float rim = 1.0 - smoothstep(0.015, 0.11, abs(edge_distance));
		color = mix(color, vec3(0.76, 0.94, 0.39), rim * 0.78);
		float fleck_grid = hash_cell(floor(UV * vec2(18.0, 21.0)));
		vec2 local_cell = fract(UV * vec2(18.0, 21.0));
		vec2 fleck_center = vec2(hash_cell(floor(UV * vec2(18.0, 21.0)) + 4.7), hash_cell(floor(UV * vec2(18.0, 21.0)) + 9.2));
		float fleck_radius = mix(0.08, 0.22, hash_cell(floor(UV * vec2(18.0, 21.0)) + 2.1));
		float flecks = (1.0 - smoothstep(fleck_radius, fleck_radius + 0.07, distance(local_cell, fleck_center))) * step(0.73, fleck_grid) * smoothstep(0.52, 0.86, radius);
		color = mix(color, vec3(0.94, 0.98, 0.82), flecks);
		float edge = smoothstep(-0.018, 0.018, edge_distance);
		ALBEDO = color;
		EMISSION = color * 0.18;
		ALPHA = edge;
	}
	"""
	var surface_material = ShaderMaterial.new()
	surface_material.shader = portal_shader
	surface.material_override = surface_material
	portal_node.add_child(surface)


func _reload() -> void:
	if reload_remaining > 0.0 or transition_pending or special_preparing or special_active:
		return
	if not has_pistol:
		_show_message("ยังไม่มีปืนให้บรรจุกระสุน", 1.2)
		return
	var capacity = 20 if assembled else 8
	var amount = min(capacity - ammo, reserve)
	if amount <= 0:
		_show_message("ยังไม่ต้องบรรจุกระสุน", 1.2)
		return
	reload_remaining = RELOAD_DURATION
	shot_requested = false
	trigger_held = false
	avatar.call("set_reload_progress",0.0)
	first_weapon.call("set_reload_progress",0.0)
	game_audio.call("play_reload")
	_show_message("กำลังบรรจุกระสุน...", RELOAD_DURATION)


func _update_reload(delta: float) -> void:
	if reload_remaining <= 0.0:
		return
	reload_remaining = maxf(reload_remaining - delta, 0.0)
	if reload_remaining > 0.0:
		var progress = 1.0 - reload_remaining / RELOAD_DURATION
		avatar.call("set_reload_progress",progress)
		first_weapon.call("set_reload_progress",progress)
		return
	var capacity = 20 if assembled else 8
	var amount = mini(capacity - ammo, reserve)
	ammo += amount
	reserve -= amount
	avatar.call("set_reload_progress",-1.0)
	first_weapon.call("set_reload_progress",-1.0)
	_show_message("บรรจุกระสุนแล้ว", 1.0)


func _cancel_reload() -> void:
	if reload_remaining <= 0.0:
		return
	reload_remaining = 0.0
	avatar.call("set_reload_progress",-1.0)
	first_weapon.call("set_reload_progress",-1.0)
	game_audio.call("stop_reload")


func _interact() -> void:
	if transition_pending:
		return
	for part in parts:
		if not part["taken"] and player.global_position.distance_to(part["node"].global_position) < 2.25:
			part["taken"] = true
			part["node"].visible = false
			game_audio.call("play_item_pickup")
			match stage:
				1:
					parts_found += 1
					if parts_found == 3:
						_unlock_pistol()
					else:
						_show_message("เก็บ%sแล้ว (%d/3)" % [part["label"], parts_found], 2.0)
				2:
					parts_found += 1
					if parts_found == 5:
						_equip_ak()
					else:
						_show_message("เก็บ%sแล้ว (%d/5)" % [part["label"], parts_found], 2.0)
				3:
					special_item_found = true
					_show_message("ได้เครื่องรางแล้ว! ช่วยชาวบ้านเพื่อสะสมพลัง 15 หน่วย กด F เมื่อเต็ม", 4.0)
					_check_stage_clear()
			return
	for index in range(shrines.size()):
		if not shrines[index]["worshipped"] and player.global_position.distance_to(shrines[index]["place"]) < 2.7:
			shrines[index]["worshipped"] = true
			worshipped_count += 1
			current_map.mark_worshipped(index)
			game_audio.call("play_shrine")
			_show_message("ไหว้ศาลพระภูมิแล้ว (%d/%d)" % [worshipped_count, shrines.size()], 2.0)
			_check_stage_clear()
			return
	_use_medicine()


func _use_medicine() -> void:
	if medicine_count <= 0:
		_show_message("ยังไม่มียา • เดินหาแสงสีแดงตามพื้น", 1.5)
		return
	if health >= MAX_HP:
		_show_message("เลือดเต็มอยู่แล้ว", 1.3)
		return
	medicine_count -= 1
	var restored := mini(MEDICINE_HEAL, MAX_HP - health)
	health += restored
	_show_message("ใช้ยาแล้ว • ฟื้นเลือด %d" % restored, 1.8)


func _unlock_pistol() -> void:
	has_pistol = true
	avatar.gun.visible = true
	first_weapon.visible = first_person
	ammo = 8
	reserve = 160
	game_audio.call("play_craft")
	_show_message("ประกอบปืนสั้นกระติบสำเร็จ! ใช้ยิงช่วยชาวบ้านได้แล้ว", 3.0)


func _equip_ak() -> void:
	_cancel_reload()
	assembled = true
	avatar.call("set_rifle", true)
	first_weapon.call("set_rifle", true)
	ammo = 20
	reserve = 220
	game_audio.call("play_craft")
	_show_message("ประกอบปืนลำแคนยิงรัวสำเร็จ! กด B เพื่อสลับโหมดยิง", 3.0)
	_check_stage_clear()


func _advance_stage() -> void:
	if stage >= 4 or transition_pending or not portal_open:
		return
	transition_pending = true
	portal_open = false
	if is_instance_valid(portal_node):
		portal_node.queue_free()
	portal_node = null
	_end_special()
	_cancel_reload()
	for enemy in enemies:
		enemy["area"].collision_layer = 0
		enemy["head_area"].collision_layer = 0
		enemy["node"].queue_free()
	enemies.clear()
	_clear_boss_spirits()
	boss_enemy_index = -1
	boss_phase_label = null
	boss_shield = null
	boss_vulnerable = false
	boss_phase_remaining = 0.0
	special_unlimited = false
	special_cooldown_remaining = 0.0
	for part in parts:
		part["node"].queue_free()
	parts.clear()
	medicines.clear()
	current_map.queue_free()
	stage += 1
	parts_found = 0
	rescued_stage = 0
	health = MAX_HP
	respawns_left = RESPAWNS_PER_STAGE
	respawn_protection = 0.0
	if assembled:
		reserve = maxi(reserve, 240 if stage == 4 else 220)
	player.global_position = STAGE_SPAWN
	player.velocity = Vector3.ZERO
	dash_remaining = 0.0
	dash_cooldown = 0.0
	_load_map()
	_make_pickups()
	_make_enemies()
	transition_pending = false
	_show_message("เข้าสู่แผนที่ %d • บันทึกจุดเกิดแล้ว • สำรวจศาลและช่วยชาวบ้าน" % stage, 4.0)


func _update_ui() -> void:
	if hud == null:
		return
	ammo_label.text = "KHENE" if special_preparing else ("SICKLE" if special_active else "%d / %d" % [ammo, reserve])
	hud.reserve_label.text = "กระสุนสำรอง  %d" % reserve
	if special_preparing:
		hud.fire_mode_label.text = "เป่าแคน %.1f วิ" % maxf(KHENE_PREP_DURATION - special_prepare_elapsed, 0.0)
	elif special_active:
		hud.fire_mode_label.text = "เคียว ∞ • พุ่งตามจุดเล็ง" if special_unlimited else "เคียว %.1f วิ • พุ่งตามจุดเล็ง" % special_time_left
	elif stage == 4 and special_cooldown_remaining > 0.0:
		hud.fire_mode_label.text = "พักพลังเคียว %.1f วิ" % special_cooldown_remaining
	elif not has_pistol:
		hud.fire_mode_label.text = "ยังไม่มีปืน"
	elif reload_remaining > 0.0:
		hud.fire_mode_label.text = "บรรจุ %.1f วิ" % reload_remaining
	elif assembled:
		hud.fire_mode_label.text = "ลำแคน • %s [B]" % ("ยิงรัว" if full_auto else "ทีละนัด")
	else:
		hud.fire_mode_label.text = "กระติบ • ทีละนัด"
	hud.health_bar.value = health
	hud.save_label.text = "SAVE %d/%d" % [respawns_left, RESPAWNS_PER_STAGE]
	hud.dash_bar.value = 1.0 - dash_cooldown / DASH_COOLDOWN
	hud.special_meter.set_status(special_charge, special_active, special_item_found, special_time_left, special_unlimited)
	hud.medicine_meter.set_status(medicine_count)
	hud.rescued_label.text = "ชาวบ้าน %d/%d • รวม %d/%d" % [rescued_stage, MAP_VILLAGER_COUNTS[stage - 1], rescued_total, VILLAGER_COUNT]
	mode_label.text = "กล้อง: %s  •  Ctrl Dash" % ("FPS" if first_person else ("TPS" if tps_mode else "สำรวจ"))
	var map_names = ["หมู่บ้านทุ่งนา", "ตลาดและลานฝึก", "ศาลาริมนา", "ศาลท้ายหมู่บ้าน"]
	var day_times = ["เช้า", "สาย", "ใกล้ค่ำ", "ดึก"]
	var item_goal = ""
	match stage:
		1:
			item_goal = "ชิ้นส่วนปืนกระติบ %d/3" % parts_found
		2:
			item_goal = "ปืนลำแคน: ประกอบแล้ว" if assembled else "ชิ้นส่วนปืนลำแคน %d/5" % parts_found
		3:
			item_goal = "พลังวิญญาณ %d/%d • กด F เมื่อเต็ม" % [special_charge, SPECIAL_MAX] if special_item_found else "เครื่องราง: ยังไม่เก็บ"
		4:
			var boss_free = boss_enemy_index >= 0 and not enemies[boss_enemy_index]["alive"]
			var villagers_cleared = rescued_stage >= MAP_VILLAGER_COUNTS[3]
			var phase_text = "เป็นอิสระแล้ว" if boss_free else ("ช่วยชาวบ้านก่อน" if not villagers_cleared else ("โจมตีได้" if boss_vulnerable else "เกราะวิญญาณ"))
			item_goal = "ช่วยชาวบ้าน %d/35 • พลัง%s\nยายจ่อย: %s %s" % [rescued_stage, "ไม่จำกัด" if special_unlimited else "%d/15 จนครบ 35 คน" % special_charge, phase_text, "%.1f วิ" % boss_phase_remaining if villagers_cleared and not boss_free else ""]
	if portal_open:
		item_goal = "เดินเข้าประตูมิติกลางแผนที่เพื่อไปต่อ"
	objective_label.text = "แผนที่ %d/4: %s (%s)\nไหว้ศาลพระภูมิ %d/%d\n%s" % [stage, map_names[stage - 1], day_times[stage - 1], worshipped_count, shrines.size(), item_goal]
	if finished:
		prompt_label.text = ""
		return
	prompt_label.text = ""
	if transition_pending:
		return
	if portal_open and is_instance_valid(portal_node):
		var portal_offset = player.global_position - portal_node.global_position
		portal_offset.y = 0.0
		if portal_offset.length() < 5.0:
			prompt_label.text = "เดินเข้าไป • ไปแผนที่ %d" % (stage + 1)
		return
	for part in parts:
		if not part["taken"] and player.global_position.distance_to(part["node"].global_position) < 2.25:
			prompt_label.text = "กด E • เก็บ%s" % part["label"]
			return
	for shrine in shrines:
		if not shrine["worshipped"] and player.global_position.distance_to(shrine["place"]) < 2.7:
			prompt_label.text = "กด E • ไหว้ศาลพระภูมิ"
			return


func _show_message(content: String, duration: float) -> void:
	if message_label == null:
		return
	message_label.text = content
	message_time = duration


func _handle_player_death() -> void:
	if finished:
		return
	if respawns_left <= 0:
		_finish(false)
		return
	respawns_left -= 1
	_end_special()
	_cancel_reload()
	_clear_boss_spirits()
	shot_requested = false
	trigger_held = false
	aiming = false
	special_lunging = false
	dash_remaining = 0.0
	dash_cooldown = 0.0
	player.velocity = Vector3.ZERO
	player.global_position = STAGE_SPAWN
	yaw = 0.0
	pitch = -0.04
	health = MAX_HP
	respawn_protection = RESPAWN_PROTECTION
	for enemy in enemies:
		enemy["attack_remaining"] = 0.0
		enemy["attack_landed"] = false
		enemy["aggroed"] = enemy["stage"] == 4 and not enemy["boss"]
		enemy["node"].call("set_walking", false)
	_show_message("กลับมาที่จุดเซฟ • เหลือโอกาส %d/%d" % [respawns_left, RESPAWNS_PER_STAGE], 3.0)


func _finish(victory: bool) -> void:
	_end_special()
	_cancel_reload()
	finished = true
	won = victory
	trigger_held = false
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	end_panel.visible = true
	if victory:
		hud.end_heading.text = "VICTORY"
		end_label.text = "ยายจ่อยเป็นอิสระแล้ว!\nวิกรมช่วยชาวบ้านครบทั้ง 4 แผนที่"
	else:
		hud.end_heading.text = "GAME OVER"
		end_label.text = "ใช้โอกาสเกิดใหม่ครบ 2 ครั้งในด่านนี้\nเริ่มใหม่จากแผนที่แรก"
