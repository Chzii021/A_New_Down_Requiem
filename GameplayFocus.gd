extends CanvasLayer

signal pause_requested
signal capture_confirmed

var active := false
var waiting_for_capture := false
var captured := false
var _request_pending := false
var _overlay: Control
var _heading: Label
var _hint: Label
var _resume: Button
var _document: JavaScriptObject
var _browser_window: JavaScriptObject
var _lock_callback: JavaScriptObject
var _error_callback: JavaScriptObject
var _blur_callback: JavaScriptObject


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 100
	_build_overlay()
	get_window().focus_exited.connect(_on_focus_lost)
	if OS.has_feature("web"):
		_document = JavaScriptBridge.get_interface("document")
		_browser_window = JavaScriptBridge.get_interface("window")
		_lock_callback = JavaScriptBridge.create_callback(_on_browser_lock_changed)
		_error_callback = JavaScriptBridge.create_callback(_on_browser_lock_error)
		_blur_callback = JavaScriptBridge.create_callback(_on_browser_blur)
		_document.addEventListener("pointerlockchange", _lock_callback)
		_document.addEventListener("pointerlockerror", _error_callback)
		_browser_window.addEventListener("blur", _blur_callback)


func activate(from_input_event: bool = false) -> void:
	active = true
	if from_input_event or not OS.has_feature("web"):
		request_resume()
	else:
		show_resume_gate(true)


func deactivate() -> void:
	active = false
	_request_pending = false
	waiting_for_capture = false
	_overlay.hide()


func menu_opened() -> void:
	_request_pending = false
	waiting_for_capture = false
	_overlay.hide()


func show_resume_gate(starting: bool = false) -> void:
	if not active:
		return
	_request_pending = false
	waiting_for_capture = true
	get_tree().paused = true
	_heading.text = "พร้อมเข้าสู่เกม" if starting else "หยุดชั่วคราว"
	_hint.text = "คลิกเพื่อเริ่มควบคุมตัวละคร" if starting else "คลิกกลับไปเล่น เพื่อควบคุมเมาส์ในเกม"
	_resume.text = "เริ่มเล่น / PLAY" if starting else "กลับไปเล่น / RESUME"
	_overlay.show()


func request_resume() -> void:
	if not active:
		return
	waiting_for_capture = true
	_request_pending = true
	# This must run directly from a real click/key event on the web.
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	if not OS.has_feature("web"):
		_confirm_capture()
	elif _document.pointerLockElement != null:
		_confirm_capture()
	else:
		# Keep the game paused until the browser confirms pointer lock.
		get_tree().paused = true
		_overlay.show()


func _confirm_capture() -> void:
	if not active:
		return
	captured = true
	_request_pending = false
	waiting_for_capture = false
	_overlay.hide()
	capture_confirmed.emit()


func _on_browser_lock_changed(_arguments: Array) -> void:
	var was_captured := captured
	captured = _document.pointerLockElement != null
	if not active:
		return
	if captured and _request_pending:
		_confirm_capture()
	elif not captured:
		if _request_pending:
			show_resume_gate()
		elif was_captured:
			pause_requested.emit()


func _on_browser_lock_error(_arguments: Array) -> void:
	if active and _request_pending:
		show_resume_gate()


func _on_browser_blur(_arguments: Array) -> void:
	_on_focus_lost()


func _on_focus_lost() -> void:
	if active:
		pause_requested.emit()


func _unhandled_key_input(event: InputEvent) -> void:
	if waiting_for_capture and event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		pause_requested.emit()


func _build_overlay() -> void:
	var font := preload("res://PixelFont.gd").make()
	_overlay = Control.new()
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_overlay)
	var shade := ColorRect.new()
	shade.color = Color(.025, .035, .035, .72)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay.add_child(shade)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay.add_child(center)
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color("182a27")
	style.border_color = Color("bba46d")
	style.set_border_width_all(2)
	style.content_margin_left = 34
	style.content_margin_right = 34
	style.content_margin_top = 25
	style.content_margin_bottom = 25
	panel.add_theme_stylebox_override("panel", style)
	center.add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 18)
	panel.add_child(column)
	_heading = Label.new()
	_heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_heading.add_theme_font_override("font", font)
	_heading.add_theme_font_size_override("font_size", 27)
	column.add_child(_heading)
	_hint = Label.new()
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint.add_theme_font_override("font", font)
	_hint.add_theme_font_size_override("font_size", 17)
	column.add_child(_hint)
	_resume = Button.new()
	_resume.custom_minimum_size = Vector2(330, 48)
	_resume.focus_mode = Control.FOCUS_NONE
	_resume.add_theme_font_override("font", font)
	_resume.add_theme_font_size_override("font_size", 23)
	_resume.button_down.connect(request_resume)
	column.add_child(_resume)
	_overlay.hide()


func _exit_tree() -> void:
	active = false
	if _document != null:
		_document.removeEventListener("pointerlockchange", _lock_callback)
		_document.removeEventListener("pointerlockerror", _error_callback)
		_browser_window.removeEventListener("blur", _blur_callback)
