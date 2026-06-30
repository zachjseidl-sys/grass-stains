extends Node

## Shared constants for the Grass Stains vertical slice.

const LAWN_ORIGIN := Vector2(-14.0, -6.0)
const LAWN_SIZE := Vector2(28.0, 32.0)

const MASK_RESOLUTION := 512
const GRID_RESOLUTION := 128

const MOW_COMPLETE_THRESHOLD := 0.99
const GRASS_RESISTANCE := 0.72

const MAX_SPEED := 3.6
const ACCEL := 5.5
const DECEL := 7.0
const TURN_RATE := 1.35
const TURN_RATE_FAST := 0.42

const DECK_RADIUS := 0.55
const DECK_WIDTH := 0.48

const TALL_GRASS_COLOR := Color(0.28, 0.52, 0.18)
const CUT_GRASS_COLOR := Color(0.42, 0.68, 0.28)
const STRIPE_TINT := Color(0.36, 0.58, 0.22)

const PLACEHOLDER_PAY := 12
