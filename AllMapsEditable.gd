@tool
extends Node3D

# Use one neutral light in the overview; the original map scenes keep their own time-of-day lights.
func _ready() -> void:
	for level in get_children():
		if not level is Node3D or not level.name.begins_with("0"):
			continue
		var scenery = level.get_node_or_null("Scenery")
		if scenery == null:
			continue
		for part in scenery.get_children():
			if part is DirectionalLight3D:
				part.visible = false
			elif part is WorldEnvironment:
				part.environment = null
			elif part is MeshInstance3D and part.mesh is SphereMesh and part.position.y > 30.0:
				part.visible = false
