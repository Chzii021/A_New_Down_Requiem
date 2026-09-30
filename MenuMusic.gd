extends RefCounted

const AUDIO_SCRIPT = preload("res://GameAudio.gd")
const NODE_NAME := "MenuMusic"


static func ensure(tree: SceneTree, scene_owner: Node) -> Node:
	var audio: Node = tree.root.get_node_or_null(NODE_NAME)
	if audio != null:
		return audio
	audio = AUDIO_SCRIPT.new()
	audio.name = NODE_NAME
	audio.process_mode = Node.PROCESS_MODE_ALWAYS
	scene_owner.add_child(audio)
	audio.call("play_menu_music")
	audio.call_deferred("reparent", tree.root)
	return audio


static func stop(tree: SceneTree) -> void:
	var audio: Node = tree.root.get_node_or_null(NODE_NAME)
	if audio != null:
		audio.queue_free()
