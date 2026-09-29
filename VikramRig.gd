extends Node3D

const RELICS = preload("res://RelicWeapons.gd")

# The Quaternius Worker skeleton provides locomotion. New faceted geometry is
# driven by its joints; analytic arm IK keeps both palms on the weapon grips.
var model: Node3D
var skeleton: Skeleton3D
var animator: AnimationPlayer
var bones = {}
var materials = {}
var chest: Node3D
var head: Node3D
var hips: Node3D
var pack: Node3D
var sash_tail: Node3D
var gun: Node3D
var khene: Node3D
var khene_weight := 0.0
var khene_blowing := false
var sickle_equipped := false
var lunge_pose_target := false
var lunge_weight := 0.0
var pistol: Node3D
var rifle: Node3D
var pistol_magazine: Node3D
var rifle_magazine: Node3D
var fresh_pistol_magazine: Node3D
var fresh_rifle_magazine: Node3D
var muzzle: Node3D
var flash_light: OmniLight3D
var effects: Node3D
var foot_neutral = {}
var foot_floor = 0.0
var arms = []
var legs = []
var rifle_equipped = false
var move_speed = 0.0
var smoothed_speed = 0.0
var move_direction = Vector3.FORWARD
var running = false
var grounded = true
var aim_pitch = 0.0
var recoil = 0.0
var reload_progress = -1.0
var fire_time = 0.0
var aim_time = 0.0
var aim_weight = 0.0
var aiming_down_sights = false
var has_aim_target = false
var aim_target = Vector3.ZERO
var gun_yaw = 0.0
var age = 0.0
var active_clip = ""
var gun_pitch = -0.12
var hand_error = 0.0
var ik_stretch = 0.0

func _ready() -> void:
	model = $Worker
	skeleton = model.find_child("Skeleton3D", true, false)
	animator = model.find_child("AnimationPlayer", true, false)
	for i in range(skeleton.get_bone_count()):
		bones[skeleton.get_bone_name(i)] = i
	for mesh in model.find_children("*", "MeshInstance3D", true, false):
		mesh.hide()
	# Manual advancement guarantees that the limb geometry uses this frame's pose.
	animator.callback_mode_process = 2
	for clip in ["Idle_Neutral", "Walk", "Run", "Run_Back", "Run_Left", "Run_Right"]:
		animator.get_animation("CharacterArmature|" + clip).loop_mode = Animation.LOOP_LINEAR
	_build_character()
	_build_weapons()
	khene = preload("res://Khene.tscn").instantiate()
	add_child(khene)
	khene.visible = false
	khene.scale = Vector3.ONE * .75
	set_rifle(false)
	_play("Idle_Neutral")
	animator.advance(0.0)
	# The imported rest pose has different yaw on the two feet. Calibrate against
	# a neutral animation pose instead, preserving the animated heel/toe roll.
	animator.seek(0.0, true)
	for suffix in [".L", ".R"]:
		var pose = skeleton.global_transform * skeleton.get_bone_global_pose(bones["Foot"+suffix])
		foot_neutral[suffix] = (global_basis.inverse()*pose.basis).orthonormalized()
	foot_floor = minf(_bone_position("Foot.L").y, _bone_position("Foot.R").y)
	_update_pose(0.0)
	process_priority = 20

func _mat(hex: String) -> StandardMaterial3D:
	if materials.has(hex):
		return materials[hex]
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(hex)
	material.roughness = 0.87
	material.metallic_specular = 0.15
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	materials[hex] = material
	return material

func _node(parent: Node3D, label: String) -> Node3D:
	var n = Node3D.new()
	n.name = label
	parent.add_child(n)
	return n

func _triangle(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3) -> void:
	st.add_vertex(a)
	st.add_vertex(c)
	st.add_vertex(b)

func _rings_mesh(rings: Array) -> ArrayMesh:
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var layers = []
	for r in rings:
		var cut = minf(r.x, r.z) * 0.35
		layers.append([Vector3(-r.x+cut,r.y,-r.z),Vector3(r.x-cut,r.y,-r.z),Vector3(r.x,r.y,-r.z+cut),Vector3(r.x,r.y,r.z-cut),Vector3(r.x-cut,r.y,r.z),Vector3(-r.x+cut,r.y,r.z),Vector3(-r.x,r.y,r.z-cut),Vector3(-r.x,r.y,-r.z+cut)])
	for level in range(layers.size()-1):
		for j in range(8):
			var k = (j+1)%8
			_triangle(st,layers[level][j],layers[level+1][j],layers[level+1][k])
			_triangle(st,layers[level][j],layers[level+1][k],layers[level][k])
	for j in range(8):
		_triangle(st,Vector3(0,rings[0].y,0),layers[0][(j+1)%8],layers[0][j])
		_triangle(st,Vector3(0,rings[-1].y,0),layers[-1][j],layers[-1][(j+1)%8])
	st.generate_normals()
	return st.commit()

func _mesh(parent: Node3D, label: String, mesh: Mesh, position_value: Vector3, color: String) -> MeshInstance3D:
	var n = MeshInstance3D.new()
	n.name = label
	n.mesh = mesh
	n.material_override = _mat(color)
	n.position = position_value
	parent.add_child(n)
	return n

func _bevel(parent: Node3D, label: String, pos: Vector3, size: Vector3, color: String) -> MeshInstance3D:
	var b = minf(size.x, minf(size.y,size.z)) * 0.16
	var mesh = _rings_mesh([Vector3(size.x*.5-b,-size.y*.5,size.z*.5-b),Vector3(size.x*.5,-size.y*.5+b,size.z*.5),Vector3(size.x*.5,size.y*.5-b,size.z*.5),Vector3(size.x*.5-b,size.y*.5,size.z*.5-b)])
	return _mesh(parent,label,mesh,pos,color)

func _ellipsoid(parent: Node3D, label: String, pos: Vector3, size: Vector3, color: String) -> MeshInstance3D:
	var rings = []
	for i in range(7):
		var angle = PI*float(i)/6.0
		var width = maxf(sin(angle),0.10)
		rings.append(Vector3(size.x*width,-cos(angle)*size.y,size.z*width))
	return _mesh(parent,label,_rings_mesh(rings),pos,color)

func _wedge(parent: Node3D, label: String, base: Vector3, tip: Vector3, width: float, depth: float, color: String) -> void:
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var points = [base+Vector3(-width*.5,0,-depth*.5),base+Vector3(width*.5,0,-depth*.5),base+Vector3(width*.5,0,depth*.5),base+Vector3(-width*.5,0,depth*.5)]
	for i in range(4):
		_triangle(st,points[i],points[(i+1)%4],tip)
	_triangle(st,points[0],points[2],points[1])
	_triangle(st,points[0],points[3],points[2])
	st.generate_normals()
	_mesh(parent,label,st.commit(),Vector3.ZERO,color)

func _cylinder(parent: Node3D, label: String, pos: Vector3, radius: float, length: float, color: String) -> MeshInstance3D:
	var mesh = CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = length
	mesh.radial_segments = 10
	var n = _mesh(parent,label,mesh,pos,color)
	n.rotation.x = PI*.5
	return n

func _profile(parent: Node3D, label: String, points: Array, width: float, color: String) -> void:
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var center = Vector2.ZERO
	for p in points:
		center += p
	center /= points.size()
	for i in range(points.size()):
		var p = points[i]
		var q = points[(i+1)%points.size()]
		var a = Vector3(-width*.5,p.x,p.y)
		var b = Vector3(width*.5,p.x,p.y)
		var c = Vector3(width*.5,q.x,q.y)
		var d = Vector3(-width*.5,q.x,q.y)
		_triangle(st,a,b,c)
		_triangle(st,a,c,d)
		_triangle(st,Vector3(-width*.5,center.x,center.y),a,d)
		_triangle(st,Vector3(width*.5,center.x,center.y),c,b)
	st.generate_normals()
	_mesh(parent,label,st.commit(),Vector3.ZERO,color)

func _segment(parent: Node3D, label: String, color: String, taper: float = 0.78) -> MeshInstance3D:
	return _mesh(parent,label,_rings_mesh([Vector3(1,-.5,1),Vector3(taper,.5,taper)]),Vector3.ZERO,color)

func _fit(segment: MeshInstance3D, start: Vector3, end: Vector3, radius: float, depth: float = 1.0) -> void:
	var direction = end-start
	segment.position = (start+end)*.5
	segment.quaternion = Quaternion(Vector3.UP,direction.normalized())
	segment.scale = Vector3(radius,maxf(direction.length(),.001),radius*depth)

func _build_character() -> void:
	chest = _node(self,"ShirtAndBackpack")
	_mesh(chest,"TailoredIndigoShirt",_rings_mesh([Vector3(.19,-.39,.14),Vector3(.168,-.24,.124),Vector3(.207,-.02,.143),Vector3(.212,.065,.132),Vector3(.155,.132,.105)]),Vector3.ZERO,"29466f")
	_bevel(chest,"ButtonPlacket",Vector3(0,-.145,-.143),Vector3(.026,.32,.015),"223c62")
	for y in [-.02,-.10,-.18,-.26]:
		_bevel(chest,"ShirtButton",Vector3(0,y,-.155),Vector3(.010,.010,.007),"71819a")
	_wedge(chest,"NeckOpening",Vector3(0,.14,-.106),Vector3(0,.015,-.153),.10,.022,"c68953")
	_wedge(chest,"LeftCollar",Vector3(-.071,.12,-.116),Vector3(-.033,.025,-.162),.09,.047,"365983")
	_wedge(chest,"RightCollar",Vector3(.071,.12,-.116),Vector3(.033,.025,-.162),.09,.047,"365983")
	_ellipsoid(chest,"Neck",Vector3(0,.155,0),Vector3(.069,.08,.066),"d79861")
	for side in [-1.0,1.0]:
		var strap = _bevel(chest,"LeatherStrap",Vector3(side*.142,-.13,-.149),Vector3(.035,.42,.021),"755032")
		strap.rotation.z = side * .075
		_bevel(chest,"StrapTop",Vector3(side*.14,.09,.012),Vector3(.036,.027,.27),"83603d")
		_bevel(chest,"StrapBuckle",Vector3(side*.15,-.19,-.164),Vector3(.043,.048,.014),"a79b84")
	pack = _node(chest,"LeatherPack")
	_bevel(pack,"Bag",Vector3(0,-.15,.20),Vector3(.32,.40,.19),"785233")
	_bevel(pack,"Lid",Vector3(0,.016,.23),Vector3(.34,.105,.19),"996c43")
	_bevel(pack,"Pocket",Vector3(0,-.24,.309),Vector3(.22,.15,.067),"825939")
	_bevel(pack,"VerticalStrap",Vector3(0,-.105,.31),Vector3(.038,.25,.018),"563d2b")
	_bevel(pack,"MetalBuckle",Vector3(0,-.075,.327),Vector3(.052,.06,.013),"ada795")
	_bevel(pack,"BuckleInset",Vector3(0,-.075,.337),Vector3(.028,.031,.008),"514639")
	for side in [-1.0,1.0]:
		_bevel(pack,"SidePouch",Vector3(side*.192,-.23,.20),Vector3(.09,.17,.14),"8a603d")
	var flashlight = _node(pack,"Flashlight")
	flashlight.position = Vector3(-.218,-.13,.22)
	_cylinder(flashlight,"Body",Vector3.ZERO,.035,.20,"57613d").rotation.x=0
	_cylinder(flashlight,"Head",Vector3(0,.11,0),.046,.047,"313535").rotation.x=0
	_cylinder(flashlight,"Lens",Vector3(0,.137,0),.033,.004,"dfdcb4").rotation.x=0

	head = _node(self,"FaceAndHair")
	_mesh(head,"FacetedFace",_rings_mesh([Vector3(.067,-.17,.075),Vector3(.117,-.105,.111),Vector3(.148,-.025,.128),Vector3(.15,.071,.128),Vector3(.135,.139,.118),Vector3(.089,.173,.077)]),Vector3(0,.16,-.008),"d99a64")
	for side in [-1.0,1.0]:
		_ellipsoid(head,"Ear",Vector3(side*.15,.167,.002),Vector3(.032,.051,.026),"ce8957")
		_bevel(head,"EyeWhite",Vector3(side*.062,.204,-.140),Vector3(.060,.050,.009),"efdfc3")
		_ellipsoid(head,"Iris",Vector3(side*.060,.201,-.148),Vector3(.018,.024,.008),"493226")
		_ellipsoid(head,"Pupil",Vector3(side*.060,.201,-.155),Vector3(.010,.018,.004),"161820")
		_ellipsoid(head,"EyeGlint",Vector3(side*.060-.005,.21,-.159),Vector3(.004,.005,.002),"fcf5df")
		var brow = _bevel(head,"Eyebrow",Vector3(side*.063,.242,-.143),Vector3(.070,.015,.015),"30251f")
		brow.rotation.z = side*.10
	_ellipsoid(head,"Nose",Vector3(0,.159,-.148),Vector3(.021,.028,.026),"d18e57")
	_bevel(head,"Mouth",Vector3(0,.105,-.125),Vector3(.047,.009,.009),"965d40")
	_ellipsoid(head,"BackHair",Vector3(0,.225,.072),Vector3(.148,.137,.092),"302823")
	_ellipsoid(head,"HairMass",Vector3(0,.302,.020),Vector3(.16,.105,.15),"302823")
	for i in range(9):
		var angle = TAU*float(i)/9.0
		var base = Vector3(cos(angle)*.108,.32,.025+sin(angle)*.10)
		var tip = base+Vector3(cos(angle)*.07+.023,.063+float(i%3)*.014,sin(angle)*.075)
		_wedge(head,"SweptHair",base,tip,.13,.12,"302823" if i%2==0 else "3e3027")
	for i in range(5):
		var x = -.118+i*.056
		_wedge(head,"ForeheadLocks",Vector3(x,.33,-.090),Vector3(x-.025,.205+float(i%3)*.018,-.155),.081,.096,"29231f" if i%2==0 else "352922")
	for side in [-1.0,1.0]:
		_wedge(head,"TempleLock",Vector3(side*.142,.279,.002),Vector3(side*.149,.159,-.011),.043,.066,"302823")

	hips = _node(self,"Waist")
	_bevel(hips,"ShortsPelvis",Vector3(0,.075,.015),Vector3(.345,.19,.245),"292a32")
	_bevel(hips,"WovenRedSash",Vector3(0,.145,-.012),Vector3(.39,.075,.275),"963e42")
	_bevel(hips,"SashFold",Vector3(0,.171,-.014),Vector3(.392,.012,.277),"ad5050")
	_bevel(hips,"Knot",Vector3(-.054,.135,-.166),Vector3(.10,.078,.062),"ac4b48")
	sash_tail = _node(hips,"ClothTails")
	sash_tail.position = Vector3(-.052,.112,-.164)
	var tail = _bevel(sash_tail,"LongTail",Vector3(-.02,-.13,0),Vector3(.065,.27,.014),"92393e")
	tail.rotation.z = -.09
	_bevel(sash_tail,"ShortTail",Vector3(.047,-.086,-.008),Vector3(.055,.19,.012),"ac4946").rotation.z=.12

	for side in [-1.0,1.0]:
		var arm = {"side":side,"sleeve":_segment(self,"RolledSleeve","29466f",.92),"cuff":_segment(self,"Cuff","40628c",1.0),"upper":_segment(self,"UpperArm","d99a64",.91),"lower":_segment(self,"Forearm","d49660",.70),"elbow":_ellipsoid(self,"Elbow",Vector3.ZERO,Vector3(.051,.056,.051),"d99a64"),"hand":_build_hand(side)}
		arms.append(arm)
		var foot = _build_foot(side)
		legs.append({"side":side,"shorts":_segment(self,"ShortsLeg","30313a",1.03),"cuff":_segment(self,"ShortsHem","24262f",1.0),"thigh":_segment(self,"ExposedThigh","d99a64",.91),"shin":_segment(self,"Calf","d0925d",.68),"knee":_ellipsoid(self,"Knee",Vector3.ZERO,Vector3(.060,.066,.060),"d99a64"),"foot":foot})

func _build_foot(side: float) -> Node3D:
	var foot = _node(self,"LeftSandal" if side<0 else "RightSandal")
	_bevel(foot,"RubberSole",Vector3(0,.018,-.054),Vector3(.151,.032,.276),"403028")
	_bevel(foot,"LeatherFootbed",Vector3(0,.038,-.054),Vector3(.145,.015,.269),"866042")
	_ellipsoid(foot,"Heel",Vector3(0,.069,.021),Vector3(.052,.034,.063),"cc8e5b")
	_ellipsoid(foot,"Instep",Vector3(0,.076,-.032),Vector3(.059,.040,.093),"d69762")
	_bevel(foot,"Forefoot",Vector3(-side*.005,.059,-.112),Vector3(.118,.035,.099),"d69762")
	# Mirrored toe lengths and inner big toe distinguish the left and right foot.
	for i in range(5):
		var x = side*(-.047+i*.023)
		_ellipsoid(foot,"Toe",Vector3(x,.060,-.158+i*.006),Vector3(.0125-i*.001,.016-i*.001,.026-i*.003),"dda06b")
	for edge in [-1.0,1.0]:
		_bevel(foot,"SideLeather",Vector3(edge*.064,.070,-.045),Vector3(.014,.042,.180),"65452f")
	_bevel(foot,"ToeStrap",Vector3(0,.082,-.111),Vector3(.145,.027,.044),"6e4a32")
	_bevel(foot,"InstepStrap",Vector3(0,.108,-.019),Vector3(.133,.027,.039),"785036").rotation.x=-.14
	_bevel(foot,"HeelStrap",Vector3(0,.088,.067),Vector3(.116,.045,.022),"67462f")
	_bevel(foot,"Buckle",Vector3(side*.074,.094,-.015),Vector3(.013,.025,.032),"b9a585")
	_bevel(foot,"BuckleCenter",Vector3(side*.082,.094,-.015),Vector3(.006,.012,.017),"533e2c")
	return foot

func _build_hand(side: float) -> Node3D:
	var hand = _node(self,"RightGripHand" if side>0 else "LeftSupportHand")
	if side > 0.0:
		# The palm stays beside the grip; fingers curl in front of it instead of
		# intersecting the receiver. The index finger reaches the trigger guard.
		_ellipsoid(hand,"GripPalm",Vector3(0,0,.009),Vector3(.034,.055,.038),"d99a64")
		for i in range(4):
			var finger_y = .032-float(i)*.023
			var finger_z = -.061 if i == 0 else -.031
			_ellipsoid(hand,"Knuckle",Vector3(-.014,finger_y,-.016),Vector3(.018,.013,.018),"d99a64")
			_bevel(hand,"CurledFinger",Vector3(-.039,finger_y,finger_z),Vector3(.052,.016,.028),"d3945e")
			_ellipsoid(hand,"Fingertip",Vector3(-.064,finger_y,finger_z-.004),Vector3(.012,.010,.014),"d99a64")
		var thumb = _bevel(hand,"GripThumb",Vector3(-.036,.043,.028),Vector3(.073,.023,.028),"e1a36d")
		thumb.rotation.z = -.22
	else:
		# The support hand cups the underside of the rifle handguard.
		_ellipsoid(hand,"SupportPalm",Vector3(0,0,.002),Vector3(.039,.032,.057),"d99a64")
		for i in range(4):
			var finger_z = -.046+float(i)*.030
			_bevel(hand,"SupportFinger",Vector3(.032,.024,finger_z),Vector3(.058,.018,.021),"d3945e")
			_ellipsoid(hand,"SupportFingertip",Vector3(.060,.030,finger_z),Vector3(.012,.011,.013),"d99a64")
		_bevel(hand,"SupportThumb",Vector3(-.018,.040,-.017),Vector3(.022,.025,.065),"e1a36d")
	return hand

func _build_weapons() -> void:
	gun = _node(self,"WeaponSocket")
	pistol = _node(gun,"Pistol")
	RELICS.short_component(pistol, 0)
	RELICS.short_component(pistol, 1)
	pistol_magazine = RELICS.short_magazine(pistol)
	RELICS.short_component(pistol, 2)
	fresh_pistol_magazine = _node(self, "FreshPistolMagazine")
	var fresh_pistol_visual: Node3D = RELICS.short_magazine(fresh_pistol_magazine)
	fresh_pistol_visual.position = Vector3.ZERO
	fresh_pistol_magazine.visible = false
	rifle = _node(gun,"Rifle")
	RELICS.rapid_component(rifle, 0)
	RELICS.rapid_component(rifle, 1)
	rifle_magazine = RELICS.rapid_component(rifle, 2)
	RELICS.rapid_component(rifle, 3)
	RELICS.rapid_component(rifle, 4)
	fresh_rifle_magazine = _node(self, "FreshRifleMagazine")
	var fresh_rifle_visual: Node3D = RELICS.rapid_component(fresh_rifle_magazine, 2)
	fresh_rifle_visual.position = Vector3.ZERO
	fresh_rifle_magazine.visible = false
	muzzle = _node(gun,"MuzzleFlash")
	effects = preload("res://ShotEffects.gd").new()
	effects.name = "ShotEffects"
	add_child(effects)
	var flash = _ellipsoid(muzzle,"WhiteHotCore",Vector3(0,0,-.045),Vector3(.022,.022,.078),"fff2bf")
	flash.material_override = effects.material(Color(1.0,.88,.52,.96),true)
	for i in range(5):
		var petal = _ellipsoid(muzzle,"Flame",Vector3.ZERO,Vector3(.014,.014,.065),"ffad3e")
		var angle = TAU*i/5.0
		petal.position = Vector3(cos(angle)*.022,sin(angle)*.022,-.046)
		petal.rotation = Vector3(sin(angle)*.48,-cos(angle)*.48,angle)
		petal.material_override = effects.material(Color(1.0,.46,.08,.55),true)
		petal.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	flash.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	flash_light = OmniLight3D.new()
	flash_light.light_color = Color("ffc875")
	flash_light.omni_range = 1.5
	flash_light.shadow_enabled = false
	muzzle.add_child(flash_light)
	muzzle.hide()

func _bone_position(name: String) -> Vector3:
	return to_local(skeleton.to_global(skeleton.get_bone_global_pose(bones[name]).origin))

func _attach(anchor: Node3D, name: String) -> void:
	var pose = skeleton.global_transform * skeleton.get_bone_global_pose(bones[name])
	var rest = skeleton.global_transform * skeleton.get_bone_global_rest(bones[name])
	anchor.global_transform = Transform3D(pose.basis.orthonormalized()*rest.basis.orthonormalized().inverse()*global_basis.orthonormalized(),pose.origin)

func _play(clip: String) -> void:
	if active_clip == clip:
		return
	active_clip = clip
	animator.play("CharacterArmature|"+clip,.18)

func set_motion(speed: float, on_floor: bool, is_running: bool, pitch: float) -> void:
	move_speed=maxf(speed,0.0)
	grounded=on_floor
	running=is_running
	aim_pitch=pitch

func set_khene_pose(weight: float, is_blowing: bool) -> void:
	khene_weight = clampf(weight, 0.0, 1.0)
	khene_blowing = is_blowing
	if khene != null:
		khene.visible = khene_weight > .001
		khene.call("set_blowing", is_blowing)

func set_sickle_equipped(equipped: bool) -> void:
	sickle_equipped = equipped
	if not equipped:
		lunge_pose_target = false

func set_lunge_pose(active: bool) -> void:
	lunge_pose_target = active

func set_move_direction(direction: Vector3) -> void:
	if direction.length_squared()>.001:
		move_direction=direction.normalized()

func set_aim_target(point: Vector3, is_aiming: bool) -> void:
	aim_target = point
	has_aim_target = true
	aiming_down_sights = is_aiming

func set_rifle(equipped: bool) -> void:
	rifle_equipped=equipped
	if rifle != null:
		rifle.visible=equipped
		pistol.visible=not equipped

func set_reload_progress(progress: float) -> void:
	reload_progress = progress
	if progress < 0.0:
		fresh_pistol_magazine.visible = false
		fresh_rifle_magazine.visible = false

func _reload_weight() -> float:
	if reload_progress < 0.0:
		return 0.0
	return sin(clampf(reload_progress,0.0,1.0)*PI)

func _reload_body_socket() -> Vector3:
	return Vector3(-.23, 1.02, -.08)

func _reload_hand_grip(side: float) -> Vector3:
	var grip = _grip_offset(side)
	if side > 0.0 or reload_progress < 0.0:
		return grip
	var progress = clampf(reload_progress, 0.0, 1.0)
	var magazine_grip = Vector3(-.055, -.20, -.09) if rifle_equipped else Vector3(-.05, -.315, .025)
	var extracted = magazine_grip + Vector3(0.0, -.18, .05)
	var body_grip = gun.transform.affine_inverse() * _reload_body_socket()
	var insert_grip = magazine_grip + Vector3(0.0, -.14, .03)
	if progress < .16:
		return grip.lerp(magazine_grip, smoothstep(0.0, .16, progress))
	if progress < .36:
		return magazine_grip.lerp(extracted, smoothstep(.16, .36, progress))
	if progress < .53:
		return extracted.lerp(body_grip, smoothstep(.36, .53, progress))
	if progress < .61:
		return body_grip
	if progress < .80:
		return body_grip.lerp(insert_grip, smoothstep(.61, .80, progress))
	if progress < .92:
		return insert_grip.lerp(magazine_grip, smoothstep(.80, .92, progress))
	return magazine_grip.lerp(grip, smoothstep(.92, 1.0, progress))

func _pose_magazines() -> void:
	var pistol_seat = Vector3(0.0, -.315, .025)
	var rifle_seat = Vector3(0.0, -.060, -.089)
	pistol_magazine.position = pistol_seat
	rifle_magazine.position = rifle_seat
	pistol_magazine.rotation = Vector3.ZERO
	rifle_magazine.rotation = Vector3.ZERO
	pistol_magazine.visible = true
	rifle_magazine.visible = true
	fresh_pistol_magazine.visible = false
	fresh_rifle_magazine.visible = false
	if reload_progress < 0.0:
		return
	var progress = clampf(reload_progress, 0.0, 1.0)
	var magazine: Node3D = rifle_magazine if rifle_equipped else pistol_magazine
	var fresh: Node3D = fresh_rifle_magazine if rifle_equipped else fresh_pistol_magazine
	var seat = rifle_seat if rifle_equipped else pistol_seat
	if progress >= .16 and progress < .53:
		magazine.position = seat + (_reload_hand_grip(-1.0) - (Vector3(-.055, -.20, -.09) if rifle_equipped else Vector3(-.05, -.315, .025)))
		magazine.rotation.x = -.14 * smoothstep(.16, .36, progress)
	elif progress >= .53 and progress < .86:
		magazine.visible = false
	elif progress >= .86:
		magazine.position = seat + Vector3(0.0, -.14 * (1.0 - smoothstep(.86, .94, progress)), .03 * (1.0 - smoothstep(.86, .94, progress)))
	if progress >= .53 and progress < .86:
		fresh.visible = true
		var palm = gun.transform * _reload_hand_grip(-1.0)
		fresh.transform = Transform3D(gun.basis, palm)

func play_shot() -> void:
	recoil=minf(recoil+.8,1.2)
	fire_time=.075
	aim_time=.42
	# Refresh the two-hand pose before sampling the muzzle for this shot.
	_update_pose(.035)
	muzzle.rotation.z = randf()*TAU
	effects.discharge(get_muzzle_position(),gun.global_basis,gun.to_global(Vector3(.045,.024,-.025)),rifle_equipped,global_position.y)

func fire_trace(end: Vector3, normal: Vector3, collided: bool, spirit: bool) -> void:
	effects.trace(get_muzzle_position(),end,normal,collided,spirit)

func get_muzzle_position() -> Vector3:
	return gun.to_global(Vector3(0,0,-.690) if rifle_equipped else Vector3(0,0,-.325))

func get_weapon_origin() -> Vector3:
	return gun.global_position

func _process(delta: float) -> void:
	age+=delta
	lunge_weight = move_toward(lunge_weight, 1.0 if lunge_pose_target else 0.0, delta * 9.0)
	smoothed_speed=lerpf(smoothed_speed,move_speed,1.0-exp(-delta*12.0))
	var clip="Idle_Neutral"
	if grounded and smoothed_speed>.22:
		clip="Run" if running else "Walk"
		if running and move_direction.z>.4:
			clip="Run_Back"
		elif running and absf(move_direction.x)>.7:
			clip="Run_Right" if move_direction.x>0 else "Run_Left"
	if lunge_pose_target:
		clip="Idle_Neutral"
	_play(clip)
	var cadence=clampf(smoothed_speed/(7.4 if running else 5.2),.65,1.2) if smoothed_speed>.22 else 1.0
	animator.advance(delta*cadence)
	recoil=move_toward(recoil,0.0,delta*6.0)
	fire_time=maxf(fire_time-delta,0.0)
	aim_time=maxf(aim_time-delta,0.0)
	aim_weight=lerpf(aim_weight,1.0 if aim_time>0 or aiming_down_sights else 0.0,1.0-exp(-delta*16.0))
	_update_pose(delta)

func _grip_offset(side: float) -> Vector3:
	if rifle_equipped:
		return Vector3(.052,-.103,.065) if side>0 else Vector3(-.055,-.063,-.255)
	return Vector3(.049,-.086,.035) if side>0 else Vector3(-.052,-.105,.043)

func _update_pose(delta: float) -> void:
	_attach(chest,"Chest")
	_attach(head,"Head")
	_attach(hips,"Hips")
	if lunge_weight > .001:
		chest.rotation.x -= .34 * lunge_weight
		head.position += Vector3(0.0, -.045, -.15) * lunge_weight
		head.rotation.x += .17 * lunge_weight
		hips.rotation.x -= .13 * lunge_weight
	if khene != null and khene_weight > .001:
		var raised := smoothstep(0.0, 1.0, khene_weight)
		var mouth_position := head.position + Vector3(.0, -.135, -.30)
		var low_position := head.position + Vector3(.38, -.75, -.08)
		khene.position = low_position.lerp(mouth_position, raised)
		khene.rotation = Vector3(-.11 * raised, -.08, .16 * (1.0 - raised) + sin(age * 11.0) * (.012 if khene_blowing else 0.0))
	pack.rotation.x=sin(age*8.0)*minf(smoothed_speed/7.4,1.0)*.027
	sash_tail.rotation.x=sin(age*9.0)*minf(smoothed_speed/7.4,1.0)*.15
	var chest_pos=chest.position
	var ready_angle=0.12+(.10 if running and smoothed_speed>1 else 0.0)
	gun.position=chest_pos+Vector3(.13,-.02,-.19) if rifle_equipped else chest_pos+Vector3(.035,-.045,-.32)
	var reload_weight = _reload_weight()
	gun.position += Vector3(.045,-.18,.10)*reload_weight
	gun.position.z+=recoil*.032
	gun.position.y+=aim_weight*.025
	var desired_pitch=aim_pitch
	var desired_yaw=0.0
	if has_aim_target:
		var aim_direction=(to_local(aim_target)-gun.position).normalized()
		desired_pitch=asin(clampf(aim_direction.y,-1.0,1.0))
		desired_yaw=atan2(-aim_direction.x,-aim_direction.z)
	desired_pitch-=ready_angle*(1.0-aim_weight)
	gun_pitch=lerpf(gun_pitch,desired_pitch,1.0-exp(-delta*14.0))
	gun_yaw=lerp_angle(gun_yaw,desired_yaw,1.0-exp(-delta*18.0))
	gun.rotation=Vector3(gun_pitch+recoil*.045-reload_weight*.18,gun_yaw,-reload_weight*.18)
	_pose_magazines()
	# Keep the rigid two-hand grip within both arms' reach, including steep aim
	# and lateral strides, instead of stretching an arm or detaching its hand.
	for iteration in range(5):
		for side in [-1.0,1.0]:
			if sickle_equipped and side < 0.0:
				continue
			var shoulder=_bone_position("UpperArm.R" if side>0 else "UpperArm.L")+Vector3(side*.045,0,0)
			var wrist=gun.transform*_reload_hand_grip(side)+gun.basis.orthonormalized()*Vector3(side*.036,-.032,.025)
			var distance=wrist.distance_to(shoulder)
			if distance>.49:
				gun.position+=(shoulder-wrist).normalized()*(distance-.49)
	muzzle.position=Vector3(0,0,-.705) if rifle_equipped else Vector3(0,0,-.340)
	muzzle.visible=fire_time>0.0
	var flash_amount = clampf(fire_time/.075,0.0,1.0)
	muzzle.scale=Vector3.ONE*(.55+flash_amount*.7)*(1.0 if rifle_equipped else .7)
	flash_light.light_energy = .65*flash_amount
	head.rotation.x+=aim_pitch*.25 + khene_weight * (.045 + sin(age * 10.0) * (.008 if khene_blowing else 0.0))
	hand_error=0.0
	ik_stretch=0.0
	for arm in arms:
		var side=arm.side
		var suffix=".R" if side>0 else ".L"
		var shoulder=_bone_position("UpperArm"+suffix)+Vector3(side*.045,0,0)
		var grip=_reload_hand_grip(side)
		var palm=gun.transform*grip
		var hand_basis=gun.basis.orthonormalized()
		if khene_weight > .001:
			var khene_grip = khene.transform * Vector3(side * .19, .30, -.095)
			palm = palm.lerp(khene_grip, khene_weight)
			hand_basis = hand_basis.slerp(khene.basis.orthonormalized(), khene_weight)
		elif sickle_equipped and side < 0.0:
			palm = shoulder + Vector3(-.09, -.36, -.035)
		if sickle_equipped and lunge_weight > .001:
			var lunge_palm = shoulder + (Vector3(.12, -.15, -.56) if side > 0.0 else Vector3(-.15, -.30, .12))
			palm = palm.lerp(lunge_palm, lunge_weight)
			if side > 0.0:
				hand_basis = hand_basis.slerp(Basis.from_euler(Vector3(-.32, -.12, -.12)), lunge_weight)
		var wrist=palm+hand_basis*Vector3(side*.036,-.032,.025)
		var upper_length=.255
		var lower_length=.245
		var offset=wrist-shoulder
		var distance=offset.length()
		ik_stretch=maxf(ik_stretch,maxf(distance-upper_length-lower_length,0.0))
		var direction=offset.normalized()
		var d=clampf(distance,.06,upper_length+lower_length-.002)
		var along=(upper_length*upper_length-lower_length*lower_length+d*d)/(2*d)
		var bend=Vector3(side*.85,-.7,.3)
		bend=(bend-direction*bend.dot(direction)).normalized()
		var elbow=shoulder+direction*along+bend*sqrt(maxf(upper_length*upper_length-along*along,0.0))
		var cuff_point=shoulder.lerp(elbow,.58)
		_fit(arm.sleeve,shoulder,cuff_point,.078)
		_fit(arm.cuff,shoulder.lerp(elbow,.52),shoulder.lerp(elbow,.65),.082)
		_fit(arm.upper,cuff_point,elbow,.060)
		_fit(arm.lower,elbow,wrist,.054)
		arm.elbow.position=elbow
		arm.hand.transform=Transform3D(hand_basis,palm)
		hand_error=maxf(hand_error,arm.hand.position.distance_to(gun.transform*grip))
	for leg in legs:
		var side=leg.side
		var suffix=".R" if side>0 else ".L"
		var hip=_bone_position("UpperLeg"+suffix)
		var knee=_bone_position("LowerLeg"+suffix)
		var foot_pose = skeleton.global_transform*skeleton.get_bone_global_pose(bones["Foot"+suffix])
		var local_basis = (global_basis.inverse()*foot_pose.basis).orthonormalized()
		leg.foot.basis = local_basis*foot_neutral[suffix].inverse()*Basis(Vector3.UP,-side*.055)
		leg.foot.position = to_local(foot_pose.origin)-Vector3(0,foot_floor,0)
		# Keep the whole sole above the character's support plane during foot roll.
		# The shin endpoint uses the same corrected transform, avoiding ankle gaps.
		if grounded:
			var lowest = INF
			for x in [-.075,.075]:
				for z in [-.192,.084]:
					lowest = minf(lowest,(leg.foot.transform*Vector3(x,.002,z)).y)
			leg.foot.position.y += maxf(.003-lowest,0.0)
		var ankle=leg.foot.position+leg.foot.basis*Vector3(0,.095,0)
		if not grounded:
			knee=hip+Vector3(side*.02,-.29,-.15)
			ankle=knee+Vector3(0,-.27,.18)
			leg.foot.position=ankle-Vector3(0,.095,0)
			leg.foot.rotation=Vector3(.12,0,0)
		if lunge_weight > .001:
			var tucked_knee = hip + Vector3(side * .08, -.20, -.30)
			var tucked_ankle = tucked_knee + Vector3(0.0, -.24, .23)
			knee = knee.lerp(tucked_knee, lunge_weight)
			ankle = ankle.lerp(tucked_ankle, lunge_weight)
			leg.foot.position = leg.foot.position.lerp(ankle - Vector3(0.0, .095, 0.0), lunge_weight)
			leg.foot.rotation.x = lerpf(leg.foot.rotation.x, .48, lunge_weight)
		var hem=hip.lerp(knee,.75)
		_fit(leg.shorts,hip+Vector3(0,.035,0),hem,.103,1.10)
		_fit(leg.cuff,hip.lerp(knee,.69),hip.lerp(knee,.78),.107,1.10)
		_fit(leg.thigh,hem,knee,.066)
		_fit(leg.shin,knee,ankle,.063)
		leg.knee.position=knee
