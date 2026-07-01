extends Node3D

@onready var ground_mesh: MeshInstance3D = $Ground
@onready var ambient_birds: AudioStreamPlayer = $AmbientBirds
@onready var ambient_wind: AudioStreamPlayer = $AmbientWind

var mask_manager: Node = null
var _props: Node3D


func _ready() -> void:
	_props = Node3D.new()
	_props.name = "Neighborhood"
	add_child(_props)
	_build_ground()
	_build_neighborhood()
	_start_ambience()


func setup(mask: Node) -> void:
	mask_manager = mask
	update_mask_texture(mask.get_mask_texture() if mask else null)


func update_mask_texture(tex: Texture2D) -> void:
	var mat: ShaderMaterial = ground_mesh.material_override as ShaderMaterial
	if mat and tex:
		mat.set_shader_parameter("mow_mask", tex)


func _build_ground() -> void:
	var plane := PlaneMesh.new()
	plane.size = Vector2(90, 90)
	ground_mesh.mesh = plane
	ground_mesh.position = Vector3(8, -0.02, 10)

	var shader := load("res://shaders/ground.gdshader") as Shader
	var mat := ShaderMaterial.new()
	mat.shader = shader
	mat.set_shader_parameter("lawn_origin", GameSettings.LAWN_ORIGIN)
	mat.set_shader_parameter("lawn_size", GameSettings.LAWN_SIZE)
	mat.set_shader_parameter(
		"street_bounds",
		Vector4(
			GameSettings.STREET_X_MIN,
			GameSettings.STREET_Z_MIN,
			GameSettings.STREET_X_MAX,
			GameSettings.STREET_Z_MAX
		)
	)
	ground_mesh.material_override = mat


func _build_neighborhood() -> void:
	_build_street_props()
	_build_player_home()
	_build_neighbor_row(-1)
	_add_parked_car(Vector3(1.2, 0, -4))
	_add_mailbox(Vector3(7.5, 0, 30))
	_add_street_lamp(Vector3(4.5, 0, 8))
	_add_street_lamp(Vector3(4.5, 0, 24))
	_add_white_fence_line(Vector3(18.5, 0, 12), 34.0, 0)
	_add_white_fence_line(Vector3(18.5, 0, 12), 34.0, 90)
	_add_static_collisions()
	_add_ground_collision()


func _build_street_props() -> void:
	_add_mesh_box("StreetSign", Vector3(5.2, 1.6, 2), Vector3(0.12, 2.8, 0.12), Color(0.28, 0.26, 0.24))
	_add_mesh_box("StreetSignBoard", Vector3(5.35, 2.5, 2), Vector3(1.4, 0.35, 0.08), Color(0.16, 0.34, 0.22))
	_add_mesh_box("Hydrant", Vector3(-1.5, 0.35, 14), Vector3(0.35, 0.7, 0.35), Color(0.78, 0.18, 0.14))
	for z in [-10, -2, 6, 14, 22, 30]:
		_add_tree(Vector3(-9.5, 0, float(z)), 0.9 + float(z % 3) * 0.08)


func _build_player_home() -> void:
	var hx := 14.0
	var hz := -2.0
	_add_house("YourHouse", Vector3(hx, 0, hz), Color(0.82, 0.74, 0.58), Color(0.42, 0.24, 0.18), true)
	_add_mesh_box("YourPorch", Vector3(hx - 2.5, 0.18, hz + 5.5), Vector3(5.5, 0.36, 2.5), Color(0.68, 0.58, 0.44))
	_add_mesh_box("YourDriveway", Vector3(10.5, 0.025, 8), Vector3(4.5, 0.05, 14), Color(0.50, 0.48, 0.45))
	_add_mesh_box("Garage", Vector3(hx + 4, 1.6, hz + 1), Vector3(4.5, 3.2, 5.5), Color(0.72, 0.66, 0.58))
	_add_garage_door(Vector3(hx + 4, 0.9, hz + 3.8))
	_add_flower_bed(Vector3(9, 0, 28), 5.0)
	_add_flower_bed(Vector3(16, 0, 32), 4.0)
	_add_maple_tree(Vector3(11, 0, 20))
	_add_shrub_cluster(Vector3(8, 0, 14))
	_add_shrub_cluster(Vector3(17, 0, 18))


func _build_neighbor_row(side: int) -> void:
	var base_x := -14.0 * side
	for i in range(3):
		var z := float(i * 14 - 4)
		var palette := [
			[Color(0.76, 0.70, 0.62), Color(0.34, 0.40, 0.48)],
			[Color(0.70, 0.76, 0.66), Color(0.48, 0.28, 0.22)],
			[Color(0.84, 0.78, 0.70), Color(0.38, 0.34, 0.30)],
		][i]
		_add_house("Neighbor_%d_%d" % [side, i], Vector3(base_x, 0, z), palette[0], palette[1], false)
		if i == 1:
			_add_mesh_box("NeighborPorch_%d" % side, Vector3(base_x + 2.8 * side, 0.15, z + 4), Vector3(3.5, 0.3, 2), palette[0] * 0.9)


func _add_house(name: String, origin: Vector3, siding: Color, roof: Color, detailed: bool) -> void:
	var body := _add_mesh_box("%s_Body" % name, origin + Vector3(0, 2.2, 0), Vector3(9, 4.4, 7), siding)
	body.name = name
	_add_mesh_box("%s_Roof" % name, origin + Vector3(0, 5.0, 0), Vector3(10, 0.5, 8), roof)
	_add_mesh_box("%s_RoofPeakL" % name, origin + Vector3(-2.2, 5.8, 0), Vector3(5.2, 0.35, 8.2), roof * 0.92)
	_add_mesh_box("%s_RoofPeakR" % name, origin + Vector3(2.2, 5.8, 0), Vector3(5.2, 0.35, 8.2), roof * 0.88)
	_add_window(origin + Vector3(-2.5, 2.5, 3.55), 1.2, 1.4)
	_add_window(origin + Vector3(0.0, 2.5, 3.55), 1.2, 1.4)
	_add_window(origin + Vector3(2.5, 2.5, 3.55), 1.2, 1.4)
	if detailed:
		_add_window(origin + Vector3(-2.5, 2.5, -3.55), 1.0, 1.2, 0.4)
		_add_door(origin + Vector3(0, 1.1, 3.58))


func _add_window(pos: Vector3, w: float, h: float, glow: float = 0.75) -> void:
	var frame := _add_mesh_box("", pos, Vector3(w, h, 0.08), Color(0.92, 0.88, 0.78))
	var glass := _add_mesh_box("", pos + Vector3(0, 0, 0.02), Vector3(w * 0.82, h * 0.82, 0.04), Color(0.55, 0.72, 0.88))
	glass.material_override = _make_mat(Color(0.95, 0.82, 0.55), 0.15, glow)


func _add_door(pos: Vector3) -> void:
	_add_mesh_box("", pos, Vector3(1.1, 2.2, 0.12), Color(0.36, 0.22, 0.14))
	_add_mesh_box("", pos + Vector3(0.42, 0, 0.08), Vector3(0.08, 0.08, 0.08), Color(0.85, 0.7, 0.2))


func _add_garage_door(pos: Vector3) -> void:
	_add_mesh_box("", pos, Vector3(3.6, 2.2, 0.1), Color(0.62, 0.62, 0.64))


func _add_parked_car(pos: Vector3) -> void:
	_add_mesh_box("CarBody", pos + Vector3(0, 0.55, 0), Vector3(1.8, 0.7, 3.8), Color(0.18, 0.22, 0.28))
	_add_mesh_box("CarCab", pos + Vector3(0, 1.0, -0.3), Vector3(1.6, 0.55, 2.0), Color(0.20, 0.24, 0.30))
	_add_mesh_box("CarWheelFL", pos + Vector3(-0.75, 0.2, 1.1), Vector3(0.35, 0.35, 0.2), Color(0.1, 0.1, 0.1))
	_add_mesh_box("CarWheelFR", pos + Vector3(0.75, 0.2, 1.1), Vector3(0.35, 0.35, 0.2), Color(0.1, 0.1, 0.1))


func _add_mailbox(pos: Vector3) -> void:
	_add_mesh_box("", pos + Vector3(0, 0.55, 0), Vector3(0.12, 1.1, 0.12), Color(0.28, 0.26, 0.24))
	_add_mesh_box("", pos + Vector3(0, 1.15, 0), Vector3(0.45, 0.32, 0.65), Color(0.16, 0.34, 0.58))


func _add_street_lamp(pos: Vector3) -> void:
	_add_mesh_box("", pos + Vector3(0, 1.5, 0), Vector3(0.14, 3.0, 0.14), Color(0.22, 0.22, 0.24))
	var bulb := _add_mesh_box("", pos + Vector3(0, 3.15, 0.35), Vector3(0.5, 0.25, 0.5), Color(1.0, 0.88, 0.55))
	bulb.material_override = _make_mat(Color(1.0, 0.86, 0.48), 0.2, 1.4, true)


func _add_white_fence_line(origin: Vector3, length: float, rot_deg: float) -> void:
	var segments := int(length / 1.2)
	for i in segments:
		var offset := Vector3(0, 0, i * 1.2) if rot_deg == 0 else Vector3(i * 1.2, 0, 0)
		_add_mesh_box("", origin + offset + Vector3(0, 0.45, 0), Vector3(0.08, 0.9, 0.08), Color(0.92, 0.90, 0.84))
		if i < segments - 1:
			var rail_offset := offset + Vector3(0, 0.75, 0.6 if rot_deg == 0 else 0)
			if rot_deg != 0:
				rail_offset = offset + Vector3(0.6, 0.75, 0)
			_add_mesh_box("", origin + rail_offset, Vector3(1.15, 0.06, 0.06) if rot_deg == 0 else Vector3(0.06, 0.06, 1.15), Color(0.92, 0.90, 0.84))


func _add_flower_bed(pos: Vector3, width: float) -> void:
	_add_mesh_box("", pos + Vector3(0, 0.06, 0), Vector3(width, 0.12, 1.4), Color(0.36, 0.24, 0.16))
	for i in range(int(width)):
		var hue := 0.08 + randf() * 0.12
		_add_mesh_box("", pos + Vector3(-width * 0.5 + i + 0.5, 0.22, randf_range(-0.2, 0.2)), Vector3(0.18, 0.28, 0.18), Color.from_hsv(hue, 0.55, 0.75))


func _add_shrub_cluster(pos: Vector3) -> void:
	for i in range(4):
		var p := pos + Vector3(randf_range(-1.2, 1.2), 0, randf_range(-1.2, 1.2))
		_add_mesh_box("", p + Vector3(0, 0.35, 0), Vector3(0.9, 0.7, 0.9), Color(0.18, 0.40, 0.16))


func _add_maple_tree(pos: Vector3) -> void:
	_add_tree(pos, 1.35)


func _add_tree(pos: Vector3, scale: float = 1.0) -> void:
	var trunk := MeshInstance3D.new()
	var trunk_mesh := CylinderMesh.new()
	trunk_mesh.top_radius = 0.28 * scale
	trunk_mesh.bottom_radius = 0.42 * scale
	trunk_mesh.height = 3.2 * scale
	trunk.mesh = trunk_mesh
	trunk.position = pos + Vector3(0, 1.6 * scale, 0)
	trunk.material_override = _make_mat(Color(0.36, 0.24, 0.14))
	_props.add_child(trunk)

	for i in range(3):
		var foliage := MeshInstance3D.new()
		var sphere := SphereMesh.new()
		sphere.radius = (2.2 + i * 0.4) * scale
		sphere.height = (4.0 + i * 0.5) * scale
		foliage.mesh = sphere
		var offset := Vector3(randf_range(-0.8, 0.8), 0, randf_range(-0.8, 0.8)) * scale
		foliage.position = pos + Vector3(0, (4.2 + i * 0.6) * scale, 0) + offset
		var green := Color(0.18 + randf() * 0.06, 0.42 + randf() * 0.08, 0.14)
		foliage.material_override = _make_mat(green, 0.95)
		_props.add_child(foliage)


func _add_mesh_box(name: String, pos: Vector3, size: Vector3, color: Color) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	if name != "":
		mesh_instance.name = name
	var box := BoxMesh.new()
	box.size = size
	mesh_instance.mesh = box
	mesh_instance.position = pos
	mesh_instance.material_override = _make_mat(color)
	_props.add_child(mesh_instance)
	return mesh_instance


func _make_mat(color: Color, roughness: float = 0.9, emission_strength: float = 0.0, unshaded_glow: bool = false) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = roughness
	if emission_strength > 0.0:
		mat.emission_enabled = true
		mat.emission = color
		mat.emission_energy_multiplier = emission_strength
	if unshaded_glow:
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return mat


func _add_static_collisions() -> void:
	var static_body := StaticBody3D.new()
	static_body.name = "PropertyCollisions"
	_props.add_child(static_body)

	var shapes: Array = [
		[Vector3(14, 2.2, -2), Vector3(9, 4.4, 7)],
		[Vector3(18.5, 2.2, -2), Vector3(4.5, 3.2, 5.5)],
		[Vector3(10.5, 0.5, 8), Vector3(4.5, 1, 14)],
		[Vector3(18.5, 0.5, 12), Vector3(0.4, 1.2, 34)],
		[Vector3(18.5, 0.5, 29), Vector3(34, 1.2, 0.4)],
		[Vector3(11, 2.5, 20), Vector3(3, 5, 3)],
		[Vector3(-14, 2.2, -4), Vector3(9, 4.4, 7)],
		[Vector3(-14, 2.2, 10), Vector3(9, 4.4, 7)],
		[Vector3(-14, 2.2, 24), Vector3(9, 4.4, 7)],
		[Vector3(1.2, 0.6, -4), Vector3(2, 1.2, 4)],
	]

	for entry in shapes:
		var col := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = entry[1]
		col.shape = shape
		col.position = entry[0]
		static_body.add_child(col)


func _add_ground_collision() -> void:
	var ground_body := StaticBody3D.new()
	ground_body.name = "GroundBody"
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(80, 1, 80)
	shape.shape = box
	shape.position = Vector3(8, -0.5, 10)
	ground_body.add_child(shape)
	_props.add_child(ground_body)


func _start_ambience() -> void:
	if ambient_birds.stream:
		ambient_birds.volume_db = -14.0
		ambient_birds.play()
	if ambient_wind.stream:
		ambient_wind.volume_db = -20.0
		ambient_wind.play()
