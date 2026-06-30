extends Node3D

@onready var ground_mesh: MeshInstance3D = $Ground
@onready var ambient_birds: AudioStreamPlayer = $AmbientBirds
@onready var ambient_wind: AudioStreamPlayer = $AmbientWind

var mask_manager: Node = null


func _ready() -> void:
	_build_ground()
	_build_property()
	_start_ambience()


func setup(mask: Node) -> void:
	mask_manager = mask
	if mask_manager:
		var tex: Texture2D = mask_manager.get_mask_texture()
		var mat: ShaderMaterial = ground_mesh.material_override as ShaderMaterial
		if mat:
			mat.set_shader_parameter("mow_mask", tex)


func update_mask_texture(tex: Texture2D) -> void:
	var mat: ShaderMaterial = ground_mesh.material_override as ShaderMaterial
	if mat:
		mat.set_shader_parameter("mow_mask", tex)


func _build_ground() -> void:
	var plane := PlaneMesh.new()
	plane.size = Vector2(60, 60)
	ground_mesh.mesh = plane
	ground_mesh.position = Vector3(0, -0.02, 13)

	var shader := load("res://shaders/ground.gdshader") as Shader
	var mat := ShaderMaterial.new()
	mat.shader = shader
	mat.set_shader_parameter("lawn_origin", GameSettings.LAWN_ORIGIN)
	mat.set_shader_parameter("lawn_size", GameSettings.LAWN_SIZE)
	ground_mesh.material_override = mat


func _build_property() -> void:
	_add_mesh_box("Driveway", Vector3(16, 0.03, 13), Vector3(6, 0.06, 18), Color(0.55, 0.53, 0.5))
	_add_mesh_box("House", Vector3(-2, 2.5, -14), Vector3(16, 5, 10), Color(0.78, 0.68, 0.52))
	_add_mesh_box("Roof", Vector3(-2, 5.8, -14), Vector3(17, 0.6, 11), Color(0.45, 0.28, 0.22))
	_add_mesh_box("Garage", Vector3(10, 1.8, -12), Vector3(6, 3.6, 6), Color(0.72, 0.62, 0.48))
	_add_mesh_box("FenceBack", Vector3(0, 1.0, 28), Vector3(34, 2, 0.25), Color(0.52, 0.38, 0.24))
	_add_mesh_box("FenceLeft", Vector3(-17, 1.0, 13), Vector3(0.25, 2, 34), Color(0.52, 0.38, 0.24))
	_add_mesh_box("FenceRight", Vector3(17, 1.0, 13), Vector3(0.25, 2, 34), Color(0.52, 0.38, 0.24))
	_add_mesh_box("MailboxPost", Vector3(-15.5, 0.6, 22), Vector3(0.15, 1.2, 0.15), Color(0.3, 0.28, 0.26))
	_add_mesh_box("Mailbox", Vector3(-15.5, 1.2, 22), Vector3(0.5, 0.35, 0.7), Color(0.2, 0.35, 0.55))
	_add_mesh_box("FlowerBedLeft", Vector3(-12, 0.08, 24), Vector3(4, 0.16, 2), Color(0.42, 0.28, 0.18))
	_add_mesh_box("FlowerBedRight", Vector3(8, 0.08, 26), Vector3(5, 0.16, 2.5), Color(0.42, 0.28, 0.18))
	_add_tree(Vector3(-10, 0, 18))
	_add_static_collisions()
	_add_ground_collision()


func _add_mesh_box(name: String, pos: Vector3, size: Vector3, color: Color) -> void:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = name
	var box := BoxMesh.new()
	box.size = size
	mesh_instance.mesh = box
	mesh_instance.position = pos
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.92
	mesh_instance.material_override = mat
	add_child(mesh_instance)


func _add_tree(pos: Vector3) -> void:
	var trunk := MeshInstance3D.new()
	trunk.name = "MapleTrunk"
	var trunk_mesh := CylinderMesh.new()
	trunk_mesh.top_radius = 0.35
	trunk_mesh.bottom_radius = 0.5
	trunk_mesh.height = 3.5
	trunk.mesh = trunk_mesh
	trunk.position = pos + Vector3(0, 1.75, 0)
	var trunk_mat := StandardMaterial3D.new()
	trunk_mat.albedo_color = Color(0.38, 0.26, 0.16)
	trunk.material_override = trunk_mat
	add_child(trunk)

	var foliage := MeshInstance3D.new()
	foliage.name = "MapleFoliage"
	var sphere := SphereMesh.new()
	sphere.radius = 3.2
	sphere.height = 5.5
	foliage.mesh = sphere
	foliage.position = pos + Vector3(0, 5.5, 0)
	var leaf_mat := StandardMaterial3D.new()
	leaf_mat.albedo_color = Color(0.22, 0.48, 0.18)
	leaf_mat.roughness = 0.95
	foliage.material_override = leaf_mat
	add_child(foliage)


func _add_static_collisions() -> void:
	var static_body := StaticBody3D.new()
	static_body.name = "PropertyCollisions"
	add_child(static_body)

	var shapes := [
		[Vector3(16, 0.5, 13), Vector3(6, 1, 18)],
		[Vector3(-2, 2.5, -14), Vector3(16, 5, 10)],
		[Vector3(10, 1.8, -12), Vector3(6, 3.6, 6)],
		[Vector3(0, 1.0, 28), Vector3(34, 2, 0.25)],
		[Vector3(-17, 1.0, 13), Vector3(0.25, 2, 34)],
		[Vector3(17, 1.0, 13), Vector3(0.25, 2, 34)],
		[Vector3(-10, 2.5, 18), Vector3(2.5, 5, 2.5)],
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
	box.size = Vector3(50, 1, 50)
	shape.shape = box
	shape.position = Vector3(0, -0.5, 13)
	ground_body.add_child(shape)
	add_child(ground_body)


func _start_ambience() -> void:
	if ambient_birds.stream:
		ambient_birds.volume_db = -16.0
		ambient_birds.play()
	if ambient_wind.stream:
		ambient_wind.volume_db = -22.0
		ambient_wind.play()
