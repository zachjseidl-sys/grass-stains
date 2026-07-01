extends Node3D

@onready var mask_manager: Node = $MowMaskManager
@onready var property_env: Node3D = $Property
@onready var grass_field: Node3D = $GrassField
@onready var player: CharacterBody3D = $Player
@onready var touch_ui: CanvasLayer = $TouchUI
@onready var grading_screen: CanvasLayer = $GradingScreen
@onready var opening: CanvasLayer = $OpeningSequence
@onready var audio_manager: Node = $AudioManager
@onready var world_env: WorldEnvironment = $WorldEnvironment
@onready var sun: DirectionalLight3D = $DirectionalLight3D

var mowing_started: bool = false


func _ready() -> void:
	Engine.max_fps = 60
	_setup_lighting()
	player.global_position = Vector3(10.5, 0.05, 8.0)
	player.look_at(Vector3(14.0, player.global_position.y, 22.0), Vector3.UP)
	_connect_systems()


func _setup_lighting() -> void:
	sun.rotation_degrees = Vector3(-38, -35, 0)
	sun.light_color = Color(1.0, 0.88, 0.62)
	sun.light_energy = 1.45
	sun.shadow_enabled = true

	var fill := DirectionalLight3D.new()
	fill.name = "FillLight"
	fill.rotation_degrees = Vector3(-18, 145, 0)
	fill.light_color = Color(0.68, 0.78, 0.95)
	fill.light_energy = 0.35
	add_child(fill)

	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.72, 0.84, 0.96)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.88, 0.82, 0.72)
	env.ambient_light_energy = 0.55
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 1.12

	if not OS.has_feature("web"):
		env.ssao_enabled = true
		env.glow_enabled = true
		env.glow_intensity = 0.25
		env.fog_enabled = true
		env.fog_light_color = Color(0.92, 0.86, 0.72)
		env.fog_density = 0.0018

	world_env.environment = env


func _connect_systems() -> void:
	property_env.setup(mask_manager)
	grass_field.setup(mask_manager)

	player.mask_manager = mask_manager
	player.audio_manager = audio_manager
	touch_ui.camera_controller = player.get_node("CameraRig")

	mask_manager.progress_changed.connect(_on_progress_changed)
	mask_manager.streak_changed.connect(_on_streak_changed)
	mask_manager.lawn_complete.connect(_on_lawn_complete)
	player.engine_state_changed.connect(_on_engine_state_changed)

	var mask_tex: Texture2D = mask_manager.get_mask_texture()
	property_env.update_mask_texture(mask_tex)
	grass_field.update_mask_texture(mask_tex)


func _on_progress_changed(ratio: float) -> void:
	if touch_ui.has_method("set_progress"):
		touch_ui.set_progress(ratio)
	if not mowing_started and ratio > 0.001:
		mowing_started = true
		grading_screen.start_timer()


func _on_streak_changed(streak: int, multiplier: float) -> void:
	if touch_ui.has_method("set_streak"):
		touch_ui.set_streak(streak, multiplier)


func _on_lawn_complete(stats: Dictionary) -> void:
	touch_ui.visible = false
	var career := GameSettings.complete_job(stats)
	stats["career"] = career
	grading_screen.show_results(stats)


func _on_engine_state_changed(state: int) -> void:
	if state != player.EngineState.RUNNING and player.cut_audio.playing:
		player.cut_audio.stop()
