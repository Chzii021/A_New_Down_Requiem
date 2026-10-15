extends SceneTree

var failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, label: String) -> void:
	if not condition:
		failures += 1
		push_error(label)


func _run() -> void:
	var game = preload("res://Main.tscn").instantiate()
	game.stage = 4
	root.add_child(game)
	await process_frame
	_check(game.enemies.size() == 36, "Stage 4 boss and villagers should load")
	var first = game.enemies[game.boss_enemy_index + 1]
	var second = game.enemies[game.boss_enemy_index + 2]
	first["emergence"] = 1.0
	second["emergence"] = 1.0
	first["node"].global_position = Vector3(0, 0, 0)
	second["node"].global_position = Vector3(0, 0, 0)
	game._resolve_enemy_overlaps()
	_check(first["node"].global_position.distance_to(second["node"].global_position) >= 1.34, "Villagers should not overlap")
	var old_quality: int = game.game_audio.graphics_quality
	game.game_audio.graphics_quality = 0
	game.game_audio.apply_video_settings()
	_check(is_equal_approx(root.get_viewport().scaling_3d_scale, .55), "Low graphics should lower 3D resolution")
	game.game_audio.graphics_quality = old_quality
	game.game_audio.apply_video_settings()
	game._update_boss_spirits(2.0)
	_check(is_instance_valid(game.boss_pulse_marker), "Boss should target player from stage start")
	game._clear_boss_pulse()
	game.rescued_stage = 35
	game.boss_vulnerable = true
	game._hit_enemy(game.boss_enemy_index, 26)
	_check(game.boss_enraged, "Boss should enrage below half health")
	game._update_boss_sweep(2.3)
	_check(game.boss_sweep_markers.size() == 3, "Enraged boss should telegraph spirit sweep")
	game._clear_boss_sweep()
	game._hit_enemy(game.boss_enemy_index, 24)
	var grandma = game.enemies[game.boss_enemy_index]
	for tick in range(420):
		game._update_rescued_villager(grandma, 1.0 / 60.0)
	_check(grandma["retreated"] and grandma["node"].sitting, "Freed grandma should sit in the hall")
	print("boss_mechanics_failures=", failures)
	game.queue_free()
	await process_frame
	call_deferred("_finish_test")


func _finish_test() -> void:
	quit(1 if failures > 0 else 0)
