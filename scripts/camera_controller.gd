extends Node3D

@export var yaw_input: float = 0.0
@export var pitch_input: float = 0.0

@onready var yaw_pivot: Node3D = $CameraPivot
@onready var pitch_pivot: Node3D = $CameraPivot/PitchPivot
@onready var spring_arm: SpringArm3D = $CameraPivot/PitchPivot/SpringArm3D

var target_yaw: float = 0.0
var target_pitch: float = -0.18
var min_pitch := -0.26
var max_pitch := 0.55


func _ready() -> void:
	spring_arm.add_exception(get_parent())
	if get_parent() is PhysicsBody3D:
		for child in get_parent().get_children():
			if child is CollisionObject3D:
				spring_arm.add_exception(child)


func _physics_process(delta: float) -> void:
	target_yaw -= yaw_input * delta * 1.8
	target_pitch = clampf(target_pitch - pitch_input * delta * 1.2, min_pitch, max_pitch)

	yaw_pivot.rotation.y = lerp_angle(yaw_pivot.rotation.y, target_yaw, 8.0 * delta)
	pitch_pivot.rotation.x = lerp(pitch_pivot.rotation.x, target_pitch, 8.0 * delta)

	yaw_input = 0.0
	pitch_input = 0.0
