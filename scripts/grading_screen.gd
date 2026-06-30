extends CanvasLayer

@onready var panel: PanelContainer = $Panel
@onready var accuracy_label: Label = $Panel/Margin/VBox/Accuracy
@onready var stripe_label: Label = $Panel/Margin/VBox/Stripe
@onready var missed_label: Label = $Panel/Margin/VBox/Missed
@onready var time_label: Label = $Panel/Margin/VBox/Time
@onready var rating_label: Label = $Panel/Margin/VBox/Rating
@onready var money_label: Label = $Panel/Margin/VBox/Money
@onready var replay_button: Button = $Panel/Margin/VBox/ReplayButton

var elapsed_seconds: float = 0.0
var timer_running: bool = false


func _ready() -> void:
	visible = false
	replay_button.pressed.connect(_on_replay_pressed)


func _process(delta: float) -> void:
	if timer_running:
		elapsed_seconds += delta


func start_timer() -> void:
	if not timer_running:
		timer_running = true
		elapsed_seconds = 0.0


func show_results(stats: Dictionary) -> void:
	timer_running = false
	accuracy_label.text = "Cut Accuracy: %.0f%%" % stats.get("accuracy", 0.0)
	stripe_label.text = "Stripe Quality: %.0f%%" % stats.get("stripe_quality", 0.0)
	var missed: int = stats.get("missed_grass", 0)
	if missed <= 0:
		missed_label.text = "Missed Grass: None — perfect lawn!"
	else:
		missed_label.text = "Missed Grass: %.0f%% still standing" % stats.get("missed_percent", 0.0)
	time_label.text = "Time: %s" % _format_time(elapsed_seconds)
	rating_label.text = "Overall Rating: %s" % stats.get("rating", "C")
	money_label.text = "Earned: $%d" % stats.get("money", GameSettings.PLACEHOLDER_PAY)
	visible = true


func _format_time(seconds: float) -> String:
	var total := int(seconds)
	var minutes := total / 60
	var secs := total % 60
	return "%d:%02d" % [minutes, secs]


func _on_replay_pressed() -> void:
	get_tree().reload_current_scene()
