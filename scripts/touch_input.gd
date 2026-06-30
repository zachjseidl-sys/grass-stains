extends CanvasLayer

@onready var move_joystick: Control = $MoveJoystick
@onready var camera_joystick: Control = $CameraJoystick
@onready var engine_button: Button = $EngineButton
@onready var desktop_hint: Label = $DesktopHint
@onready var player: CharacterBody3D = get_node("../Player")

var camera_controller: Node3D = null


func _ready() -> void:
	engine_button.pressed.connect(_on_engine_button_pressed)
	player.engine_state_changed.connect(_on_engine_state_changed)
	_on_engine_state_changed(player.engine_state)
	_layout_for_screen()
	get_tree().root.size_changed.connect(_layout_for_screen)

	if OS.has_feature("web"):
		desktop_hint.text = "Tap Pull Cord to start · Drag left side to move · Drag right side for camera"
	elif DisplayServer.is_touchscreen_available():
		desktop_hint.text = "Pull Cord to start · Left thumb move · Right thumb camera"
	else:
		desktop_hint.text = "Click game to focus · WASD move · Space pull cord · Drag sides or hold RMB"


func _layout_for_screen() -> void:
	var size := get_viewport().get_visible_rect().size
	move_joystick.set_anchors_preset(Control.PRESET_LEFT_WIDE)
	move_joystick.offset_right = size.x * 0.5
	move_joystick.offset_bottom = size.y
	camera_joystick.set_anchors_preset(Control.PRESET_RIGHT_WIDE)
	camera_joystick.offset_left = size.x * 0.5
	camera_joystick.offset_right = size.x
	camera_joystick.offset_bottom = size.y
	engine_button.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	engine_button.offset_left = -280.0
	engine_button.offset_top = -140.0
	engine_button.offset_right = -20.0
	engine_button.offset_bottom = -20.0


func _process(_delta: float) -> void:
	if not is_instance_valid(player):
		return

	var move_out := move_joystick.get_output()
	var cam_out := camera_joystick.get_output()

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


func _on_engine_state_changed(state: int) -> void:
	engine_button.text = player.get_engine_button_label()
	engine_button.disabled = state == player.EngineState.STARTING
