extends SceneTree

var failures := 0
var capture_confirmations := 0


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
	game.set_physics_process(false)
	await process_frame
	var focus = game.gameplay_focus
	var resume_handler := Callable(game, "_resume_after_capture")
	focus.capture_confirmed.connect(func(): capture_confirmations += 1)
	_check(focus.active and not paused, "Native gameplay should begin with active mouse capture")
	_check(focus.captured, "Native gameplay should confirm capture before play begins")
	# A headless DisplayServer has no physical cursor and always reports VISIBLE.
	if DisplayServer.get_name() != "headless":
		_check(Input.mouse_mode == Input.MOUSE_MODE_CAPTURED, "Gameplay should capture the native cursor")

	game.trigger_held = true
	game.shot_requested = true
	game.aiming = true
	var escape := InputEventKey.new()
	escape.keycode = KEY_ESCAPE
	escape.pressed = true
	game._input(escape)
	_check(paused and game.sound_settings.visible, "Escape should pause gameplay and open Settings")
	_check(Input.mouse_mode == Input.MOUSE_MODE_VISIBLE, "Settings should release the cursor")
	_check(not game.trigger_held and not game.shot_requested and not game.aiming, "Pausing should clear held fire, queued shots and aim")

	# The capture-confirmed signal is the only route that may resume gameplay.
	# Disconnect it briefly to detect an early unpause in the Settings callback.
	focus.capture_confirmed.disconnect(resume_handler)
	game.sound_settings.resume_requested.emit()
	_check(not game.sound_settings.visible, "The Resume button should close Settings")
	_check(capture_confirmations == 1, "Settings Resume should request and confirm native mouse capture")
	_check(paused, "Settings Resume must not unpause before the capture-confirmed handler")
	focus.capture_confirmed.connect(resume_handler)
	game.trigger_held = true
	game.shot_requested = true
	focus.request_resume()
	_check(not paused and not focus.waiting_for_capture, "Confirmed native capture should resume gameplay")
	if DisplayServer.get_name() != "headless":
		_check(Input.mouse_mode == Input.MOUSE_MODE_CAPTURED, "Resuming should recapture the native cursor")
	_check(not game.trigger_held and not game.shot_requested, "Capture confirmation should discard held or queued fire")

	focus.show_resume_gate()
	_check(paused and focus.waiting_for_capture, "The resume gate should keep gameplay paused")
	var ammo_before: int = game.ammo
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	game._input(click)
	_check(paused and focus.waiting_for_capture, "A gameplay click must not bypass the resume gate")
	_check(not game.trigger_held and not game.shot_requested and game.ammo == ammo_before, "The first click after losing capture must not fire or queue a shot")
	focus.request_resume()
	_check(not paused and not focus.waiting_for_capture and focus.captured, "A native Resume request should restore confirmed capture and play")
	_check(not game.trigger_held and not game.shot_requested, "Returning from the resume gate must not leave the trigger active")

	print("gameplay_focus_failures=", failures)
	focus.deactivate()
	paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	for audio_player in game.find_children("*", "AudioStreamPlayer", true, false):
		audio_player.stop()
		audio_player.stream = null
	for audio_player in game.find_children("*", "AudioStreamPlayer3D", true, false):
		audio_player.stop()
		audio_player.stream = null
	await create_timer(.08).timeout
	game.queue_free()
	await process_frame
	call_deferred("_finish_test")


func _finish_test() -> void:
	quit(1 if failures > 0 else 0)
