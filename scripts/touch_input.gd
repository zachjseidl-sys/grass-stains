extends CanvasLayer

@onready var move_joystick: Control = $MoveJoystick
@onready var camera_joystick: Control = $CameraJoystick
@onready var engine_button: Button = $EngineButton
@onready var player: CharacterBody3D = get_node("../Player")

var camera_controller: Node3D = null


func _ready() -> void:
	engine_button.pressed.connect(_on_engine_button_pressed)
	player.engine_state_changed.connect(_on_engine_state_changed)
	_on_engine_state_changed(player.engine_state)


func _process(_delta: float) -> void:
	if not is_instance_valid(player):
		return

	var move_out := move_joystick.get_output() if move_joystick.has_method("get_output") else Vector2.ZERO
	var cam_out := camera_joystick.get_output() if camera_joystick.has_method("get_output") else Vector2.ZERO

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
	player.toggle_engine()


func _on_engine_state_changed(state: int) -> void:
	engine_button.text = player.get_engine_button_label()
	engine_button.disabled = state == player.EngineState.STARTING
