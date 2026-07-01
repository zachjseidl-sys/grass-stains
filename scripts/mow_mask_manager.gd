extends Node

signal progress_changed(ratio: float)
signal streak_changed(streak: int, multiplier: float)
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
var current_streak: int = 0
var best_streak: int = 0
var last_stamp_had_cut: bool = false
var wasted_passes: int = 0
var total_newly_cut_pixels: int = 0


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
	var touched_pixels := 0
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
			touched_pixels += 1

			if existing.r < 0.95:
				newly_cut += 1
				mask_image.set_pixelv(pixel, Color(1.0, dir_encoded.x, dir_encoded.y, 1.0))
				_update_grid_from_pixel(pixel)

			if stripe_samples.size() < stripe_sample_limit:
				stripe_samples.append(dir)

	_update_streak(newly_cut, touched_pixels)
	total_newly_cut_pixels += newly_cut
	mask_texture.update(mask_image)
	_update_progress()

	var resistance := 1.0
	if resistance_count > 0:
		resistance = resistance_sum / float(resistance_count)

	return {"newly_cut": newly_cut, "resistance": resistance, "streak": current_streak, "multiplier": get_combo_multiplier()}


func _update_streak(newly_cut: int, touched_pixels: int) -> void:
	if newly_cut > 0:
		current_streak += newly_cut
		best_streak = maxi(best_streak, current_streak)
		last_stamp_had_cut = true
	elif touched_pixels > 0 and last_stamp_had_cut:
		wasted_passes += 1
		current_streak = 0
		last_stamp_had_cut = false
	streak_changed.emit(current_streak, get_combo_multiplier())


func get_combo_multiplier() -> float:
	if current_streak >= 1600:
		return 1.5
	if current_streak >= 900:
		return 1.35
	if current_streak >= 400:
		return 1.2
	return 1.0


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
	var job_threshold := float(GameSettings.get_current_job().get("threshold", GameSettings.MOW_COMPLETE_THRESHOLD))
	if not is_complete and progress_ratio >= job_threshold:
		is_complete = true
		lawn_complete.emit(get_stats())


func get_stats() -> Dictionary:
	var missed_cells := total_grid_cells - grid_cut_count
	var stripe_quality := _calculate_stripe_quality()
	var accuracy := progress_ratio * 100.0
	var rating := _calculate_rating(accuracy, stripe_quality, missed_cells)
	var job := GameSettings.get_current_job()
	var efficiency := _calculate_efficiency()
	var multiplier := maxf(get_combo_multiplier(), 1.0)
	var money := int(round(float(job.get("base_pay", GameSettings.PLACEHOLDER_PAY)) * (0.65 + accuracy / 200.0) + float(job.get("tip", 0)) * stripe_quality / 100.0 * multiplier))
	var reputation := int(clampf((accuracy - 85.0) / 5.0, 1.0, 5.0))
	return {
		"accuracy": accuracy,
		"stripe_quality": stripe_quality,
		"missed_grass": missed_cells,
		"missed_percent": (float(missed_cells) / float(total_grid_cells)) * 100.0,
		"rating": rating,
		"money": money,
		"reputation": reputation,
		"best_streak": best_streak,
		"wasted_passes": wasted_passes,
		"efficiency": efficiency,
		"job_name": job.get("name", "Next Job"),
		"client": job.get("client", "Client"),
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


func _calculate_efficiency() -> float:
	var denominator := maxf(float(total_newly_cut_pixels + wasted_passes * 64), 1.0)
	return clampf(float(total_newly_cut_pixels) / denominator * 100.0, 0.0, 100.0)


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
	current_streak = 0
	best_streak = 0
	wasted_passes = 0
	total_newly_cut_pixels = 0
	progress_changed.emit(0.0)
	streak_changed.emit(0, 1.0)
