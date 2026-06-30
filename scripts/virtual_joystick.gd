extends Control

signal action_pressed

@export var side: String = "left"
@export var max_radius: float = 90.0
@export var deadzone: float = 0.12

var touch_index: int = -1
var center: Vector2 = Vector2.ZERO
var output: Vector2 = Vector2.ZERO
var active: bool = false

@onready var base: Control = $Base
@onready var knob: Control = $Base/Knob


func _ready() -> void:
	base.modulate.a = 0.35
	knob.modulate.a = 0.65
	base.mouse_filter = Control.MOUSE_FILTER_IGNORE
	knob.mouse_filter = Control.MOUSE_FILTER_IGNORE


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
		if event.pressed and touch_index == -1:
			var rect := get_global_rect()
			if not rect.has_point(event.position):
				return
			touch_index = event.index
			center = event.position
			base.global_position = center - base.size * 0.5
			base.visible = true
			active = true
			_update_knob(event.position)
		elif not event.pressed and event.index == touch_index:
			_reset()
	elif event is InputEventScreenDrag and event.index == touch_index:
		_update_knob(event.position)


func _process(_delta: float) -> void:
	if not active:
		output = output.lerp(Vector2.ZERO, 0.2)


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
	touch_index = -1
	active = false
	output = Vector2.ZERO
	base.visible = false


func get_output() -> Vector2:
	if side == "left":
		return output
	return output
