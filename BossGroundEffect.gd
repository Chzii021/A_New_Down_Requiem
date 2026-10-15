extends Node3D

## Three unlit draws: a woven ground seal, spirit ribbons, and rising embers.
## Configure before adding to the scene. Warning seals live until queue_free();
## impact seals finish themselves without a timer node or physics processing.
const EFFECT_SHADER := preload("res://shaders/boss_ground.gdshader")
const IMPACT_DURATION := .9

static var _ground_mesh: PlaneMesh
static var _ribbon_mesh: QuadMesh
static var _ember_mesh: SphereMesh

var radius := 3.2
var tint := Color(1.0, .42, .14)
var impact := false
var _age := 0.0
var _materials: Array[ShaderMaterial] = []


func configure(effect_radius: float, effect_tint: Color, is_impact: bool = false) -> void:
	radius = maxf(effect_radius, .3)
	tint = effect_tint
	impact = is_impact


func _ready() -> void:
	if _ground_mesh == null:
		_ground_mesh = PlaneMesh.new()
		_ground_mesh.size = Vector2(2.32, 2.32)
		_ribbon_mesh = QuadMesh.new()
		_ribbon_mesh.size = Vector2.ONE
		_ember_mesh = SphereMesh.new()
		_ember_mesh.radius = .028
		_ember_mesh.height = .075
		_ember_mesh.radial_segments = 4
		_ember_mesh.rings = 1
	var seal := MeshInstance3D.new()
	seal.name = "WovenSpiritSeal"
	seal.mesh = _ground_mesh
	seal.scale = Vector3(radius, 1.0, radius)
	seal.position.y = .025
	seal.material_override = _material(0)
	seal.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(seal)
	var ribbons := MultiMeshInstance3D.new()
	ribbons.name = "SpiritFlames" if impact else "RisingWarning"
	ribbons.multimesh = _multimesh(_ribbon_mesh, 18 if impact else 12)
	ribbons.material_override = _material(1)
	ribbons.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var ribbon_height := 2.4 if impact else .72
	for index in ribbons.multimesh.instance_count:
		var angle := TAU * float(index) / float(ribbons.multimesh.instance_count)
		var ring_radius := radius * (.74 if impact else .94)
		var height_variation := .8 + .2 * sin(float(index) * 2.37)
		var ribbon_basis := Basis(Vector3.UP, -angle).scaled(Vector3(.22 + radius * .07, ribbon_height * height_variation, 1.0))
		var origin := Vector3(sin(angle) * ring_radius, ribbon_height * height_variation * .5, cos(angle) * ring_radius)
		ribbons.multimesh.set_instance_transform(index, Transform3D(ribbon_basis, origin))
		ribbons.multimesh.set_instance_custom_data(index, Color(float(index) / 18.0, height_variation, 0.0, 1.0))
	add_child(ribbons)
	var embers := MultiMeshInstance3D.new()
	embers.name = "SpiritEmbers"
	embers.multimesh = _multimesh(_ember_mesh, 18 if impact else 10)
	embers.material_override = _material(2)
	embers.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for index in embers.multimesh.instance_count:
		var angle := float(index) * 2.39996
		var ember_radius := radius * (.32 + .6 * fposmod(float(index) * .618, 1.0))
		embers.multimesh.set_instance_transform(index, Transform3D(Basis.IDENTITY, Vector3(sin(angle) * ember_radius, .12, cos(angle) * ember_radius)))
		embers.multimesh.set_instance_custom_data(index, Color(fposmod(float(index) * .317, 1.0), 0.0, 0.0, 1.0))
	add_child(embers)


func _process(delta: float) -> void:
	_age += delta
	for material in _materials:
		material.set_shader_parameter("age", _age)
	if impact and _age >= IMPACT_DURATION:
		queue_free()


func _material(mode: int) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = EFFECT_SHADER
	material.set_shader_parameter("effect_mode", mode)
	material.set_shader_parameter("tint", tint)
	material.set_shader_parameter("impact", impact)
	_materials.append(material)
	return material


func _multimesh(mesh: Mesh, count: int) -> MultiMesh:
	var instances := MultiMesh.new()
	instances.transform_format = MultiMesh.TRANSFORM_3D
	instances.use_custom_data = true
	instances.mesh = mesh
	instances.instance_count = count
	instances.custom_aabb = AABB(Vector3(-radius - 1.0, -.2, -radius - 1.0), Vector3(radius * 2.0 + 2.0, 5.0, radius * 2.0 + 2.0))
	return instances
