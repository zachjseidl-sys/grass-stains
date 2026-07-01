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
	player.global_position = Vector3(10.5, 0.05, 6.0)
	player.look_at(Vector3(16.0, player.global_position.y, 24.0), Vector3.UP)
	_connect_systems()


func _setup_lighting() -> void:
	sun.rotation_degrees = Vector3(-42, -48, 0)
	sun.light_color = Color(1.0, 0.90, 0.68)
	sun.light_energy = 1.35
	sun.shadow_enabled = true
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
	sun.directional_shadow_max_distance = 55.0

	var fill := DirectionalLight3D.new()
	fill.name = "FillLight"
	fill.rotation_degrees = Vector3(-20, 120, 0)
	fill.light_color = Color(0.72, 0.82, 0.98)
	fill.light_energy = 0.28
	add_child(fill)

	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color(0.38, 0.58, 0.88)
	sky_mat.sky_horizon_color = Color(0.78, 0.84, 0.92)
	sky_mat.ground_bottom_color = Color(0.28, 0.34, 0.22)
	sky_mat.ground_horizon_color = Color(0.62, 0.72, 0.58)
	sky_mat.sun_angle_max = 28.0
	sky_mat.sun_curve = 0.08
	sky.sky_material = sky_mat
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.45
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.tonemap_exposure = 1.08
	env.ssao_enabled = true
	env.ssao_radius = 1.2
	env.ssao_intensity = 0.6
	env.glow_enabled = true
	env.glow_intensity = 0.35
	env.glow_bloom = 0.18
	env.fog_enabled = true
	env.fog_light_color = Color(0.92, 0.86, 0.72)
	env.fog_density = 0.0022
	env.fog_aerial_perspective = 0.15
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
