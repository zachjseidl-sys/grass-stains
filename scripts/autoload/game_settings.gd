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

const MOW_COMPLETE_THRESHOLD := 0.99
const GRASS_RESISTANCE := 0.72

const MAX_SPEED := 3.8
const ACCEL := 5.8
const DECEL := 7.2
const TURN_RATE := 1.4
const TURN_RATE_FAST := 0.44

const DECK_RADIUS := 0.58
const DECK_WIDTH := 0.5

const TALL_GRASS_COLOR := Color(0.26, 0.50, 0.17)
const CUT_GRASS_COLOR := Color(0.40, 0.66, 0.26)
const STRIPE_TINT := Color(0.34, 0.56, 0.21)

const PLACEHOLDER_PAY := 12
