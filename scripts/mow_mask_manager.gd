extends Node

signal progress_changed(ratio: float)
signal lawn_complete(stats: Dictionary)

@export var lawn_origin: Vector2 = GameSettings.LAWN_ORIGIN
@export var lawn_size: Vector2 = GameSettings.LAWN_SIZE
@export var mask_resolution: int = GameSettings.MASK_RESOLUTION
@export var grid_resolution: int = GameSettings.GRID_RESOLUTION

var mask_image: Image
var mask_texture: ImageTexture
var grid: PackedByteArray
var grid_cut_count: int = 0
var total_grid_cells: int = 0
var progress_ratio: float = 0.0
var is_complete: bool = false

var stripe_samples: Array[Vector2] = []
var stripe_sample_limit: int = 4096


func _ready() -> void:
	_init_mask()


func _init_mask() -> void:
	mask_image = Image.create(mask_resolution, mask_resolution, false, Image.FORMAT_RGBA8)
	mask_image.fill(Color(0, 0.5, 0.5, 1))
	mask_texture = ImageTexture.create_from_image(mask_image)

	total_grid_cells = grid_resolution * grid_resolution
	grid = PackedByteArray()
	grid.resize(total_grid_cells)
	grid.fill(0)
	grid_cut_count = 0


func get_mask_texture() -> ImageTexture:
	return mask_texture


func world_to_uv(world_xz: Vector2) -> Vector2:
	return (world_xz - lawn_origin) / lawn_size


func is_in_lawn(world_xz: Vector2) -> bool:
	var uv := world_to_uv(world_xz)
	return uv.x >= 0.0 and uv.x <= 1.0 and uv.y >= 0.0 and uv.y <= 1.0


func get_cut_amount_at(world_xz: Vector2) -> float:
	if not is_in_lawn(world_xz):
		return 1.0
	var uv := world_to_uv(world_xz)
	var px := Vector2i(
		clampi(int(uv.x * float(mask_resolution)), 0, mask_resolution - 1),
		clampi(int(uv.y * float(mask_resolution)), 0, mask_resolution - 1)
	)
	return mask_image.get_pixelv(px).r


func stamp_deck(world_xz: Vector2, facing: Vector2, radius: float, width: float) -> Dictionary:
	if not is_in_lawn(world_xz):
		return {"newly_cut": 0, "resistance": 1.0}

	var uv := world_to_uv(world_xz)
	var dir := facing.normalized()
	if dir.length_squared() < 0.001:
		dir = Vector2(0, -1)

	var px_center := Vector2i(
		int(uv.x * float(mask_resolution)),
		int(uv.y * float(mask_resolution))
	)
	var px_radius := int(radius / lawn_size.x * float(mask_resolution))
	var px_width := maxi(1, int(width / lawn_size.x * float(mask_resolution)))

	var dir_encoded := Vector2(dir.x * 0.5 + 0.5, dir.y * 0.5 + 0.5)
	var newly_cut := 0
	var resistance_sum := 0.0
	var resistance_count := 0

	for y in range(px_center.y - px_radius, px_center.y + px_radius + 1):
		if y < 0 or y >= mask_resolution:
			continue
		for x in range(px_center.x - px_radius, px_center.x + px_radius + 1):
			if x < 0 or x >= mask_resolution:
				continue
			var offset := Vector2(x - px_center.x, y - px_center.y)
			if offset.length() > float(px_radius):
				continue
			if absf(offset.dot(Vector2(-dir.y, dir.x))) > float(px_width):
				continue

			var pixel := Vector2i(x, y)
			var existing := mask_image.get_pixelv(pixel)
			resistance_sum += 1.0 - existing.r
			resistance_count += 1

			if existing.r < 0.95:
				newly_cut += 1
				mask_image.set_pixelv(pixel, Color(1.0, dir_encoded.x, dir_encoded.y, 1.0))
				_update_grid_from_pixel(pixel)

			if stripe_samples.size() < stripe_sample_limit:
				stripe_samples.append(dir)

	mask_texture.update(mask_image)
	_update_progress()

	var resistance := 1.0
	if resistance_count > 0:
		resistance = resistance_sum / float(resistance_count)

	return {"newly_cut": newly_cut, "resistance": resistance}


func _update_grid_from_pixel(pixel: Vector2i) -> void:
	var gx := clampi(pixel.x * grid_resolution / mask_resolution, 0, grid_resolution - 1)
	var gy := clampi(pixel.y * grid_resolution / mask_resolution, 0, grid_resolution - 1)
	var idx := gy * grid_resolution + gx
	if grid[idx] == 0:
		grid[idx] = 1
		grid_cut_count += 1


func _update_progress() -> void:
	if total_grid_cells == 0:
		return
	progress_ratio = float(grid_cut_count) / float(total_grid_cells)
	progress_changed.emit(progress_ratio)
	if not is_complete and progress_ratio >= GameSettings.MOW_COMPLETE_THRESHOLD:
		is_complete = true
		lawn_complete.emit(get_stats())


func get_stats() -> Dictionary:
	var missed_cells := total_grid_cells - grid_cut_count
	var stripe_quality := _calculate_stripe_quality()
	var accuracy := progress_ratio * 100.0
	var rating := _calculate_rating(accuracy, stripe_quality, missed_cells)
	return {
		"accuracy": accuracy,
		"stripe_quality": stripe_quality,
		"missed_grass": missed_cells,
		"missed_percent": (float(missed_cells) / float(total_grid_cells)) * 100.0,
		"rating": rating,
		"money": GameSettings.PLACEHOLDER_PAY,
	}


func _calculate_stripe_quality() -> float:
	if stripe_samples.is_empty():
		return 50.0
	var avg := Vector2.ZERO
	for dir in stripe_samples:
		avg += dir
	avg /= float(stripe_samples.size())
	var consistency := 0.0
	for dir in stripe_samples:
		consistency += clampf(dir.dot(avg.normalized()), 0.0, 1.0)
	consistency /= float(stripe_samples.size())
	return clampf(consistency * 100.0, 0.0, 100.0)


func _calculate_rating(accuracy: float, stripe_quality: float, missed_cells: int) -> String:
	var score := accuracy * 0.55 + stripe_quality * 0.35 - float(missed_cells) * 0.02
	if score >= 92.0:
		return "A"
	if score >= 82.0:
		return "B"
	if score >= 70.0:
		return "C"
	return "D"


func reset_mask() -> void:
	_init_mask()
	progress_ratio = 0.0
	is_complete = false
	stripe_samples.clear()
	progress_changed.emit(0.0)
