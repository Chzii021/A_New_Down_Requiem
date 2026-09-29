extends Node

const AMBIENT = preload("res://audio/ambient_original.wav")
const GUNSHOT = preload("res://audio/gunshot_original.wav")
const HIT = preload("res://audio/hit_original.wav")
const SPIRIT = preload("res://audio/spirit_original.wav")
const CRAFT = preload("res://audio/craft_original.wav")
const SHRINE = preload("res://audio/shrine_original.wav")
const RELOAD = preload("res://audio/reload_original.wav")
const SETTINGS_PATH = "user://audio_settings.cfg"
const MUSIC_BASE_DB = -16.44
const GUN_BASE_DB = -5.0
const HIT_BASE_DB = -8.0
const SPIRIT_BASE_DB = -9.02

var music_player: AudioStreamPlayer
var shot_players: Array[AudioStreamPlayer] = []
var shot_index = 0
var hit_players: Array[AudioStreamPlayer] = []
var hit_index = 0
var spirit_stream: AudioStream
var craft_player: AudioStreamPlayer
var shrine_player: AudioStreamPlayer
var reload_player: AudioStreamPlayer
var volume_levels = {"music": 1.0, "gun": 1.0, "effects": 1.0}


func _ready() -> void:
	_load_settings()
	music_player = AudioStreamPlayer.new()
	music_player.name = "BackgroundMusic"
	music_player.stream = _preferred_stream("music", AMBIENT)
	add_child(music_player)
	music_player.finished.connect(_repeat_music)
	var shot_stream = _preferred_stream("gunshot", GUNSHOT)
	for index in range(6):
		var player = AudioStreamPlayer.new()
		player.name = "Gunshot%d" % index
		player.stream = shot_stream
		add_child(player)
		shot_players.append(player)
	var hit_stream = _preferred_stream("hit", HIT)
	for index in range(4):
		var player = AudioStreamPlayer.new()
		player.name = "VillagerHit%d" % index
		player.stream = hit_stream
		add_child(player)
		hit_players.append(player)
	spirit_stream = _preferred_stream("spirit", SPIRIT)
	craft_player = _one_shot("CraftSound", _preferred_stream("craft", CRAFT), -5.0)
	shrine_player = _one_shot("ShrineSound", _preferred_stream("shrine", SHRINE), -7.0)
	reload_player = _one_shot("ReloadSound", _preferred_stream("reload", RELOAD), -5.0)
	_apply_volumes()
	music_player.play()


func _load_settings() -> void:
	var config := ConfigFile.new()
	if config.load(SETTINGS_PATH) != OK:
		return
	for category in volume_levels.keys():
		volume_levels[category] = clampf(float(config.get_value("audio", category, 1.0)), 0.0, 1.0)


func get_volume_levels() -> Dictionary:
	return volume_levels.duplicate()


func set_volume_level(category: String, level: float) -> void:
	if not volume_levels.has(category):
		return
	volume_levels[category] = clampf(level, 0.0, 1.0)
	_apply_volumes()
	var config := ConfigFile.new()
	for key in volume_levels.keys():
		config.set_value("audio", key, volume_levels[key])
	config.save(SETTINGS_PATH)


func _scaled_db(base_db: float, category: String) -> float:
	var level: float = volume_levels[category]
	return -80.0 if level <= 0.001 else base_db + linear_to_db(level)


func _apply_volumes() -> void:
	music_player.volume_db = _scaled_db(MUSIC_BASE_DB, "music")
	for player in shot_players:
		player.volume_db = _scaled_db(GUN_BASE_DB, "gun")
	for player in hit_players:
		player.volume_db = _scaled_db(HIT_BASE_DB, "effects")
	craft_player.volume_db = _scaled_db(-5.0, "effects")
	shrine_player.volume_db = _scaled_db(-7.0, "effects")
	reload_player.volume_db = _scaled_db(-5.0, "effects")
	for child in get_children():
		if child is AudioStreamPlayer3D and child.name == "SpiritReleaseSound":
			child.volume_db = _scaled_db(SPIRIT_BASE_DB, "effects")


func _one_shot(label: String, sound: AudioStream, volume: float) -> AudioStreamPlayer:
	var player = AudioStreamPlayer.new()
	player.name = label
	player.stream = sound
	player.volume_db = volume
	add_child(player)
	return player


func _preferred_stream(label: String, fallback: AudioStream) -> AudioStream:
	for extension in ["ogg", "wav", "mp3"]:
		var path = "res://audio/%s_custom.%s" % [label, extension]
		if ResourceLoader.exists(path):
			var stream = load(path)
			if stream is AudioStream:
				return stream
	return fallback


func _repeat_music() -> void:
	if is_instance_valid(music_player):
		music_player.play()


func play_shot() -> void:
	var player = shot_players[shot_index]
	shot_index = (shot_index + 1) % shot_players.size()
	player.stop()
	player.pitch_scale = randf_range(.96, 1.04)
	player.play()


func play_hit() -> void:
	var player = hit_players[hit_index]
	hit_index = (hit_index + 1) % hit_players.size()
	player.stop()
	player.pitch_scale = randf_range(.97, 1.03)
	player.play()


func play_craft() -> void:
	craft_player.stop()
	craft_player.play()


func play_shrine() -> void:
	shrine_player.stop()
	shrine_player.play()


func play_reload() -> void:
	reload_player.stop()
	reload_player.play()


func stop_reload() -> void:
	reload_player.stop()


func play_spirit(place: Vector3) -> void:
	var player = AudioStreamPlayer3D.new()
	player.name = "SpiritReleaseSound"
	player.stream = spirit_stream
	player.volume_db = _scaled_db(SPIRIT_BASE_DB, "effects")
	player.unit_size = 8.0
	player.max_distance = 35.0
	add_child(player)
	player.global_position = place + Vector3(0, 1.2, 0)
	player.finished.connect(player.queue_free)
	player.play()
