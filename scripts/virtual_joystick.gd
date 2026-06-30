extends Control

@export var max_radius: float = 90.0
@export var deadzone: float = 0.12

var pointer_index: int = -1
var center: Vector2 = Vector2.ZERO
var output: Vector2 = Vector2.ZERO
var active: bool = false
var using_mouse: bool = false

@onready var base: Control = $Base
@onready var knob: Control = $Base/Knob


func _ready() -> void:
	base.mouse_filter = Control.MOUSE_FILTER_IGNORE
	knob.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mouse_filter = Control.MOUSE_FILTER_STOP


func _draw() -> void:
	if not base.visible:
		return
	var base_center := base.size * 0.5
	draw_circle(base_center, max_radius, Color(1, 1, 1, 0.08))
	draw_arc(base_center, max_radius, 0, TAU, 48, Color(1, 1, 1, 0.25), 2.0)
	var knob_center := knob.position + knob.size * 0.5
	draw_circle(knob_center, 36.0, Color(0.95, 0.92, 0.82, 0.55))


func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		_handle_press(event.index, event.position, event.pressed, false)
	elif event is InputEventScreenDrag:
		if event.index == pointer_index:
			_update_knob(event.position)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_handle_press(0, event.position, event.pressed, true)
	elif event is InputEventMouseMotion:
		if active and using_mouse and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			_update_knob(event.position)


func _handle_press(index: int, pos: Vector2, pressed: bool, mouse: bool) -> void:
	if pressed:
		if pointer_index != -1:
			return
		if not get_global_rect().has_point(pos):
			return
		pointer_index = index
		using_mouse = mouse
		center = pos
		base.global_position = center - base.size * 0.5
		base.visible = true
		active = true
		_update_knob(pos)
		accept_event()
	else:
		if index == pointer_index or (mouse and using_mouse):
			_reset()
			accept_event()


func _process(delta: float) -> void:
	if not active:
		output = output.lerp(Vector2.ZERO, 0.2 * delta * 60.0)


func _update_knob(pos: Vector2) -> void:
	var delta := pos - center
	if delta.length() > max_radius:
		delta = delta.normalized() * max_radius
	knob.position = base.size * 0.5 - knob.size * 0.5 + delta
	var norm := delta / max_radius
	if norm.length() < deadzone:
		output = Vector2.ZERO
	else:
		output = norm.normalized() * ((norm.length() - deadzone) / (1.0 - deadzone))
	queue_redraw()


func _reset() -> void:
	pointer_index = -1
	using_mouse = false
	active = false
	output = Vector2.ZERO
	base.visible = false


func get_output() -> Vector2:
	return output
