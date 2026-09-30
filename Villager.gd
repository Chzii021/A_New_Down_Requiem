extends "res://VikramRig.gd"

# Reuse the character's mesh-building helpers, with an independent NPC rig.
@export_enum("Farmer", "Vendor", "Elder", "YoungWoman", "Grandmother") var variant = 0
var possessed = true
var walking = false
var walk_phase_rate = 8.8
var hit_reaction = 0.0
const ATTACK_DURATION = 0.62
var attack_time = 0.0
var npc_body: Node3D
var npc_head: Node3D
var glow_eyes: Node3D
var aura: Node3D
var npc_legs = []
var npc_arms = []
var wisps = []
var flash_materials = []
var hp_text: Label3D
var health_anchor: Node3D
var health_fill: MeshInstance3D
var health_trail: MeshInstance3D
var health_current = 5
var health_maximum = 5
var health_delayed = 1.0
var health_focus_time = 0.0
var special_health_reveal = false
var hp_time = 0.0
var phase = 0.0

func _ready() -> void:
	phase = variant*1.73
	_build_npc()
	for mesh in find_children("*","MeshInstance3D",true,false):
		if mesh.material_override is StandardMaterial3D and not mesh.material_override.emission_enabled:
			if not flash_materials.has(mesh.material_override):
				flash_materials.append(mesh.material_override)
	health_anchor=_node(self,"NPCHealthBar")
	health_anchor.position=Vector3(0,2.22,0)
	_health_quad("Background",Vector2(.82,.086),Color("142024"),0)
	health_trail=_health_quad("DamageTrail",Vector2(.76,.044),Color("d7b77b"),.003)
	health_fill=_health_quad("CurrentHealth",Vector2(.76,.044),Color("bc695d"),.006)
	hp_text = Label3D.new()
	hp_text.position = Vector3(0,.125,.008)
	hp_text.font_size = 30
	hp_text.pixel_size = .0028
	hp_text.modulate = Color("f3eade")
	hp_text.outline_modulate = Color("142024")
	var font = preload("res://PixelFont.gd").make()
	hp_text.font = font
	health_anchor.add_child(hp_text)
	set_health(30 if variant==4 else 5,30 if variant==4 else 5)

func _health_quad(label: String, dimensions: Vector2, tint: Color, z: float) -> MeshInstance3D:
	var quad=QuadMesh.new()
	quad.size=dimensions
	var mesh=MeshInstance3D.new()
	mesh.name=label
	mesh.mesh=quad
	mesh.position.z=z
	mesh.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var material=StandardMaterial3D.new()
	material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color=tint
	mesh.material_override=material
	health_anchor.add_child(mesh)
	return mesh

func set_health(current: int, maximum: int) -> void:
	health_maximum=maxi(maximum,1)
	health_current=clampi(current,0,health_maximum)
	hp_text.text="%d / %d" % [health_current,health_maximum]
	var ratio=float(health_current)/health_maximum
	health_fill.scale.x=maxf(ratio,.001)
	health_fill.position.x=-.38*(1.0-ratio)
	health_fill.visible=health_current>0
	health_fill.material_override.albedo_color=Color("dc6556") if ratio<=.30 else Color("b97c64")

func focus_health() -> void:
	health_focus_time=.2

func _build_npc() -> void:
	var female = variant in [1,3,4]
	var elder = variant in [2,4]
	var coat = ["294568","713348","6a6a43","505d44","773951"][variant]
	var skin = "c59065" if elder else "d69a68"
	var hair = "8d8983" if elder else "302925"
	npc_body = _node(self,"ClothesAndHead")
	npc_body.position.y = 1.12
	_mesh(npc_body,"TailoredShirt",_rings_mesh([Vector3(.23,-.25,.145),Vector3(.185,-.05,.125),Vector3(.235,.20,.14),Vector3(.20,.29,.125)]),Vector3.ZERO,coat)
	_ellipsoid(npc_body,"Neck",Vector3(0,.32,0),Vector3(.074,.095,.072),skin)
	_bevel(npc_body,"ShirtOpening",Vector3(0,.04,-.151),Vector3(.043,.43,.014),"bba986" if variant==3 else coat)
	for side in [-1.0,1.0]:
		_wedge(npc_body,"Collar",Vector3(side*.077,.27,-.12),Vector3(side*.042,.135,-.16),.08,.05,coat)
		if variant==3:
			_bevel(npc_body,"Pocket",Vector3(side*.13,-.12,-.153),Vector3(.095,.08,.017),"59674b")
	for y in [-.16,-.06,.04]:
		_bevel(npc_body,"Button",Vector3(.022,y,-.16),Vector3(.01,.01,.007),"b0a181")
	if variant==0:
		_bevel(npc_body,"RedSash",Vector3(0,-.16,-.008),Vector3(.435,.065,.31),"9b434b")
		for side in [-1.0,1.0]:
			_bevel(npc_body,"SashTail",Vector3(side*.046,-.31,-.17),Vector3(.066,.25,.018),"9b434b").rotation.z=side*.10
	if variant in [1,4]:
		_mesh(npc_body,"WovenSinh",_rings_mesh([Vector3(.275,-.80,.175),Vector3(.28,-.73,.18),Vector3(.245,-.33,.16),Vector3(.21,-.19,.14)]),Vector3.ZERO,"533b46")
		_pattern(npc_body,Vector3(0,-.62,-.181),.48,.24,"ba8547")
		for y in [-.75,-.47]:
			_bevel(npc_body,"SinhBorder",Vector3(0,y,-.184),Vector3(.51,.022,.008),"916238")
	if variant==1:
		_bevel(npc_body,"Apron",Vector3(0,-.34,-.185),Vector3(.35,.32,.02),"b9a58a")
		_bevel(npc_body,"ApronTie",Vector3(0,-.175,-.192),Vector3(.43,.028,.02),"d3bda0")
		for side in [-1.0,1.0]:
			_bevel(npc_body,"TieEnds",Vector3(side*.038,-.255,-.21),Vector3(.025,.15,.016),"d3bda0").rotation.z=side*.2
	for side in [-1.0,1.0]:
		var leg = _node(self,"LeftLeg" if side<0 else "RightLeg")
		leg.position = Vector3(side*.12,.91,0)
		var knee = _node(leg,"Knee")
		knee.position.y = -.39
		if variant not in [1,4]:
			_mesh(leg,"TrouserThigh",_rings_mesh([Vector3(.098,-.415,.108),Vector3(.115,-.28,.127),Vector3(.109,.025,.125)]),Vector3.ZERO,"333138")
			_bevel(knee,"RolledTrouser",Vector3(0,-.024,0),Vector3(.206,.085,.238),"413d43")
			if variant==3:
				_bevel(knee,"LongTrouser",Vector3(0,-.14,0),Vector3(.21,.26,.245),"35323a")
				_pattern(knee,Vector3(0,-.23,-.125),.18,.07,"886762")
		_ellipsoid(knee,"Calf",Vector3(0,-.26,0),Vector3(.061,.21,.065),skin)
		var foot = _build_foot(side)
		foot.reparent(knee)
		foot.position = Vector3(0,-.50,0)
		npc_legs.append({"node":leg,"knee":knee,"side":side})
		var arm = _node(npc_body,"Arm")
		arm.position = Vector3(side*.26,.20,0)
		_mesh(arm,"Sleeve",_rings_mesh([Vector3(.074,-.255,.084),Vector3(.086,-.08,.095),Vector3(.07,.022,.075)]),Vector3.ZERO,coat)
		_bevel(arm,"RolledCuff",Vector3(0,-.25,0),Vector3(.17,.064,.187),coat)
		_ellipsoid(arm,"Forearm",Vector3(0,-.365,0),Vector3(.059,.15,.063),skin)
		_bevel(arm,"Hand",Vector3(0,-.515,-.006),Vector3(.083,.115,.061),skin)
		for finger in range(4):
			_bevel(arm,"Finger",Vector3((finger-1.5)*.019,-.566,-.011),Vector3(.016,.043,.045),skin)
		_bevel(arm,"Thumb",Vector3(-side*.044,-.49,-.026),Vector3(.026,.062,.031),skin)
		npc_arms.append({"node":arm,"side":side})
		if variant==1 and side<0:
			var basket = _basket(arm,Vector3(-.14,-.69,-.075),.23,.27)
			for i in range(9):
				_wedge(basket,"Vegetables",Vector3((i%3-1)*.07,.1,(i/3-1)*.045),Vector3((i%3-1)*.10,.26+(i%2)*.05,0),.07,.07,"526743")
			var handle = TorusMesh.new()
			handle.inner_radius = .18
			handle.outer_radius = .204
			handle.rings = 16
			handle.ring_segments = 6
			_mesh(basket,"BasketHandle",handle,Vector3(0,.20,0),"755234").rotation.x=PI*.5
		if elder and side>0:
			_cylinder(arm,"Cane",Vector3(.015,-.83,-.03),.022,.74,"715134").rotation.x=0
			_bevel(arm,"CaneHandle",Vector3(-.012,-.466,-.03),Vector3(.10,.055,.05),"89613c")
	npc_head = _node(npc_body,"FaceAndHair")
	npc_head.position = Vector3(0,.50,-.01)
	_ellipsoid(npc_head,"Face",Vector3.ZERO,Vector3(.166,.205,.142),skin)
	for side in [-1.0,1.0]:
		_ellipsoid(npc_head,"Ear",Vector3(side*.17,-.01,.005),Vector3(.03,.047,.027),skin)
		_bevel(npc_head,"EyeWhite",Vector3(side*.067,.035,-.139),Vector3(.066,.040,.014),"ede0c5")
		_ellipsoid(npc_head,"NormalEye",Vector3(side*.065,.034,-.15),Vector3(.017,.021,.008),"3b3028")
		_bevel(npc_head,"Brow",Vector3(side*.067,.076,-.147),Vector3(.077,.013,.016),hair).rotation.z=side*.22
	_ellipsoid(npc_head,"Nose",Vector3(0,-.013,-.157),Vector3(.025,.042,.032),skin)
	_bevel(npc_head,"Mouth",Vector3(0,-.084,-.13),Vector3(.058,.012,.01),"8d5941")
	_ellipsoid(npc_head,"HairCap",Vector3(0,.14,.019),Vector3(.183,.126,.16),hair)
	if female:
		_ellipsoid(npc_head,"HairBun",Vector3(-.10,.21,.08) if variant==1 else Vector3(-.015,.335,.05),Vector3(.105,.115,.10),hair)
		for i in range(5):
			_wedge(npc_head,"SweptFringe",Vector3(-.12+i*.052,.20,-.08),Vector3(-.15+i*.056,.025+(i%2)*.035,-.161),.085,.08,hair)
		_wedge(npc_head,"SideLock",Vector3(.145,.13,-.06),Vector3(.17,-.12,-.09),.035,.07,hair)
	elif variant==2:
		for i in range(7):
			var a=TAU*i/7.0
			_ellipsoid(npc_head,"GreyWaves",Vector3(cos(a)*.117,.19,sin(a)*.09),Vector3(.07,.062,.065),hair)
	else:
		for i in range(9):
			var a = TAU*i/9.0
			_wedge(npc_head,"HairTuft",Vector3(cos(a)*.12,.17,sin(a)*.10),Vector3(cos(a)*.21,.26+(i%3)*.022,sin(a)*.17),.14,.10,hair)
	if variant in [0,2]:
		_bevel(npc_head,"Moustache",Vector3(0,-.059,-.15),Vector3(.088,.018,.016),hair)
		_wedge(npc_head,"Beard",Vector3(0,-.13,-.094),Vector3(0,-.17,-.126),.07,.035,hair)
	if variant==4:
		for side in [-1.0,1.0]:
			var glasses = TorusMesh.new()
			glasses.inner_radius=.048
			glasses.outer_radius=.057
			glasses.rings=16
			glasses.ring_segments=5
			_mesh(npc_head,"RoundGlasses",glasses,Vector3(side*.069,.035,-.17),"39302d").rotation.x=PI*.5
		_bevel(npc_head,"GlassesBridge",Vector3(0,.035,-.17),Vector3(.035,.008,.01),"39302d")
	if variant==0:
		_basket(npc_body,Vector3(0,.00,.25),.24,.48)
		for side in [-1.0,1.0]:
			_bevel(npc_body,"BasketStrap",Vector3(side*.15,.06,-.15),Vector3(.035,.46,.022),"78613d")
		for i in range(13):
			var x=(i%5-2)*.08
			var base=Vector3(x,.18,.24+(i%3)*.05)
			_wedge(npc_body,"RiceLeaf",base,base+Vector3(x*.8,.32+(i%3)*.06,.04),.045,.04,"9c944e")
	if variant==2:
		for i in range(12):
			for j in range(4):
				_bevel(npc_body,"PlaidScarf",Vector3(-.155+j*.035,.30-i*.055,-.173),Vector3(.035,.055,.015),["aa7464","d6bd95","765355","c69580"][(i+j)%4])
	if variant==3:
		_bevel(npc_body,"BagStrap",Vector3(0,.01,-.16),Vector3(.043,.63,.023),"79564a").rotation.z=-.55
		_bevel(npc_body,"WovenShoulderBag",Vector3(.285,-.32,-.005),Vector3(.20,.27,.12),"71523e")
		_pattern(npc_body,Vector3(.285,-.32,-.071),.17,.15,"b19056")
	glow_eyes = _node(npc_head,"PossessedEyes")
	for side in [-1.0,1.0]:
		var eye=_ellipsoid(glow_eyes,"SpiritGlow",Vector3(side*.065,.034,-.164),Vector3(.024,.024,.01),"a4fff1")
		var m=_mat("a4fff1")
		m.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
		m.emission_enabled=true
		m.emission=Color("65f4df")
		m.emission_energy_multiplier=2
		eye.material_override=m
	aura=_node(self,"SpiritWisps")
	var glow=StandardMaterial3D.new()
	glow.albedo_color=Color(.63,.82,.77,.18)
	glow.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
	glow.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	glow.cull_mode=BaseMaterial3D.CULL_DISABLED
	for i in range(6):
		var st=SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		for step in range(12):
			var t=step/12.0
			var u=(step+1)/12.0
			var p=Vector3(sin(t*TAU)*.07,t*.8,0)
			var q=Vector3(sin(u*TAU)*.07,u*.8,0)
			var width=sin(t*PI)*.038
			var next_width=sin(u*PI)*.038
			_triangle(st,p-Vector3(width,0,0),p+Vector3(width,0,0),q+Vector3(next_width,0,0))
			_triangle(st,p-Vector3(width,0,0),q+Vector3(next_width,0,0),q-Vector3(next_width,0,0))
		st.generate_normals()
		var w=_mesh(aura,"Wisp",st.commit(),Vector3.ZERO,"90dacb")
		w.material_override=glow
		w.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		wisps.append(w)

func _pattern(parent: Node3D, pos: Vector3, width: float, height: float, color: String) -> void:
	for row in range(3):
		for col in range(5):
			var at=pos+Vector3((col-2)*width/5.0,(row-1)*height/3.0,0)
			var diamond=_bevel(parent,"WovenDiamond",at,Vector3(width/9.0,width/9.0,.005),color)
			diamond.rotation.z=PI*.25
			_bevel(diamond,"DiamondCenter",Vector3(0,0,-.004),Vector3(width/22.0,width/22.0,.005),"654453")

func _basket(parent: Node3D, pos: Vector3, radius: float, height: float) -> Node3D:
	var basket=_node(parent,"WovenBasket")
	basket.position=pos
	var shape=CylinderMesh.new()
	shape.top_radius=radius
	shape.bottom_radius=radius*.76
	shape.height=height
	shape.radial_segments=12
	_mesh(basket,"BasketBody",shape,Vector3.ZERO,"79563a")
	for row in range(6):
		var ring=TorusMesh.new()
		ring.inner_radius=radius*(.80+row*.038)
		ring.outer_radius=ring.inner_radius+.012
		ring.rings=12
		ring.ring_segments=4
		_mesh(basket,"WeaveBand",ring,Vector3(0,-height*.45+row*height*.18,0),"aa8050")
	for i in range(12):
		var a=TAU*i/12.0
		_bevel(basket,"WeaveUpright",Vector3(sin(a)*radius*.94,0,cos(a)*radius*.94),Vector3(.012,height,.013),"9c7349")
	return basket

func set_walking(value: bool, movement_speed: float = 2.7) -> void:
	walking=value and possessed
	if walking:
		walk_phase_rate=8.8*movement_speed/5.2
		set_process(true)

func start_attack() -> void:
	if not possessed:
		return
	walking = false
	attack_time = ATTACK_DURATION

func set_nearby(value: bool) -> void:
	var active = value or walking or special_health_reveal or attack_time > 0.0 or hit_reaction > .01 or health_focus_time > 0.0 or hp_time > 0.0
	set_process(active)
	if not active and health_anchor != null:
		health_anchor.visible = false

func set_special_health_reveal(value: bool) -> void:
	special_health_reveal = value and possessed
	if special_health_reveal:
		set_process(true)
	elif health_anchor != null and not is_processing():
		health_anchor.visible = false

func receive_hit(remaining: int, maximum: int) -> void:
	hit_reaction=1.0
	hp_time=2.5
	set_health(remaining,maximum)

func release_spirit() -> void:
	if not possessed:
		return
	possessed=false
	walking=false
	attack_time=0.0
	glow_eyes.hide()
	aura.hide()
	set_health(0,health_maximum)
	hp_time=1.2
	var release=preload("res://SpiritRelease.gd").new()
	add_child(release)
	release.position=Vector3(0,1.2,0)
	if variant==4:
		release.scale=Vector3.ONE*1.4

func _process(delta: float) -> void:
	age+=delta
	phase+=delta*(walk_phase_rate if walking else 1.5)
	var attack_progress = -1.0
	if attack_time > 0.0:
		attack_time = maxf(attack_time - delta, 0.0)
		attack_progress = 1.0 - attack_time / ATTACK_DURATION
	hit_reaction=move_toward(hit_reaction,0,delta*4.0)
	hp_time=maxf(hp_time-delta,0)
	health_focus_time=maxf(health_focus_time-delta,0)
	health_anchor.visible=possessed or hp_time>0
	var camera=get_viewport().get_camera_3d()
	if camera!=null:
		var distance=camera.global_position.distance_to(health_anchor.global_position)
		var depth=maxf(-camera.to_local(health_anchor.global_position).z,.1)
		var meters_per_pixel=2.0*depth*tan(deg_to_rad(camera.fov*.5))/maxf(get_viewport().get_visible_rect().size.y,1.0)
		var display_scale=clampf(meters_per_pixel*112.0/.82,.25,12.0)
		health_anchor.global_basis=camera.global_basis.orthonormalized().scaled(Vector3.ONE*display_scale)
		health_anchor.visible=health_anchor.visible and not camera.is_position_behind(health_anchor.global_position) and (special_health_reveal or distance<24.0 or health_focus_time>0 or hp_time>0)
	health_delayed=lerpf(health_delayed,float(health_current)/health_maximum,1.0-exp(-delta*5.0))
	health_trail.scale.x=maxf(health_delayed,.001)
	health_trail.position.x=-.38*(1.0-health_delayed)
	health_trail.visible=health_delayed>.002
	npc_body.rotation=Vector3((-.12 if possessed else 0.0)+hit_reaction*.18,0,sin(age*1.7+variant)*(.022 if possessed else .008))
	npc_head.rotation=Vector3(-.07 if possessed else 0.0,0,sin(age*.8+variant)*.045)
	npc_body.position.z = 0.0
	if attack_progress >= 0.0:
		var lunge = sin(attack_progress * PI)
		npc_body.rotation.x += lunge * .18
		npc_body.position.z = -lunge * .12
		npc_head.rotation.x += lunge * .07
	for leg in npc_legs:
		var stride=sin(phase+PI*(1.0 if leg.side<0 else 0.0))
		leg.node.rotation.x=lerpf(leg.node.rotation.x,stride*.34 if walking else 0.0,1.0-exp(-delta*12))
		leg.knee.rotation.x=maxf(-stride,0)*.30 if walking else 0.0
	for arm in npc_arms:
		arm.node.rotation.x=(.32 if variant==1 and arm.side<0 else .08)+sin(phase)*arm.side*(.14 if walking else .018)
		arm.node.rotation.z=arm.side*.07
		if attack_progress >= 0.0:
			if arm.side > 0.0:
				var swing = 0.0
				if attack_progress < .28:
					swing = lerpf(0.0, -.65, attack_progress / .28)
				elif attack_progress < .58:
					swing = lerpf(-.65, 1.30, (attack_progress - .28) / .30)
				else:
					swing = lerpf(1.30, 0.0, (attack_progress - .58) / .42)
				arm.node.rotation.x += swing
				arm.node.rotation.z = -.16 * sin(attack_progress * PI)
			else:
				arm.node.rotation.x += .26 * sin(attack_progress * PI)
	for m in flash_materials:
		m.emission_enabled=hit_reaction>.01
		m.emission=Color(.2,.8,.67)
		m.emission_energy_multiplier=hit_reaction*.65
	for i in range(wisps.size()):
		var t=fmod(age*.18+i/6.0,1.0)
		var a=age*.8+i*2.4
		wisps[i].position=Vector3(cos(a)*(.29+t*.16),.05+t*1.7,sin(a)*.25+.06)
		wisps[i].rotation.z=sin(a)*.45
		wisps[i].scale=Vector3.ONE*sin(t*PI)
