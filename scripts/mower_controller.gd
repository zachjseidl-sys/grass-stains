extends CharacterBody3D

enum EngineState { OFF, STARTING, IDLE, RUNNING }

signal engine_state_changed(state: EngineState)
signal cut_occurred(newly_cut: int, world_position: Vector3)

@export var move_input: Vector2 = Vector2.ZERO
@export var turn_input: float = 0.0

var engine_state: EngineState = EngineState.OFF
var speed: float = 0.0
var grass_resistance: float = 1.0
var mow_timer: float = 0.0
var haptic_cooldown: float = 0.0

@onready var mower_pivot: Node3D = $MowerPivot
@onready var deck_marker: Marker3D = $MowerPivot/DeckMarker
@onready var clipping_particles: GPUParticles3D = $MowerPivot/ClippingParticles
@onready var engine_audio: AudioStreamPlayer3D = $EngineAudio
@onready var cut_audio: AudioStreamPlayer3D = $CutAudio

var mask_manager: Node = null
var audio_manager: Node = null


func _ready() -> void:
	clipping_particles.emitting = false
	if engine_audio.stream:
		engine_audio.stream.loop = true
	if cut_audio.stream:
		cut_audio.stream.loop = true


func _physics_process(delta: float) -> void:
	_apply_movement(delta)
	_apply_mowing(delta)
	haptic_cooldown = maxf(haptic_cooldown - delta, 0.0)


func _apply_movement(delta: float) -> void:
	var max_speed := GameSettings.MAX_SPEED
	var target_speed := move_input.y * max_speed

	if engine_state != EngineState.RUNNING:
		target_speed *= 0.5

	if engine_state == EngineState.RUNNING:
		target_speed *= lerpf(1.0, GameSettings.GRASS_RESISTANCE, 1.0 - grass_resistance)

	var rate := GameSettings.ACCEL if absf(target_speed) > absf(speed) else GameSettings.DECEL
	speed = move_toward(speed, target_speed, rate * delta)

	var turn_scale := lerpf(1.0, GameSettings.TURN_RATE_FAST / GameSettings.TURN_RATE, absf(speed) / GameSettings.MAX_SPEED)
	rotate_y(-turn_input * GameSettings.TURN_RATE * turn_scale * delta)

	velocity = -global_transform.basis.z * speed
	move_and_slide()

	_update_audio_load()


func _apply_mowing(delta: float) -> void:
	if engine_state != EngineState.RUNNING or mask_manager == null:
		clipping_particles.emitting = false
		if cut_audio.playing:
			cut_audio.stop()
		return

	mow_timer += delta
	if mow_timer < 0.03:
		return
	mow_timer = 0.0

	var deck_pos := deck_marker.global_position
	var deck_xz := Vector2(deck_pos.x, deck_pos.z)
	var facing := Vector2(-global_transform.basis.z.x, -global_transform.basis.z.z).normalized()
	var result: Dictionary = mask_manager.stamp_deck(
		deck_xz,
		facing,
		GameSettings.DECK_RADIUS,
		GameSettings.DECK_WIDTH
	)

	grass_resistance = result.get("resistance", 1.0)
	var newly_cut: int = result.get("newly_cut", 0)

	if newly_cut > 0:
		cut_occurred.emit(newly_cut, deck_pos)
		clipping_particles.emitting = true
		if not cut_audio.playing:
			cut_audio.play()
		if haptic_cooldown <= 0.0 and not OS.has_feature("web"):
			Input.vibrate_handheld(20)
			haptic_cooldown = 0.15
	else:
		clipping_particles.emitting = false
		if cut_audio.playing and absf(speed) < 0.05:
			cut_audio.stop()


func _update_audio_load() -> void:
	if engine_state != EngineState.RUNNING or not engine_audio.playing:
		return
	var load := clampf(absf(speed) / GameSettings.MAX_SPEED, 0.0, 1.0)
	var resistance_load := 1.0 - grass_resistance
	engine_audio.pitch_scale = lerpf(0.95, 1.18, maxf(load, resistance_load * 0.6))
	engine_audio.volume_db = lerpf(-8.0, -2.0, maxf(load, resistance_load * 0.5))


func pull_starter_cord() -> void:
	if engine_state != EngineState.OFF:
		return
	engine_state = EngineState.RUNNING
	engine_state_changed.emit(engine_state)
	if audio_manager:
		audio_manager.play_starter_cord()
		audio_manager.on_engine_running()
	if engine_audio.stream:
		engine_audio.play()


func stop_engine() -> void:
	if engine_state == EngineState.OFF:
		return
	engine_state = EngineState.OFF
	engine_state_changed.emit(engine_state)
	speed = 0.0
	clipping_particles.emitting = false
	if engine_audio.playing:
		engine_audio.stop()
	if cut_audio.playing:
		cut_audio.stop()


func toggle_engine() -> void:
	if engine_state == EngineState.OFF:
		pull_starter_cord()
	else:
		stop_engine()


func get_engine_button_label() -> String:
	return "Stop" if engine_state == EngineState.RUNNING else "Start Mower"


func is_engine_running() -> bool:
	return engine_state == EngineState.RUNNING
