extends Node3D

# World-space effects, owned by the character so scene reloads remove them too.
const LIMIT = 180
var particles: Array = []
var shots: Array = []
var random = RandomNumberGenerator.new()
var sphere: SphereMesh
var streak: CylinderMesh
var smoke_mesh: QuadMesh
var smoke_texture: GradientTexture2D

func _ready() -> void:
	top_level = true
	global_transform = Transform3D.IDENTITY
	random.randomize()
	sphere = SphereMesh.new()
	sphere.radius = 1.0
	sphere.height = 2.0
	sphere.radial_segments = 8
	sphere.rings = 4
	streak = CylinderMesh.new()
	streak.top_radius = 1.0
	streak.bottom_radius = 1.0
	streak.height = 1.0
	streak.radial_segments = 6
	smoke_mesh = QuadMesh.new()
	smoke_mesh.size = Vector2(2.0,2.0)
	var gradient = Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0,.35,1.0])
	gradient.colors = PackedColorArray([Color(1,1,1,.7),Color(1,1,1,.4),Color(1,1,1,0)])
	smoke_texture = GradientTexture2D.new()
	smoke_texture.gradient = gradient
	smoke_texture.fill = GradientTexture2D.FILL_RADIAL
	smoke_texture.fill_from = Vector2(.5,.5)
	smoke_texture.fill_to = Vector2(.5,0)
	smoke_texture.width = 64
	smoke_texture.height = 64

func material(color: Color, glow: bool) -> StandardMaterial3D:
	var m = StandardMaterial3D.new()
	m.albedo_color = color
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED if glow else BaseMaterial3D.SHADING_MODE_PER_PIXEL
	if glow:
		m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		m.emission_enabled = true
		m.emission = color
		m.emission_energy_multiplier = 1.7
	m.roughness = .7
	return m

func visual(mesh: Mesh, color: Color, glow: bool) -> MeshInstance3D:
	var n = MeshInstance3D.new()
	n.mesh = mesh
	n.material_override = material(color, glow)
	if mesh == smoke_mesh:
		n.material_override.albedo_texture = smoke_texture
		n.material_override.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
		n.material_override.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	n.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(n)
	return n

func particle(pos: Vector3, velocity: Vector3, color: Color, size: float, life: float, kind: String, floor_y: float = 0.0) -> void:
	if particles.size() >= LIMIT:
		var oldest: Dictionary = particles.pop_front()
		oldest.node.queue_free()
	var mesh = smoke_mesh if kind == "smoke" else (streak if kind == "casing" or kind == "spark" else sphere)
	var n = visual(mesh, color, kind == "spark" or kind == "spirit")
	n.position = pos
	n.scale = Vector3.ONE * size
	if kind == "casing":
		n.scale = Vector3(.010, .039, .010)
		n.material_override.metallic = .65
	n.rotation = Vector3(random.randf()*PI, random.randf()*PI, random.randf()*PI)
	particles.append({"node":n,"velocity":velocity,"age":0.0,"life":life,"size":size,"kind":kind,"alpha":color.a,"floor":floor_y,"bounced":false})

func discharge(muzzle: Vector3, weapon_basis: Basis, eject: Vector3, rifle: bool, floor_y: float) -> void:
	for i in range(3):
		var drift = -weapon_basis.z * random.randf_range(.4, .9) + Vector3(random.randf_range(-.09,.09), .23+i*.06, 0)
		particle(muzzle-weapon_basis.z*i*.035, drift, Color(.69,.68,.62,.13), .025+i*.006, .32+i*.09, "smoke")
	var kick = weapon_basis.x*random.randf_range(1.1,1.6)+Vector3.UP*random.randf_range(1.2,1.8)+weapon_basis.z*.2
	particle(eject, kick, Color("be934d"), .01, 1.5 if rifle else 1.3, "casing", floor_y)

func trace(start: Vector3, end: Vector3, normal: Vector3, collided: bool, spirit: bool) -> void:
	var distance = start.distance_to(end)
	if distance < .015:
		if collided:
			impact(end, normal, spirit)
		return
	# Short luminous segments travel along the hitscan ray. Damage remains immediate.
	var shell = visual(streak, Color(1.0,.52,.11,.45), true)
	var core = visual(streak, Color(1.0,.94,.67,.95), true)
	shots.append({"start":start,"end":end,"normal":normal,"hit":collided,"spirit":spirit,"distance":distance,"direction":(end-start)/distance,"age":0.0,"duration":clampf(distance/160.0,.055,.24),"shell":shell,"core":core,"impacted":false})
	_segment(shell,start,start+(end-start).normalized()*.015,.012)
	_segment(core,start,start+(end-start).normalized()*.015,.0035)

func _segment(n: MeshInstance3D, a: Vector3, b: Vector3, width: float) -> void:
	var d = b-a
	n.position = (a+b)*.5
	n.quaternion = Quaternion(Vector3.UP,d.normalized()) if d.length_squared()>.0000001 else Quaternion.IDENTITY
	n.scale = Vector3(width,maxf(d.length(),.001),width)

func impact(point: Vector3, normal: Vector3, spirit: bool) -> void:
	var n = normal.normalized() if normal.length_squared()>.001 else Vector3.UP
	var origin = point+n*.035
	var tint = Color(.35,1.0,.85,.85) if spirit else Color(1.0,.71,.28,.9)
	for i in range(8):
		var spread = Vector3(random.randf_range(-1,1),random.randf_range(-1,1),random.randf_range(-1,1))
		var velocity = (n+spread*.85).normalized()*random.randf_range(.6,2.2)
		particle(origin,velocity,tint,random.randf_range(.012,.023),random.randf_range(.18,.38),"spirit" if spirit else "spark")
	for i in range(3):
		particle(origin,n*.2+Vector3(0,.16,0),Color(.30,.71,.61,.15) if spirit else Color(.57,.45,.30,.18),.035+i*.015,.35+i*.09,"smoke")

func _process(delta: float) -> void:
	for i in range(shots.size()-1,-1,-1):
		var s: Dictionary = shots[i]
		s.age += delta
		var progress = minf(s.age/s.duration,1.0)
		var head_distance: float = s.distance*progress
		var tail_distance = maxf(0.0,head_distance-minf(s.distance*.3,1.1))
		if progress >= 1.0:
			if not s.impacted and s.hit:
				impact(s.end,s.normal,s.spirit)
			s.impacted = true
			var fade = clampf(1.0-(s.age-s.duration)/.045,0.0,1.0)
			tail_distance = lerpf(s.distance,tail_distance,fade)
			s.shell.material_override.albedo_color.a = fade*.45
			s.core.material_override.albedo_color.a = fade*.95
		_segment(s.shell,s.start+s.direction*tail_distance,s.start+s.direction*head_distance,.012)
		_segment(s.core,s.start+s.direction*tail_distance,s.start+s.direction*head_distance,.0035)
		if s.age >= s.duration+.045:
			s.shell.queue_free()
			s.core.queue_free()
			shots.remove_at(i)
	for i in range(particles.size()-1,-1,-1):
		var p: Dictionary = particles[i]
		p.age += delta
		if p.age >= p.life:
			p.node.queue_free()
			particles.remove_at(i)
			continue
		var t: float = p.age/p.life
		if p.kind == "casing":
			p.velocity.y -= 7.5*delta
			p.node.position += p.velocity*delta
			if p.node.position.y < p.floor+.015:
				p.node.position.y = p.floor+.015
				p.velocity = Vector3(p.velocity.x*.45,absf(p.velocity.y)*.24 if not p.bounced else 0.0,p.velocity.z*.45)
				p.bounced = true
			if p.velocity.length()>.12:
				p.node.rotate_x(delta*11)
				p.node.rotate_z(delta*8)
			p.node.material_override.albedo_color.a = minf((1.0-t)*5.0,1.0)
		else:
			p.node.position += p.velocity*delta
			p.velocity *= exp(-delta*2.5)
			if p.kind == "smoke":
				p.velocity.y += delta*.25
				p.node.scale = Vector3.ONE*p.size*(1.0+t*3.2)
			elif p.kind == "spark":
				p.velocity.y -= delta*2.0
				_segment(p.node,p.node.position,p.node.position-p.velocity*.035,p.size*.35)
			else:
				p.node.scale = Vector3.ONE*p.size*(1.0-t*.6)
			p.node.material_override.albedo_color.a = p.alpha*pow(1.0-t,1.5)
