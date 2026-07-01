extends Node

## Shared constants for the Grass Stains vertical slice.

# Mowable corner lot east of Maple Lane
const LAWN_ORIGIN := Vector2(5.0, -8.0)
const LAWN_SIZE := Vector2(26.0, 42.0)

const STREET_X_MIN := -3.5
const STREET_X_MAX := 3.5
const STREET_Z_MIN := -18.0
const STREET_Z_MAX := 38.0

const MASK_RESOLUTION := 512
const GRID_RESOLUTION := 128

const MOW_COMPLETE_THRESHOLD := 0.985
const GRASS_RESISTANCE := 0.72

const MAX_SPEED := 4.15
const ACCEL := 6.3
const DECEL := 8.4
const TURN_RATE := 1.55
const TURN_RATE_FAST := 0.48

const DECK_RADIUS := 0.62
const DECK_WIDTH := 0.54

const TALL_GRASS_COLOR := Color(0.26, 0.50, 0.17)
const CUT_GRASS_COLOR := Color(0.40, 0.66, 0.26)
const STRIPE_TINT := Color(0.34, 0.56, 0.21)

const JOBS := [
	{
		"name": "Mrs. Finch's Front Yard",
		"client": "Mrs. Finch",
		"tier": "Summer Side Hustle",
		"base_pay": 14,
		"tip": 6,
		"target_time": 185.0,
		"threshold": 0.965,
		"brief": "First paid mow. Keep the rows tidy and don't scalp the flower beds.",
	},
	{
		"name": "Maple Lane Double Lot",
		"client": "The Garcias",
		"tier": "Neighborhood Regular",
		"base_pay": 28,
		"tip": 12,
		"target_time": 260.0,
		"threshold": 0.975,
		"brief": "A bigger yard with bonus cash for clean stripes and a fast finish.",
	},
	{
		"name": "Pine Hollow Ball Field",
		"client": "Coach Riley",
		"tier": "Little League Contract",
		"base_pay": 65,
		"tip": 25,
		"target_time": 360.0,
		"threshold": 0.985,
		"brief": "The infield crowd notices every missed patch. Make it look game-day ready.",
	},
	{
		"name": "Rolling Hills Golf Course",
		"client": "Groundskeeper Dale",
		"tier": "Lawn Care Mogul",
		"base_pay": 140,
		"tip": 60,
		"target_time": 520.0,
		"threshold": 0.992,
		"brief": "Premium turf, premium expectations. Chase perfect coverage and pro stripes.",
	},
]

const STARTING_CASH := 0
const PLACEHOLDER_PAY := 14

var cash: int = STARTING_CASH
var reputation: int = 0
var current_job_index: int = 0
var best_rating: String = "--"
const SAVE_PATH := "user://grass_stains_career.save"


func _ready() -> void:
	load_career()


func get_current_job() -> Dictionary:
	return JOBS[current_job_index % JOBS.size()]


func get_next_job_name() -> String:
	return JOBS[(current_job_index + 1) % JOBS.size()].get("name", "Next Job")


func complete_job(stats: Dictionary) -> Dictionary:
	var job := get_current_job()
	var payout := int(stats.get("money", job.get("base_pay", PLACEHOLDER_PAY)))
	cash += payout
	reputation += int(stats.get("reputation", 1))
	best_rating = str(stats.get("rating", best_rating))
	current_job_index = (current_job_index + 1) % JOBS.size()
	save_career()
	return {
		"cash": cash,
		"reputation": reputation,
		"next_job": get_current_job().get("name", "Next Job"),
		"next_tier": get_current_job().get("tier", "Side Hustle"),
	}


func save_career() -> void:
	var save := ConfigFile.new()
	save.set_value("career", "cash", cash)
	save.set_value("career", "reputation", reputation)
	save.set_value("career", "current_job_index", current_job_index)
	save.set_value("career", "best_rating", best_rating)
	save.save(SAVE_PATH)


func load_career() -> void:
	var save := ConfigFile.new()
	if save.load(SAVE_PATH) != OK:
		return
	cash = int(save.get_value("career", "cash", STARTING_CASH))
	reputation = int(save.get_value("career", "reputation", 0))
	current_job_index = int(save.get_value("career", "current_job_index", 0)) % JOBS.size()
	best_rating = str(save.get_value("career", "best_rating", "--"))
