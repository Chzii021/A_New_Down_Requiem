extends "res://VikramRig.gd"

# Camera-space arms share the actual weapon geometry and shot effects with TPS.
var fp_limbs = []
var sway = Vector2.ZERO
var bob_phase = 0.0
var floor_height = 0.0

func _ready() -> void:
	_build_weapons()
	khene = preload("res://Khene.tscn").instantiate()
	add_child(khene)
	khene.visible = false
	khene.scale = Vector3.ONE * .72
	gun.scale = Vector3.ONE * .68
	for side in [-1.0,1.0]:
		var limb={"side":side,"sleeve":_segment(self,"IndigoSleeve","29466f",.92),"forearm":_segment(self,"Forearm","d99a64",.75),"hand":_build_hand(side)}
		if side<0:
			limb["wrap"]=_segment(self,"RedWristCloth","963e42",1.0)
		fp_limbs.append(limb)
	set_rifle(false)
	_update_pose(0.0)
	for mesh in find_children("*","MeshInstance3D",true,false):
		mesh.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	process_priority=21

func set_view_motion(speed: float, is_aiming: bool, ground_y: float) -> void:
	move_speed=speed
	aiming_down_sights=is_aiming
	floor_height=ground_y

func add_sway(relative: Vector2) -> void:
	sway+=relative*.00009
	sway=sway.clamp(Vector2(-.016,-.012),Vector2(.016,.012))

func _reload_body_socket() -> Vector3:
	return Vector3(-.33, -.69, -.30)

func _process(delta: float) -> void:
	age+=delta
	lunge_weight=move_toward(lunge_weight,1.0 if lunge_pose_target else 0.0,delta*10.0)
	if not visible:
		muzzle.hide()
		return
	smoothed_speed=lerpf(smoothed_speed,move_speed,1.0-exp(-delta*10.0))
	bob_phase+=delta*minf(smoothed_speed,7.4)*1.8
	aim_weight=lerpf(aim_weight,1.0 if aiming_down_sights else 0.0,1.0-exp(-delta*12.0))
	recoil=move_toward(recoil,0.0,delta*6.0)
	fire_time=maxf(fire_time-delta,0.0)
	sway=sway.lerp(Vector2.ZERO,1.0-exp(-delta*8.0))
	_update_pose(delta)

func play_shot() -> void:
	recoil=minf(recoil+.8,1.2)
	fire_time=.075
	_update_pose(0.0)
	muzzle.rotation.z=randf()*TAU
	effects.discharge(get_muzzle_position(),gun.global_basis.orthonormalized(),gun.to_global(Vector3(.045,.024,-.025)),rifle_equipped,floor_height)

func _update_pose(_delta: float) -> void:
	# The longer bamboo weapon reads as a rifle, while both sights stay below the reticle.
	gun.scale = Vector3.ONE * (.83 if rifle_equipped else .68)
	if khene != null and khene_weight > .001:
		var raised := smoothstep(0.0, 1.0, khene_weight)
		khene.position = Vector3(.41, -.92, -.55).lerp(Vector3(.08, -.40, -.68), raised)
		khene.rotation = Vector3(-.08 * raised, -.10, .17 * (1.0 - raised) + sin(age * 11.0) * (.012 if khene_blowing else 0.0))
	var hip=Vector3(.32,-.27,-1.03) if rifle_equipped else Vector3(.30,-.26,-.92)
	# Align the weapon horizontally with the camera ray, but leave its top below the crosshair.
	var sight=Vector3(.02,-.11,-1.14) if rifle_equipped else Vector3(.02,-.11,-1.06)
	gun.position=hip.lerp(sight,aim_weight)
	var reload_weight = _reload_weight()
	gun.position += Vector3(-.08,.055,-.11)*reload_weight
	var bob=minf(smoothed_speed/7.4,1.0)*(1.0-aim_weight*.8)
	gun.position+=Vector3(sin(bob_phase)*.007*bob-sway.x,cos(bob_phase*2.0)*.005*bob+sway.y,recoil*.033)
	var direction=(to_local(aim_target)-gun.position).normalized() if has_aim_target else Vector3.FORWARD
	gun.rotation=Vector3(asin(clampf(direction.y,-1,1))+recoil*.032-reload_weight*.15,atan2(-direction.x,-direction.z),-sway.x*.4-reload_weight*.28)
	_pose_magazines()
	for limb in fp_limbs:
		var side=limb.side
		var palm=gun.transform*_reload_hand_grip(side)
		var hand_basis=gun.basis.orthonormalized()
		if khene_weight > .001:
			palm = palm.lerp(khene.transform * Vector3(side * .19, .30, -.095), khene_weight)
			hand_basis = hand_basis.slerp(khene.basis.orthonormalized(), khene_weight)
		elif sickle_equipped and side > 0.0:
			# Hold the sickle at the lower right of the view, clear of the reticle.
			palm = Vector3(.46, -.28, -.82).lerp(Vector3(.35, -.12, -1.08), lunge_weight)
			hand_basis = Basis.IDENTITY.slerp(Basis.from_euler(Vector3(-.30, -.10, .08)), lunge_weight)
		elif sickle_equipped and side < 0.0:
			palm = Vector3(-.40, -.66, -.38).lerp(Vector3(-.31, -.52, -.62), lunge_weight)
		var wrist=palm+hand_basis*Vector3(side*.035,-.030,.024)
		var elbow=Vector3(.34,-.50,-.55) if side>0 else Vector3(-.10,-.50,-.62)
		var shoulder=Vector3(.43,-.70,-.16) if side>0 else Vector3(-.31,-.69,-.16)
		elbow=elbow.lerp(elbow+Vector3(-side*.045,.045,-.03),aim_weight)
		_fit(limb.sleeve,shoulder,elbow,.085,1.05)
		_fit(limb.forearm,elbow,wrist,.061)
		limb.hand.transform=Transform3D(hand_basis,palm)
		if limb.has("wrap"):
			_fit(limb.wrap,elbow.lerp(wrist,.79),elbow.lerp(wrist,.94),.060)
	muzzle.position=Vector3(0,0,-.705) if rifle_equipped else Vector3(0,0,-.340)
	muzzle.visible=fire_time>0
	var amount=clampf(fire_time/.075,0,1)
	muzzle.scale=Vector3.ONE*(.55+amount*.7)*(1.0 if rifle_equipped else .7)
	flash_light.light_energy=.45*amount
