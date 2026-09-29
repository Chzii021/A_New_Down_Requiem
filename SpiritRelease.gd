extends "res://VikramRig.gd"

const DURATION = 2.5
var ghost: Node3D
var ring: MeshInstance3D
var particles = []
var spirit_arms = []
var fade_materials = []
var release_light: OmniLight3D

func _spirit_material(tint: Color) -> StandardMaterial3D:
	var material=StandardMaterial3D.new()
	material.albedo_color=tint
	material.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	material.cull_mode=BaseMaterial3D.CULL_BACK
	fade_materials.append({"material":material,"alpha":tint.a})
	return material

func _ghost_part(node: MeshInstance3D, material: Material) -> MeshInstance3D:
	node.material_override=material
	node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return node

func _ready() -> void:
	var mist=_spirit_material(Color(.69,.84,.96,.31))
	var features=_spirit_material(Color(.27,.46,.62,.48))
	var mouth=_spirit_material(Color(.36,.55,.70,.28))
	var wisps=_spirit_material(Color(.73,.86,.96,.15))
	ghost=_node(self,"PaleBlueSpirit")
	# A single translucent silhouette avoids opaque seams between head and body.
	var silhouette=_rings_mesh([
		Vector3(.012,-.53,.01),Vector3(.075,-.29,.045),
		Vector3(.155,-.06,.10),Vector3(.21,.15,.125),
		Vector3(.15,.29,.105),Vector3(.183,.44,.14),
		Vector3(.165,.59,.13),Vector3(.10,.69,.075),
		Vector3(.008,.73,.008)])
	_ghost_part(_mesh(ghost,"TranslucentSilhouette",silhouette,Vector3.ZERO,"bddff5"),mist)
	for side in [-1.0,1.0]:
		_ghost_part(_ellipsoid(ghost,"SoftEye",Vector3(side*.059,.486,-.138),Vector3(.021,.037,.008),"719cbb"),features)
		var arm=_ghost_part(_ellipsoid(ghost,"FloatingArm",Vector3(side*.219,.102,0),Vector3(.043,.165,.038),"bddff5"),mist)
		arm.rotation.z=side*.42
		spirit_arms.append(arm)
	_ghost_part(_ellipsoid(ghost,"SmallMouth",Vector3(0,.379,-.133),Vector3(.014,.022,.006),"8fbbd6"),mouth)
	var ring_mesh=TorusMesh.new()
	ring_mesh.inner_radius=.46
	ring_mesh.outer_radius=.466
	ring_mesh.rings=40
	ring_mesh.ring_segments=4
	ring=_ghost_part(_mesh(self,"SoftRipple",ring_mesh,Vector3(0,-1.16,0),"c9e2f4"),wisps)
	for i in range(14):
		var mote=_ellipsoid(self,"MistMote",Vector3.ZERO,Vector3(.012,.026,.012),"c9e2f4")
		_ghost_part(mote,wisps)
		particles.append(mote)
	release_light=OmniLight3D.new()
	release_light.light_color=Color("b6d9f5")
	release_light.omni_range=2.0
	release_light.light_energy=.10
	add_child(release_light)

func _process(delta: float) -> void:
	age+=delta
	var t=clampf(age/DURATION,0,1)
	var fade=1.0-smoothstep(.36,1.0,t)
	ghost.position=Vector3(sin(age*2.0)*.055,t*1.9,0)
	ghost.rotation=Vector3(0,sin(age*1.7)*.16,sin(age*2.2)*.025)
	ghost.scale=Vector3(1.0-t*.06,.95+t*.23,1.0)
	for entry in fade_materials:
		entry.material.albedo_color.a=entry.alpha*fade
	for i in range(spirit_arms.size()):
		spirit_arms[i].rotation.x=sin(age*2.0+i)*.08
	ring.scale=Vector3.ONE*(.6+t*2.5)
	release_light.light_energy=.10*fade
	for i in range(particles.size()):
		var a=i*2.399+age*.7
		var height=fmod(i*.173+t*1.9,2.1)
		var radius=(.14+float(i%5)*.055)*(1.0+t*.4)
		particles[i].position=Vector3(cos(a)*radius,height-.6+t*.8,sin(a)*radius)
		particles[i].scale=Vector3.ONE*(1.0-t*.7)
	if age>=DURATION:
		queue_free()
