extends Node3D

@export var instance_count: int = 6800
@export var lawn_origin: Vector2 = GameSettings.LAWN_ORIGIN
@export var lawn_size: Vector2 = GameSettings.LAWN_SIZE

@onready var multimesh_instance: MultiMeshInstance3D = $GrassMultiMesh

var mask_manager: Node = null


func _ready() -> void:
	if OS.has_feature("web"):
		instance_count = 3600
	_build_grass()


func setup(mask: Node) -> void:
	mask_manager = mask
	if mask_manager:
		update_mask_texture(mask_manager.get_mask_texture())


func update_mask_texture(tex: Texture2D) -> void:
	var mat: ShaderMaterial = multimesh_instance.material_override as ShaderMaterial
	if mat and tex:
		mat.set_shader_parameter("mow_mask", tex)


func _build_grass() -> void:
	var blade_mesh := _create_blade_mesh()
	var multi := MultiMesh.new()
	multi.transform_format = MultiMesh.TRANSFORM_3D
	multi.use_colors = false
	multi.mesh = blade_mesh
	multi.instance_count = instance_count

	var rng := RandomNumberGenerator.new()
	rng.seed = 1998

	for i in instance_count:
		var x := rng.randf_range(lawn_origin.x + 0.4, lawn_origin.x + lawn_size.x - 0.4)
		var z := rng.randf_range(lawn_origin.y + 0.4, lawn_origin.y + lawn_size.y - 0.4)
		var rot := rng.randf_range(0.0, TAU)
		var scale := rng.randf_range(0.8, 1.35)
		var basis := Basis(Vector3.UP, rot).scaled(Vector3(1.0, scale, 1.0))
		var transform := Transform3D(basis, Vector3(x, 0.0, z))
		multi.set_instance_transform(i, transform)

	multimesh_instance.multimesh = multi

	var noise := FastNoiseLite.new()
	noise.seed = 42
	noise.frequency = 0.08
	var noise_tex := NoiseTexture2D.new()
	noise_tex.noise = noise
	noise_tex.width = 256
	noise_tex.height = 256

	var shader := load("res://shaders/grass.gdshader") as Shader
	var mat := ShaderMaterial.new()
	mat.shader = shader
	mat.set_shader_parameter("wind_noise", noise_tex)
	mat.set_shader_parameter("lawn_origin", lawn_origin)
	mat.set_shader_parameter("lawn_size", lawn_size)
	multimesh_instance.material_override = mat
	multimesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


func _create_blade_mesh() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var w := 0.08
	var h := 0.44

	for angle in [0.0, PI * 0.5]:
		var dir := Vector3(cos(angle), 0.0, sin(angle)) * w
		var v0 := Vector3(-dir.x, 0.0, -dir.z)
		var v1 := Vector3(dir.x, 0.0, dir.z)
		var v2 := Vector3(dir.x, h, dir.z)
		var v3 := Vector3(-dir.x, h, -dir.z)
		st.set_uv(Vector2(0, 1)); st.add_vertex(v0)
		st.set_uv(Vector2(1, 1)); st.add_vertex(v1)
		st.set_uv(Vector2(1, 0)); st.add_vertex(v2)
		st.set_uv(Vector2(0, 1)); st.add_vertex(v0)
		st.set_uv(Vector2(1, 0)); st.add_vertex(v2)
		st.set_uv(Vector2(0, 0)); st.add_vertex(v3)

	return st.commit()
