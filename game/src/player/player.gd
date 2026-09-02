class_name Player
extends CharacterBody2D
## The player controller (DESIGN.md §3.1 / M1).
##
## This node owns the *physics*: velocity, gravity, the feel timers (coyote,
## jump buffer, dash cooldown, wall-jump lockout) and the helpers that act on
## them. The state machine under it owns the *decisions* — which of those
## helpers runs this frame. Keeping the split means a new state (M2's attacks,
## M4's hacks) is one new file, not a rewrite of this one.
##
## Not one movement constant lives here. Every number comes from `config`, so
## tuning the feel is an inspector session while the game runs.

## Facing is a separate concept from velocity: you keep facing the way you are
## travelling even while decelerating, and attacks (M2) fire the way you face.
enum Facing { LEFT = -1, RIGHT = 1 }

@export var config: MovementConfig

@onready var _state_machine: PlayerStateMachine = $StateMachine
@onready var _visual: Node2D = $Visual
@onready var camera: Camera2D = $Camera2D

## +1 right, -1 left.
var facing: int = Facing.RIGHT
## -1, 0 or +1 from the move_left/move_right actions this frame.
var input_direction: int = 0
## Edge-triggered input, sampled once per frame in `_read_input`. States read
## these rather than polling `Input` themselves: one sample point per frame
## means two states can never disagree about whether a button was tapped, and
## the answer cannot change depending on how deep into the frame it is asked.
var _dash_pressed: bool = false
var _jump_released: bool = false

var _coyote_timer: float = 0.0
var _jump_buffer_timer: float = 0.0
var _dash_cooldown_timer: float = 0.0
var _wall_jump_lockout_timer: float = 0.0
var _air_dash_used: bool = false


func _ready() -> void:
	if config == null:
		push_error("Player has no MovementConfig — it cannot move.")
		set_physics_process(false)
		return
	_state_machine.setup(self)
	_apply_camera_limits()
	Events.player_spawned.emit(self)


func _physics_process(delta: float) -> void:
	_read_input()
	_tick_timers(delta)
	_state_machine.physics_update(delta)
	move_and_slide()
	_settle_after_move()


# --- Input ------------------------------------------------------------------

func _read_input() -> void:
	input_direction = (
		int(Input.is_action_pressed("move_right"))
		- int(Input.is_action_pressed("move_left"))
	)
	_dash_pressed = Input.is_action_just_pressed("dash")
	_jump_released = Input.is_action_just_released("jump")
	if Input.is_action_just_pressed("jump"):
		# Buffer every press. Whichever state can honour it consumes it; if
		# nothing does within the window it expires harmlessly.
		_jump_buffer_timer = config.jump_buffer_time


func wants_dash() -> bool:
	return _dash_pressed


func wants_jump_cut() -> bool:
	return _jump_released


# --- Timers -----------------------------------------------------------------

func _tick_timers(delta: float) -> void:
	_coyote_timer = maxf(_coyote_timer - delta, 0.0)
	_jump_buffer_timer = maxf(_jump_buffer_timer - delta, 0.0)
	_dash_cooldown_timer = maxf(_dash_cooldown_timer - delta, 0.0)
	_wall_jump_lockout_timer = maxf(_wall_jump_lockout_timer - delta, 0.0)


func _settle_after_move() -> void:
	if is_on_floor():
		# Refresh coyote every grounded frame; it only starts draining once we
		# actually leave the floor, which is exactly the grace window we want.
		_coyote_timer = config.coyote_time
		_air_dash_used = false


func _apply_camera_limits() -> void:
	var room := _find_room()
	if room == null or room.camera_limits.size == Vector2i.ZERO:
		return
	var limits: Rect2i = room.camera_limits
	camera.limit_left = limits.position.x
	camera.limit_top = limits.position.y
	camera.limit_right = limits.end.x
	camera.limit_bottom = limits.end.y


func _find_room() -> Room:
	var node: Node = get_parent()
	while node != null:
		if node is Room:
			return node as Room
		node = node.get_parent()
	return null


# --- Movement helpers used by the states ------------------------------------

## Accelerate toward `input_direction * run_speed`, or decelerate to a stop when
## there is no input. Reversing uses `turn_acceleration` so a turn is near
## instant without being a discontinuity.
func apply_horizontal(delta: float, grounded: bool) -> void:
	if horizontal_locked():
		# The wall kick owns the horizontal axis for a moment; see
		# MovementConfig.wall_jump_lockout_time for why.
		return

	var target: float = input_direction * config.run_speed
	var rate: float
	if input_direction == 0:
		rate = config.ground_deceleration if grounded else config.air_deceleration
	elif not is_zero_approx(velocity.x) and signf(target) != signf(velocity.x):
		rate = config.turn_acceleration
	else:
		rate = config.ground_acceleration if grounded else config.air_acceleration

	velocity.x = move_toward(velocity.x, target, rate * delta)


func apply_gravity(delta: float) -> void:
	var gravity: float = config.rise_gravity() if velocity.y < 0.0 else config.fall_gravity()
	velocity.y = minf(velocity.y + gravity * delta, config.max_fall_speed)


## Gravity, but with descent capped at the wall-slide speed.
func apply_wall_slide(delta: float) -> void:
	apply_gravity(delta)
	velocity.y = minf(velocity.y, config.wall_slide_speed)
	velocity.x = 0.0


func start_jump() -> void:
	velocity.y = config.jump_velocity()
	consume_jump()


func start_wall_jump(wall_direction: int) -> void:
	velocity = Vector2(-wall_direction * config.wall_jump_push, config.wall_jump_velocity())
	_wall_jump_lockout_timer = config.wall_jump_lockout_time
	set_facing(-wall_direction)
	consume_jump()


## Variable jump height: releasing early clips the rise short (DESIGN.md §3.1).
func cut_jump() -> void:
	if velocity.y < 0.0:
		velocity.y *= config.jump_cut_multiplier


func start_dash() -> void:
	velocity = Vector2(facing * config.dash_speed(), 0.0)
	if not is_on_floor():
		_air_dash_used = true


func end_dash() -> void:
	# Bleed the dash off at run speed rather than dropping to zero, so a dash
	# into a run keeps flowing.
	velocity.x = clampf(velocity.x, -config.run_speed, config.run_speed)
	velocity.y = 0.0
	_dash_cooldown_timer = config.dash_cooldown


# --- Queries used by the states ---------------------------------------------

## True while a jump is still allowed — grounded, or inside the coyote window.
func can_jump() -> bool:
	return _coyote_timer > 0.0


## True when a jump press is waiting to be honoured.
func has_buffered_jump() -> bool:
	return _jump_buffer_timer > 0.0


func consume_jump() -> void:
	_jump_buffer_timer = 0.0
	_coyote_timer = 0.0


func can_dash() -> bool:
	if _dash_cooldown_timer > 0.0:
		return false
	if is_on_floor():
		return true
	return config.can_dash_in_air and not _air_dash_used


## Direction *toward* the wall being touched: -1 left, +1 right, 0 for none.
func wall_direction() -> int:
	if not is_on_wall():
		return 0
	return -signi(int(signf(get_wall_normal().x)))


## True while the wall kick owns the horizontal axis. Both velocity and facing
## defer to it, so the kick is not cancelled — visually or physically — by a
## stick still held toward the wall.
func horizontal_locked() -> bool:
	return _wall_jump_lockout_timer > 0.0


func set_facing(direction: int) -> void:
	if direction == 0 or direction == facing:
		return
	facing = direction
	_visual.scale.x = facing


func state_name() -> StringName:
	return _state_machine.current_state_name()
