class_name MovementConfig
extends Resource
## Every number the player controller reads (DESIGN.md §3.1).
##
## The controller owns no magic numbers: it asks this resource. Tuning the feel
## therefore means editing `movement_config.tres` in the inspector while the
## game runs, not editing code — which is the whole point of M1.
##
## Jump is authored in *shape*, not in physics units: you say how high the jump
## goes and how long it takes to get there, and gravity falls out of that. Ask
## a designer for "3.5 tiles high, snappy" and you can type it in directly.

@export_group("Run")
## Top horizontal speed, px/s.
@export var run_speed: float = 450.0
## px/s². How fast we reach `run_speed` on the ground.
@export var ground_acceleration: float = 3600.0
## px/s². How fast we stop on the ground when input is released.
@export var ground_deceleration: float = 4800.0
@export var air_acceleration: float = 2700.0
@export var air_deceleration: float = 1800.0
## px/s² applied when input opposes current travel. DESIGN.md §3.1 asks for
## "instant turn"; keeping it a (steep) acceleration rather than a hard snap to
## zero means a turn still reads as a turn. Raise it to make reversals crisper.
@export var turn_acceleration: float = 9000.0

@export_group("Jump")
## Peak height of a full-hold jump, px.
@export var jump_height: float = 168.0
## Seconds from leaving the ground to the top of a full-hold jump.
@export var jump_time_to_apex: float = 0.36
## Falling uses heavier gravity than rising — the single biggest "feels good"
## knob in a platformer. 1.0 = symmetric arc.
@export var fall_gravity_multiplier: float = 1.6
## Upward velocity is multiplied by this when jump is released early
## (variable jump height).
@export var jump_cut_multiplier: float = 0.45
## Terminal velocity, px/s.
@export var max_fall_speed: float = 1200.0
## Grace period after walking off a ledge where jump still works, seconds.
@export var coyote_time: float = 0.1
## A jump pressed this long before landing still fires on touchdown, seconds.
@export var jump_buffer_time: float = 0.15

@export_group("Dash")
## Distance covered by one dash, px.
@export var dash_distance: float = 288.0
@export var dash_duration: float = 0.16
@export var dash_cooldown: float = 0.5
## Undecided by design — flip it on in playtest and see (DESIGN.md §3.1).
@export var dash_grants_iframes: bool = false
@export var dash_iframe_time: float = 0.12
## One air dash per airborne period, refunded on landing. Off makes dash a
## purely grounded verb. This changes how far a horizontal gap can be, so it
## interacts with M5's level design — decide it before the district is laid out.
@export var can_dash_in_air: bool = true

@export_group("Wall")
## Capped downward speed while sliding on a wall, px/s.
@export var wall_slide_speed: float = 120.0
## Horizontal kick away from the wall on a wall jump, px/s.
@export var wall_jump_push: float = 420.0
## Height of a wall jump, px (fed through the same gravity as a normal jump).
@export var wall_jump_height: float = 144.0
## Seconds the player keeps clinging after pushing away from the wall, so a
## turn-and-jump input doesn't drop them.
@export var wall_stick_time: float = 0.1
## Seconds after a wall jump during which horizontal input is ignored, so the
## kick away from the wall actually lands instead of being cancelled by the
## stick the player is already holding toward it.
@export var wall_jump_lockout_time: float = 0.12
## How much of a wall jump's whole flight (rise and fall back to the take-off
## height) the *same* wall refuses the player for. At 1.0 a re-stick always
## lands below the point of departure and a single wall is unclimbable; below
## it the wall is accepted while the player is still above the departure
## point, and a single wall becomes a slow ladder for a player who re-sticks
## and kicks on time (decided 2026-09-15: a player who climbs a tease ledge
## that way has earned it). The gain per kick is the height still held when
## the lockout ends; test_movement_envelope.gd measures the rate.
@export var same_wall_lockout_scale: float = 0.85
## Extra seconds on top of the scaled flight, the margin.
@export var same_wall_lockout_margin: float = 0.05


## Downward acceleration while rising, px/s². Derived from the jump shape.
func rise_gravity() -> float:
	if is_zero_approx(jump_time_to_apex):
		return 0.0
	return (2.0 * jump_height) / (jump_time_to_apex * jump_time_to_apex)


## Downward acceleration while falling, px/s².
func fall_gravity() -> float:
	return rise_gravity() * fall_gravity_multiplier


## Initial upward velocity of a jump, px/s (negative: Godot's Y points down).
func jump_velocity() -> float:
	if is_zero_approx(jump_time_to_apex):
		return 0.0
	return -(2.0 * jump_height) / jump_time_to_apex


## Initial upward velocity of a wall jump, px/s.
func wall_jump_velocity() -> float:
	var g := rise_gravity()
	if g <= 0.0:
		return 0.0
	return -sqrt(2.0 * g * wall_jump_height)


## The seconds a wall jump spends rising and falling back to its take-off
## height, scaled by `same_wall_lockout_scale`, plus the margin. The same wall
## is refused for this long.
func same_wall_lockout_time() -> float:
	var rise_g: float = rise_gravity()
	if rise_g <= 0.0:
		return same_wall_lockout_margin
	var rise: float = sqrt(2.0 * wall_jump_height / rise_g)
	var fall: float = sqrt(2.0 * wall_jump_height / fall_gravity())
	return (rise + fall) * same_wall_lockout_scale + same_wall_lockout_margin


## Constant horizontal speed held for `dash_duration`, px/s.
func dash_speed() -> float:
	if is_zero_approx(dash_duration):
		return 0.0
	return dash_distance / dash_duration
