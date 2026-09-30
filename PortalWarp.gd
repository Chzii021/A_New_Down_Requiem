extends CanvasLayer

const WARP_SHADER = preload("res://PortalWarpScreen.gdshader")

var material: ShaderMaterial


func _ready() -> void:
	layer = 100
	var screen := ColorRect.new()
	screen.name = "WarpScreen"
	screen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	material = ShaderMaterial.new()
	material.shader = WARP_SHADER
	screen.material = material
	add_child(screen)
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_set_progress(0.0)


func play_in() -> void:
	var tween := create_tween()
	tween.tween_method(_set_progress, 0.0, 1.0, 1.2).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	await tween.finished


func play_out() -> void:
	var tween := create_tween()
	tween.tween_method(_set_progress, 1.0, 0.0, 1.15).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	await tween.finished


func _set_progress(value: float) -> void:
	material.set_shader_parameter("progress", value)
