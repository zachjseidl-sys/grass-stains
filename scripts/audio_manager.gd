extends Node

@onready var birds: AudioStreamPlayer = $Birds
@onready var wind: AudioStreamPlayer = $Wind
@onready var starter: AudioStreamPlayer = $Starter
@onready var engine_idle: AudioStreamPlayer = $EngineIdle
@onready var engine_load: AudioStreamPlayer = $EngineLoad
@onready var grass_cut: AudioStreamPlayer = $GrassCut

var load_blend: float = 0.0


func _ready() -> void:
	for player in [birds, wind, engine_idle, engine_load, grass_cut]:
		if player.stream and player.stream is AudioStreamWAV:
			player.stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		elif player.stream:
			player.stream.loop = true

	if birds.stream:
		birds.volume_db = -14.0
		birds.play()
	if wind.stream:
		wind.volume_db = -20.0
		wind.play()


func play_starter_cord() -> void:
	if starter.stream:
		starter.play()


func on_engine_running() -> void:
	if engine_idle.stream and not engine_idle.playing:
		engine_idle.play()
	if engine_load.stream and not engine_load.playing:
		engine_load.volume_db = -80.0
		engine_load.play()


func set_engine_load(amount: float) -> void:
	load_blend = clampf(amount, 0.0, 1.0)
	if engine_idle.stream:
		engine_idle.volume_db = lerpf(-6.0, -16.0, load_blend)
	if engine_load.stream:
		engine_load.volume_db = lerpf(-80.0, -4.0, load_blend)


func set_cutting_active(active: bool) -> void:
	if not grass_cut.stream:
		return
	if active and not grass_cut.playing:
		grass_cut.play()
	elif not active and grass_cut.playing:
		grass_cut.stop()
