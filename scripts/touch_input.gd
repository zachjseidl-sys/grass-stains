extends CanvasLayer

@onready var move_joystick: Control = $MoveJoystick
@onready var camera_joystick: Control = $CameraJoystick
@onready var engine_button: Button = $EngineButton
@onready var desktop_hint: Label = $DesktopHint
@onready var job_label: Label = $JobCard/Margin/VBox/Job
@onready var career_label: Label = $JobCard/Margin/VBox/Career
@onready var progress_label: Label = $JobCard/Margin/VBox/Progress
@onready var combo_label: Label = $JobCard/Margin/VBox/Combo
@onready var player: CharacterBody3D = get_node("../Player")

var camera_controller: Node3D = null
var progress_ratio: float = 0.0
var streak: int = 0
var multiplier: float = 1.0

var _dragging_move: bool = false
var _dragging_camera: bool = false
var _drag_origin: Vector2 = Vector2.ZERO
var _fallback_move: Vector2 = Vector2.ZERO
var _fallback_camera: Vector2 = Vector2.ZERO


func _ready() -> void:
	engine_button.pressed.connect(_on_engine_button_pressed)
	player.engine_state_changed.connect(_on_engine_state_changed)
	_on_engine_state_changed(player.engine_state)
	_layout_for_screen()
	get_tree().root.size_changed.connect(_layout_for_screen)
	_update_job_card()
	_update_hint_text()


func _update_hint_text() -> void:
	if OS.has_feature("web") or DisplayServer.is_touchscreen_available():
		desktop_hint.text = "1) Tap Start Mower   2) Drag LEFT half = drive   3) Drag RIGHT half = look"
	else:
		desktop_hint.text = "WASD = drive · Space = start/stop · Hold LMB left half = drive · RMB = camera"


func _layout_for_screen() -> void:
	var size := get_viewport().get_visible_rect().size
	move_joystick.set_anchors_and_offsets_preset(Control.PRESET_LEFT_WIDE)
	move_joystick.offset_right = size.x * 0.5
	move_joystick.offset_bottom = size.y
	camera_joystick.set_anchors_and_offsets_preset(Control.PRESET_RIGHT_WIDE)
	camera_joystick.offset_left = size.x * 0.5
	camera_joystick.offset_right = size.x
	camera_joystick.offset_bottom = size.y
	engine_button.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	engine_button.offset_left = -260.0
	engine_button.offset_top = -120.0
	engine_button.offset_right = -20.0
	engine_button.offset_bottom = -20.0
	$JobCard.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	$JobCard.offset_left = 20.0
	$JobCard.offset_top = 88.0
	$JobCard.offset_right = 520.0
	$JobCard.offset_bottom = 248.0
	desktop_hint.add_theme_color_override("font_color", Color(1, 0.98, 0.92))
	desktop_hint.add_theme_font_size_override("font_size", 22)


func _unhandled_input(event: InputEvent) -> void:
	var size := get_viewport().get_visible_rect().size
	var mid_x := size.x * 0.5

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_grab_game_focus()
			if event.position.x < mid_x:
				_dragging_move = true
				_drag_origin = event.position
			else:
				_dragging_camera = true
				_drag_origin = event.position
		else:
			_dragging_move = false
			_dragging_camera = false
			_fallback_move = Vector2.ZERO
			_fallback_camera = Vector2.ZERO

	elif event is InputEventScreenTouch:
		if event.pressed:
			_grab_game_focus()
			if event.position.x < mid_x:
				_dragging_move = true
				_drag_origin = event.position
			else:
				_dragging_camera = true
				_drag_origin = event.position
		else:
			_dragging_move = false
			_dragging_camera = false
			_fallback_move = Vector2.ZERO
			_fallback_camera = Vector2.ZERO

	elif event is InputEventMouseMotion and (_dragging_move or _dragging_camera):
		var delta := event.position - _drag_origin
		var norm := delta / 120.0
		norm = norm.limit_length(1.0)
		if _dragging_move:
			_fallback_move = norm
		if _dragging_camera:
			_fallback_camera = norm

	elif event is InputEventScreenDrag:
		var delta := event.position - _drag_origin
		var norm := delta / 120.0
		norm = norm.limit_length(1.0)
		if _dragging_move:
			_fallback_move = norm
		if _dragging_camera:
			_fallback_camera = norm


func _process(_delta: float) -> void:
	if not is_instance_valid(player):
		return

	var move_out := move_joystick.get_output()
	var cam_out := camera_joystick.get_output()

	if _fallback_move.length() > move_out.length():
		move_out = _fallback_move
	if _fallback_camera.length() > cam_out.length():
		cam_out = _fallback_camera

	player.move_input = Vector2(move_out.x, -move_out.y)
	player.turn_input = move_out.x

	if camera_controller:
		camera_controller.yaw_input = cam_out.x
		camera_controller.pitch_input = cam_out.y

	_apply_keyboard_fallback()


func _apply_keyboard_fallback() -> void:
	var forward := Input.get_action_strength("move_forward") - Input.get_action_strength("move_back")
	var turn := Input.get_action_strength("turn_right") - Input.get_action_strength("turn_left")
	if absf(forward) > 0.01 or absf(turn) > 0.01:
		player.move_input = Vector2(turn, forward)
		player.turn_input = turn

	if Input.is_action_just_pressed("toggle_engine"):
		player.toggle_engine()

	if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		var motion := Input.get_last_mouse_velocity()
		if camera_controller:
			camera_controller.yaw_input = motion.x * 0.004
			camera_controller.pitch_input = motion.y * 0.004


func _on_engine_button_pressed() -> void:
	_grab_game_focus()
	player.toggle_engine()


func _grab_game_focus() -> void:
	var window_id := get_window().get_window_id()
	if window_id >= 0:
		DisplayServer.window_set_input_focus(window_id)


func _on_engine_state_changed(_state: int) -> void:
	engine_button.text = player.get_engine_button_label()


func set_progress(ratio: float) -> void:
	progress_ratio = ratio
	_update_job_card()


func set_streak(new_streak: int, new_multiplier: float) -> void:
	streak = new_streak
	multiplier = new_multiplier
	_update_job_card()


func _update_job_card() -> void:
	if not is_inside_tree():
		return
	var job := GameSettings.get_current_job()
	job_label.text = "%s — %s" % [job.get("name", "Next Job"), job.get("client", "Client")]
	career_label.text = "%s  •  Cash $%d  •  Rep %d" % [job.get("tier", "Side Hustle"), GameSettings.cash, GameSettings.reputation]
	progress_label.text = "Lawn %.1f%% / %.1f%% complete" % [progress_ratio * 100.0, float(job.get("threshold", GameSettings.MOW_COMPLETE_THRESHOLD)) * 100.0]
	combo_label.text = "Clean-cut streak %d  •  Tip x%.2f" % [streak, multiplier]
