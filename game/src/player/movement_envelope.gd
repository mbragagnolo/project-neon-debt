class_name MovementEnvelope
extends RefCounted
## How far the player can reach, derived from `MovementConfig` rather than
## hand-guessed (DESIGN.md §3.4, movement envelope rule).
##
## Level design never types a gap width. It asks this for the reach of the
## kit available at that point in the district, and every gate gets a test
## asserting it sits ≥15% beyond that reach — so retuning movement re-validates
## every gate for free, and a gap that quietly became crossable fails a build
## instead of a playtest.
##
## Everything is analytic. The controller integrates gravity per physics step,
## so real flights overshoot these by a few pixels; the 15% margin is what
## absorbs that, and `tests/test_movement_envelope.gd` checks the analysis
## against real physics so the two cannot drift apart.

## The margin every gate must clear, both ways: a gate is unreachable by the
## kit before it by at least this factor, and reachable by the kit after it
## by at least this factor.
const GATE_MARGIN := 1.15

var config: MovementConfig


func _init(movement_config: MovementConfig) -> void:
	config = movement_config


static func from_project() -> MovementEnvelope:
	return MovementEnvelope.new(load("res://src/player/movement_config.tres"))


# --- Time in the air ----------------------------------------------------------

## Seconds from take-off to the apex of a full-hold jump.
func rise_time() -> float:
	return config.jump_time_to_apex


## Seconds from the apex back down to take-off height. Falling gravity is
## heavier than rising gravity, so this is shorter than the rise.
func fall_time() -> float:
	var g: float = config.fall_gravity()
	if g <= 0.0:
		return 0.0
	return sqrt(2.0 * config.jump_height / g)


## Seconds a full jump spends in the air, landing at take-off height.
func flight_time() -> float:
	return rise_time() + fall_time()


# --- Reach --------------------------------------------------------------------

## Peak height of a full jump, px. A ledge higher than this with no facing
## wall is unreachable by the whole V1 kit — a double-jump tease.
func jump_height() -> float:
	return config.jump_height


## Horizontal distance a running full jump carries, px, landing level.
func flat_jump_distance() -> float:
	return config.run_speed * flight_time()


## A ground dash, px. Altitude is held, so this is also a gap it crosses.
func dash_distance() -> float:
	return config.dash_distance


## Ground dash into a buffered jump, measured from where the dash starts.
## The starting kit's longest ground move — but it is *not* a gap reach: a
## dash spends itself before the edge, and a dash that runs off the edge gets
## no jump at its end (`Player.end_dash`).
func dash_jump_distance() -> float:
	return dash_distance() + flat_jump_distance()


## Run-jump into an air dash (the Sidewinder), edge to edge. The air dash
## suspends gravity for `dash_duration`, so it *adds* its distance to the
## flight rather than replacing part of it.
func jump_air_dash_distance() -> float:
	return flat_jump_distance() + dash_distance()


## The widest level gap crossable *from its edge* with a given kit. Without
## the implant the answer is a running jump: a dash off the edge covers less
## and forfeits the jump, and a dash before the edge spends itself on solid
## ground.
func max_gap(has_air_dash: bool) -> float:
	if has_air_dash:
		return jump_air_dash_distance()
	return maxf(flat_jump_distance(), dash_distance())


## Height gained per wall jump, px. A shaft is climbable post-Hook if its
## walls face each other within `wall_jump_reach()`.
func wall_jump_height() -> float:
	return config.wall_jump_height


## How far a wall jump carries horizontally before it starts falling below
## take-off height — the widest shaft the Mag-Hook climbs. Rise at the kick
## speed, then the fall, with the player steering back toward the far wall
## at run speed once the lockout ends.
func wall_jump_reach() -> float:
	var g: float = config.rise_gravity()
	if g <= 0.0:
		return 0.0
	var rise: float = sqrt(2.0 * config.wall_jump_height / g)
	var fall: float = sqrt(2.0 * config.wall_jump_height / config.fall_gravity())
	return config.wall_jump_push * config.wall_jump_lockout_time + config.run_speed * (rise + fall - config.wall_jump_lockout_time)


# --- Gate checks --------------------------------------------------------------

## A Sidewinder gate: a level gap the starting kit cannot cross and the
## implant can, each by the margin.
func is_valid_air_dash_gate(gap: float) -> bool:
	return gap >= max_gap(false) * GATE_MARGIN and gap * GATE_MARGIN <= max_gap(true)


## A double-jump tease: a single-wall ledge higher than a jump by the margin.
## No V1 ability adds height without a facing wall, so this is unreachable
## for the whole slice.
func is_valid_tease_height(height: float) -> bool:
	return height >= jump_height() * GATE_MARGIN


## A Mag-Hook shaft: two facing walls close enough to bounce between.
func is_climbable_shaft(width: float) -> bool:
	return width * GATE_MARGIN <= wall_jump_reach()
