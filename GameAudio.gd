extends Node

const AMBIENT = preload("res://audio/ambient_original.wav")
const GUNSHOT = preload("res://audio/gunshot_original.wav")
const HIT = preload("res://audio/hit_original.wav")
const SPIRIT = preload("res://audio/spirit_original.wav")
const CRAFT = preload("res://audio/craft_original.wav")
const SHRINE_SOUNDS = [
	preload("res://audio/End_portal_eye_place1.ogg.mp3"),
	preload("res://audio/End_portal_eye_place2.ogg.mp3"),
	preload("res://audio/End_portal_eye_place3.ogg.mp3")
]
const PORTAL_ACTIVATION = preload("res://audio/end_portal_activation.mp3")
const PORTAL_AMBIENCE = preload("res://audio/portal_ambience.wav")
const PORTAL_TRAVEL = preload("res://audio/Nether Portal Travel Sound (Minecraft) - Sound Effect for editing.mp3")
const VICTORY_SOUND = preload("res://audio/minecraftachievement.mp3")
const RELOAD = preload("res://audio/reload_original.wav")
const ITEM_PICKUP_PATH = "res://audio/minecraft_item_pickup.mp3"
const SETTINGS_PATH = "user://audio_settings.cfg"
const MUSIC_BASE_DB = -16.44
const MENU_MUSIC_PATH = "res://audio/Resident Evil 1 OST - Save Room.mp3"
const STORY_MUSIC = preload("res://audio/Silent Hill 2 OST - White Noiz.mp3")
const VICTORY_MUSIC = preload("res://audio/จี่หอย - พี สะเดิด 【OFFICIAL MV】.mp3")
const GUN_BASE_DB = -5.0
const HIT_BASE_DB = -8.0
const SPIRIT_BASE_DB = -9.02

var music_player: AudioStreamPlayer
var gameplay_music_stream: AudioStream
var shot_players: Array[AudioStreamPlayer] = []
var shot_index = 0
var hit_players: Array[AudioStreamPlayer] = []
var hit_index = 0
var spirit_stream: AudioStream
var craft_player: AudioStreamPlayer
var shrine_player: AudioStreamPlayer
var shrine_sound_index = 0
var portal_player: AudioStreamPlayer
var portal_ambience_player: AudioStreamPlayer3D
var portal_travel_player: AudioStreamPlayer
var portal_travel_fade: Tween
var victory_player: AudioStreamPlayer
var victory_sound_playing := false
var reload_player: AudioStreamPlayer
var item_pickup_player: AudioStreamPlayer
var volume_levels = {"music": 1.0, "gun": 1.0, "effects": 1.0}
var look_sensitivity = 1.0
var music_base_db := MUSIC_BASE_DB


func _ready() -> void:
	_load_settings()
	music_player = AudioStreamPlayer.new()
	music_player.name = "BackgroundMusic"
	gameplay_music_stream = _preferred_stream("music", AMBIENT)
	music_player.stream = gameplay_music_stream
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
	shrine_player = _one_shot("ShrineSound", SHRINE_SOUNDS[0], -7.0)
	portal_player = _one_shot("PortalActivationSound", PORTAL_ACTIVATION, -7.0)
	var ambience_stream := PORTAL_AMBIENCE.duplicate() as AudioStreamWAV
	ambience_stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	portal_ambience_player = AudioStreamPlayer3D.new()
	portal_ambience_player.name = "PortalNearbySound"
	portal_ambience_player.stream = ambience_stream
	portal_ambience_player.unit_size = 4.0
	portal_ambience_player.max_distance = 26.0
	portal_ambience_player.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
	add_child(portal_ambience_player)
	portal_travel_player = _one_shot("PortalTravelSound", PORTAL_TRAVEL, -4.0)
	victory_player = _one_shot("VictorySound", VICTORY_SOUND, -3.0)
	victory_player.finished.connect(_victory_sound_finished)
	reload_player = _one_shot("ReloadSound", _preferred_stream("reload", RELOAD), -5.0)
	if ResourceLoader.exists(ITEM_PICKUP_PATH):
		var item_pickup_stream: AudioStream = load(ITEM_PICKUP_PATH)
		item_pickup_player = _one_shot("ItemPickupSound", item_pickup_stream, -5.0)
	_apply_volumes()
	music_player.play()


func _load_settings() -> void:
	var config := ConfigFile.new()
	if config.load(SETTINGS_PATH) != OK:
		return
	for category in volume_levels.keys():
		volume_levels[category] = clampf(float(config.get_value("audio", category, 1.0)), 0.0, 1.0)
	look_sensitivity = clampf(float(config.get_value("controls", "look_sensitivity", 1.0)), 0.25, 2.0)


func get_volume_levels() -> Dictionary:
	return volume_levels.duplicate()


func play_menu_music() -> void:
	var menu_stream := load(MENU_MUSIC_PATH) as AudioStreamMP3
	if menu_stream == null:
		return
	menu_stream.loop = true
	music_base_db = -24.0
	music_player.stop()
	music_player.stream = menu_stream
	_apply_volumes()
	music_player.play()


func play_story_music() -> void:
	_switch_music(STORY_MUSIC, -22.0)


func play_game_music() -> void:
	_switch_music(gameplay_music_stream, MUSIC_BASE_DB)


func _switch_music(stream: AudioStream, base_db: float) -> void:
	music_player.stop()
	music_player.stream = stream
	music_base_db = base_db
	_apply_volumes()
	music_player.play()


func get_look_sensitivity() -> float:
	return look_sensitivity


func set_volume_level(category: String, level: float) -> void:
	if not volume_levels.has(category):
		return
	volume_levels[category] = clampf(level, 0.0, 1.0)
	_apply_volumes()
	_save_settings()


func set_look_sensitivity(level: float) -> void:
	look_sensitivity = clampf(level, 0.25, 2.0)
	_save_settings()


func _save_settings() -> void:
	var config := ConfigFile.new()
	config.load(SETTINGS_PATH)
	for key in volume_levels.keys():
		config.set_value("audio", key, volume_levels[key])
	config.set_value("controls", "look_sensitivity", look_sensitivity)
	config.save(SETTINGS_PATH)


func _scaled_db(base_db: float, category: String) -> float:
	var level: float = volume_levels[category]
	return -80.0 if level <= 0.001 else base_db + linear_to_db(level)


func _apply_volumes() -> void:
	music_player.volume_db = _scaled_db(music_base_db - (13.0 if victory_sound_playing else 0.0), "music")
	for player in shot_players:
		player.volume_db = _scaled_db(GUN_BASE_DB, "gun")
	for player in hit_players:
		player.volume_db = _scaled_db(HIT_BASE_DB, "effects")
	craft_player.volume_db = _scaled_db(-5.0, "effects")
	shrine_player.volume_db = _scaled_db(-7.0, "effects")
	portal_player.volume_db = _scaled_db(-7.0, "effects")
	portal_ambience_player.volume_db = _scaled_db(-9.0, "effects")
	portal_travel_player.volume_db = _scaled_db(-4.0, "effects")
	victory_player.volume_db = _scaled_db(-3.0, "effects")
	reload_player.volume_db = _scaled_db(-5.0, "effects")
	if item_pickup_player != null:
		item_pickup_player.volume_db = _scaled_db(-5.0, "effects")
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
	shrine_player.stream = SHRINE_SOUNDS[shrine_sound_index]
	shrine_sound_index = (shrine_sound_index + 1) % SHRINE_SOUNDS.size()
	shrine_player.play()


func play_portal() -> void:
	portal_player.stop()
	portal_player.play()


func start_portal_ambience(place: Vector3) -> void:
	portal_ambience_player.stop()
	portal_ambience_player.global_position = place + Vector3(0.0, 1.6, 0.0)
	portal_ambience_player.play()


func stop_portal_ambience() -> void:
	portal_ambience_player.stop()


func play_portal_travel() -> void:
	portal_player.stop()
	if portal_travel_fade != null and portal_travel_fade.is_running():
		portal_travel_fade.kill()
	portal_travel_player.volume_db = _scaled_db(-4.0, "effects")
	portal_travel_player.stop()
	portal_travel_player.play()


func fade_portal_travel() -> void:
	if not portal_travel_player.playing:
		return
	portal_travel_fade = create_tween()
	portal_travel_fade.tween_property(portal_travel_player, "volume_db", -80.0, 0.65)
	portal_travel_fade.tween_callback(portal_travel_player.stop)


func play_victory() -> void:
	victory_sound_playing = true
	_switch_music(VICTORY_MUSIC, -20.0)
	victory_player.stop()
	victory_player.play()


func _victory_sound_finished() -> void:
	victory_sound_playing = false
	_apply_volumes()


func play_item_pickup() -> void:
	if item_pickup_player == null:
		return
	item_pickup_player.stop()
	item_pickup_player.play()


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
