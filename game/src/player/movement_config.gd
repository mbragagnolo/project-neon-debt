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
@export var run_speed: float = 150.0
## px/s². How fast we reach `run_speed` on the ground.
@export var ground_acceleration: float = 1200.0
## px/s². How fast we stop on the ground when input is released.
@export var ground_deceleration: float = 1600.0
@export var air_acceleration: float = 900.0
@export var air_deceleration: float = 600.0

@export_group("Jump")
## Peak height of a full-hold jump, px.
@export var jump_height: float = 56.0
## Seconds from leaving the ground to the top of a full-hold jump.
@export var jump_time_to_apex: float = 0.36
## Falling uses heavier gravity than rising — the single biggest "feels good"
## knob in a platformer. 1.0 = symmetric arc.
@export var fall_gravity_multiplier: float = 1.6
## Upward velocity is multiplied by this when jump is released early
## (variable jump height).
@export var jump_cut_multiplier: float = 0.45
## Terminal velocity, px/s.
@export var max_fall_speed: float = 400.0
## Grace period after walking off a ledge where jump still works, seconds.
@export var coyote_time: float = 0.1
## A jump pressed this long before landing still fires on touchdown, seconds.
@export var jump_buffer_time: float = 0.15

@export_group("Dash")
## Distance covered by one dash, px.
@export var dash_distance: float = 96.0
@export var dash_duration: float = 0.16
@export var dash_cooldown: float = 0.5
## Undecided by design — flip it on in playtest and see (DESIGN.md §3.1).
@export var dash_grants_iframes: bool = false
@export var dash_iframe_time: float = 0.12

@export_group("Wall")
## Capped downward speed while sliding on a wall, px/s.
@export var wall_slide_speed: float = 40.0
## Horizontal kick away from the wall on a wall jump, px/s.
@export var wall_jump_push: float = 140.0
## Height of a wall jump, px (fed through the same gravity as a normal jump).
@export var wall_jump_height: float = 48.0
## Seconds the player keeps clinging after pushing away from the wall, so a
## turn-and-jump input doesn't drop them.
@export var wall_stick_time: float = 0.1


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


## Constant horizontal speed held for `dash_duration`, px/s.
func dash_speed() -> float:
	if is_zero_approx(dash_duration):
		return 0.0
	return dash_distance / dash_duration
