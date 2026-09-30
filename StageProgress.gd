extends RefCounted

const SAVE_PATH := "user://stage_progress.cfg"
const STAGE_COUNT := 4
const LOADING_SCENE := "res://LoadingScreen.tscn"

static var selected_stage := 1


static func highest_unlocked(save_path: String = SAVE_PATH) -> int:
	var config := ConfigFile.new()
	if config.load(save_path) != OK:
		return 1
	return clampi(int(config.get_value("progress", "highest_unlocked", 1)), 1, STAGE_COUNT)


static func unlock_stage(stage_number: int, save_path: String = SAVE_PATH) -> void:
	var unlocked := clampi(stage_number, 1, STAGE_COUNT)
	if unlocked <= highest_unlocked(save_path):
		return
	var config := ConfigFile.new()
	config.set_value("progress", "highest_unlocked", unlocked)
	var result := config.save(save_path)
	if result != OK:
		push_error("Could not save unlocked stage %d (error %d)" % [unlocked, result])


static func start_stage(tree: SceneTree, stage_number: int) -> Error:
	if stage_number < 1 or stage_number > STAGE_COUNT:
		return ERR_INVALID_PARAMETER
	selected_stage = stage_number
	return tree.change_scene_to_file(LOADING_SCENE)
