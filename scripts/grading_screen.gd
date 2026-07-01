extends CanvasLayer

@onready var panel: PanelContainer = $Panel
@onready var accuracy_label: Label = $Panel/Margin/VBox/Accuracy
@onready var stripe_label: Label = $Panel/Margin/VBox/Stripe
@onready var missed_label: Label = $Panel/Margin/VBox/Missed
@onready var time_label: Label = $Panel/Margin/VBox/Time
@onready var rating_label: Label = $Panel/Margin/VBox/Rating
@onready var money_label: Label = $Panel/Margin/VBox/Money
@onready var efficiency_label: Label = $Panel/Margin/VBox/Efficiency
@onready var career_label: Label = $Panel/Margin/VBox/Career
@onready var next_label: Label = $Panel/Margin/VBox/Next
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
	accuracy_label.text = "%s for %s\nCut Accuracy: %.0f%%" % [stats.get("job_name", "Job Complete"), stats.get("client", "the client"), stats.get("accuracy", 0.0)]
	stripe_label.text = "Stripe Quality: %.0f%%" % stats.get("stripe_quality", 0.0)
	var missed: int = stats.get("missed_grass", 0)
	if missed <= 0:
		missed_label.text = "Missed Grass: None — perfect lawn!"
	else:
		missed_label.text = "Missed Grass: %.0f%% still standing" % stats.get("missed_percent", 0.0)
	time_label.text = "Time: %s" % _format_time(elapsed_seconds)
	rating_label.text = "Overall Rating: %s" % stats.get("rating", "C")
	money_label.text = "Earned: $%d  +%d rep" % [stats.get("money", GameSettings.PLACEHOLDER_PAY), stats.get("reputation", 1)]
	efficiency_label.text = "Efficiency: %.0f%%  •  Best streak: %d  •  Wasted passes: %d" % [stats.get("efficiency", 0.0), stats.get("best_streak", 0), stats.get("wasted_passes", 0)]
	var career: Dictionary = stats.get("career", {})
	career_label.text = "Lawn-care empire: $%d banked  •  Rep %d" % [career.get("cash", GameSettings.cash), career.get("reputation", GameSettings.reputation)]
	next_label.text = "Next contract: %s (%s)" % [career.get("next_job", GameSettings.get_current_job().get("name", "Next Job")), career.get("next_tier", GameSettings.get_current_job().get("tier", "Side Hustle"))]
	visible = true


func _format_time(seconds: float) -> String:
	var total := int(seconds)
	var minutes := total / 60
	var secs := total % 60
	return "%d:%02d" % [minutes, secs]


func _on_replay_pressed() -> void:
	get_tree().reload_current_scene()
