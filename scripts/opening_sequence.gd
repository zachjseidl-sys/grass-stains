extends CanvasLayer

@onready var fade_rect: ColorRect = $Fade
@onready var title_label: Label = $TitleLabel
@onready var subtitle_label: Label = $SubtitleLabel

var sequence_running: bool = true


func _ready() -> void:
	fade_rect.color = Color(0.05, 0.04, 0.03, 1.0)
	title_label.modulate.a = 0.0
	subtitle_label.modulate.a = 0.0
	_run_opening()


func _run_opening() -> void:
	var tween := create_tween()
	tween.tween_property(fade_rect, "color:a", 0.0, 2.5).set_delay(0.5)
	tween.parallel().tween_property(title_label, "modulate:a", 1.0, 1.5).set_delay(0.8)
	tween.parallel().tween_property(subtitle_label, "modulate:a", 1.0, 1.5).set_delay(2.2)
	await tween.finished
	await get_tree().create_timer(2.5).timeout
	var fade_out := create_tween()
	fade_out.tween_property(title_label, "modulate:a", 0.0, 1.0)
	fade_out.parallel().tween_property(subtitle_label, "modulate:a", 0.0, 1.0)
	await fade_out.finished
	sequence_running = false
	visible = false
