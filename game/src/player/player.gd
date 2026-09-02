class_name Player
extends CharacterBody2D
## The player controller (DESIGN.md §3.1 / M1, §3.2 / M2).
##
## This node owns the *physics*: velocity, gravity, the feel timers (coyote,
## jump buffer, dash cooldown, wall-jump lockout, attack cooldowns) and the
## helpers that act on them. The state machine under it owns the *decisions* —
## which of those helpers runs this frame. Keeping the split means a new state
## (M4's hacks) is one new file, not a rewrite of this one.
##
## Not one movement or combat constant lives here. Every number comes from
## `config`, `combat_config` or a weapon resource, so tuning the feel is an
## inspector session while the game runs.

## Facing is a separate concept from velocity: you keep facing the way you are
## travelling even while decelerating, and attacks fire the way you face.
enum Facing { LEFT = -1, RIGHT = 1 }

@export var config: MovementConfig
@export var combat_config: CombatConfig
@export var melee_weapon: MeleeWeapon
@export var ranged_weapon: RangedWeapon
## Shared energy pool for every ranged weapon (docs/rpg/stats-and-curves.md).
## Cap growth is a vendor purchase in M5; M2 just needs a number to spend.
@export var max_ammo: int = 8

@onready var _state_machine: PlayerStateMachine = $StateMachine
@onready var _visual: Node2D = $Visual
@onready var camera: Camera2D = $Camera2D
@onready var health: Health = $Health
@onready var hurtbox: Hurtbox = $Hurtbox
@onready var melee_hitbox: Hitbox = $MeleeHitbox

## +1 right, -1 left.
var facing: int = Facing.RIGHT
## -1, 0 or +1 from the move_left/move_right actions this frame.
var input_direction: int = 0
var ammo: int = 0
## Edge-triggered input, sampled once per frame in `_read_input`. States read
## these rather than polling `Input` themselves: one sample point per frame
## means two states can never disagree about whether a button was tapped, and
## the answer cannot change depending on how deep into the frame it is asked.
var _dash_pressed: bool = false
var _jump_released: bool = false
var _melee_pressed: bool = false
var _ranged_pressed: bool = false

var _coyote_timer: float = 0.0
var _jump_buffer_timer: float = 0.0
var _dash_cooldown_timer: float = 0.0
var _wall_jump_lockout_timer: float = 0.0
var _melee_cooldown_timer: float = 0.0
var _ranged_cooldown_timer: float = 0.0
var _air_dash_used: bool = false
var _melee_shape: RectangleShape2D
var _swing_visual: ColorRect
var _spawn_position: Vector2 = Vector2.ZERO


func _ready() -> void:
	if config == null:
		push_error("Player has no MovementConfig — it cannot move.")
		set_physics_process(false)
		return
	# Enemies find the player by group rather than by node path, so a room can
	# put the player anywhere in its tree.
	add_to_group(&"player")
	_state_machine.setup(self)
	_apply_camera_limits()
	_setup_combat()
	_spawn_position = global_position
	Events.player_spawned.emit(self)


func _physics_process(delta: float) -> void:
	_read_input()
	_tick_timers(delta)
	_state_machine.physics_update(delta)
	# Ranged is resolved here rather than inside a state because it *has* no
	# state: firing costs a cooldown, never commitment, so a shot must be
	# legal while running, jumping, dashing or wall-sliding. Giving it a state
	# would also mean five near-identical transitions, and would make the
	# nailgun's 4/s fire rate a state-machine problem.
	if _ranged_pressed and can_fire_ranged():
		fire_ranged()
	move_and_slide()
	_settle_after_move()


func _process(_delta: float) -> void:
	_update_iframe_flash()


# --- Input ------------------------------------------------------------------

func _read_input() -> void:
	input_direction = (
		int(Input.is_action_pressed("move_right"))
		- int(Input.is_action_pressed("move_left"))
	)
	_dash_pressed = Input.is_action_just_pressed("dash")
	_jump_released = Input.is_action_just_released("jump")
	_melee_pressed = Input.is_action_just_pressed("attack_melee")
	_ranged_pressed = Input.is_action_just_pressed("attack_ranged")
	if Input.is_action_just_pressed("jump"):
		# Buffer every press. Whichever state can honour it consumes it; if
		# nothing does within the window it expires harmlessly.
		_jump_buffer_timer = config.jump_buffer_time


func wants_dash() -> bool:
	return _dash_pressed


func wants_jump_cut() -> bool:
	return _jump_released


func wants_melee() -> bool:
	return _melee_pressed


# --- Timers -----------------------------------------------------------------

func _tick_timers(delta: float) -> void:
	_coyote_timer = maxf(_coyote_timer - delta, 0.0)
	_jump_buffer_timer = maxf(_jump_buffer_timer - delta, 0.0)
	_dash_cooldown_timer = maxf(_dash_cooldown_timer - delta, 0.0)
	_wall_jump_lockout_timer = maxf(_wall_jump_lockout_timer - delta, 0.0)
	_melee_cooldown_timer = maxf(_melee_cooldown_timer - delta, 0.0)
	_ranged_cooldown_timer = maxf(_ranged_cooldown_timer - delta, 0.0)


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


# --- Combat (M2) ------------------------------------------------------------

func _setup_combat() -> void:
	if combat_config == null:
		push_error("Player has no CombatConfig — it cannot fight or be hurt.")
		return

	health.iframe_time = combat_config.player_iframe_time
	health.damaged.connect(_on_damaged)
	health.died.connect(_on_died)

	# The swing box is sized from the weapon rather than the scene, so swapping
	# the maul in changes its reach without touching player.tscn.
	_melee_shape = RectangleShape2D.new()
	var collider := CollisionShape2D.new()
	collider.shape = _melee_shape
	melee_hitbox.add_child(collider)

	# The swing tell lives inside the hitbox, so it inherits the box's position
	# and facing mirror for free and cannot drift away from what it is drawing.
	_swing_visual = ColorRect.new()
	_swing_visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_swing_visual.z_index = 5
	_swing_visual.visible = false
	melee_hitbox.add_child(_swing_visual)

	ammo = max_ammo
	Events.ammo_changed.emit(ammo, max_ammo)
	Events.hp_changed.emit(health.hp, health.max_hp)


## Eight-way aim off the movement keys (docs/combat/damage-pipeline.md).
##
## Neutral fires along facing; up fires straight up; up + forward fires the 45°
## diagonal. Down fires straight down but only while airborne — on the ground
## it would just hit the floor, so it is ignored rather than wasted.
##
## No new inputs and no aiming UI: `move_up`/`move_down` are already mapped,
## and reusing them keeps the pad a first-class citizen, which free aim would
## not.
func aim_direction() -> Vector2:
	var vertical: int = (
		int(Input.is_action_pressed("move_down"))
		- int(Input.is_action_pressed("move_up"))
	)
	if vertical > 0 and is_on_floor():
		vertical = 0
	if vertical == 0:
		return Vector2(float(facing), 0.0)
	if input_direction == 0:
		return Vector2(0.0, float(vertical))
	return Vector2(float(input_direction), float(vertical)).normalized()


func can_melee() -> bool:
	return melee_weapon != null and _melee_cooldown_timer <= 0.0


## Arms the swing box. The cooldown is spent on the swing, not on the hit —
## whiffing costs you exactly as much as connecting does.
func start_melee() -> void:
	var attack := Attack.make(
		self, global_position, melee_weapon.power, melee_weapon.knockback
	)
	attack.ammo_on_hit = melee_weapon.ammo_on_hit

	_melee_shape.size = melee_weapon.hitbox_size
	melee_hitbox.position = Vector2(
		melee_weapon.hitbox_offset.x * float(facing), melee_weapon.hitbox_offset.y
	)
	melee_hitbox.activate(attack)
	_melee_cooldown_timer = melee_weapon.cooldown()

	# Drawn at the hitbox's exact size, not an approximation of it. In a
	# tuning lab the tell has to *be* the truth: a swing arc that is bigger
	# than its hitbox teaches the player a reach they do not have, and every
	# whiff after that reads as the game dropping inputs.
	_swing_visual.size = melee_weapon.hitbox_size
	_swing_visual.position = -melee_weapon.hitbox_size * 0.5
	_swing_visual.color = melee_weapon.swing_color
	_swing_visual.modulate.a = 1.0
	_swing_visual.visible = true


func end_melee() -> void:
	melee_hitbox.deactivate()
	_swing_visual.visible = false


## Solid while the box is armed, a fading ghost through the recovery tail.
##
## The two phases are drawn differently on purpose: the solid frames are the
## ones that can hit, and the ghost is the window the Scav's overcommit lesson
## teaches players to punish. One shape, both halves of the swing, no lie in
## either direction.
func set_swing_alpha(alpha: float) -> void:
	if _swing_visual != null:
		_swing_visual.modulate.a = alpha


func can_fire_ranged() -> bool:
	if ranged_weapon == null or _ranged_cooldown_timer > 0.0:
		return false
	return ammo >= ranged_weapon.energy_per_shot


func fire_ranged() -> void:
	var direction: Vector2 = aim_direction()
	var attack := Attack.make(
		self, global_position, ranged_weapon.power, ranged_weapon.knockback
	)
	attack.is_ranged = true

	var shot := Projectile.new()
	shot.collision_layer = 512  # projectile
	shot.collision_mask = 1 | 64  # world + enemy_hurtbox
	var muzzle := Vector2(
		ranged_weapon.muzzle_offset.x * float(facing), ranged_weapon.muzzle_offset.y
	)
	get_parent().add_child(shot)
	shot.global_position = global_position + muzzle
	shot.launch(
		attack,
		direction,
		ranged_weapon.projectile_speed,
		ranged_weapon.projectile_lifetime,
		ranged_weapon.projectile_size,
		ranged_weapon.projectile_color
	)

	spend_ammo(ranged_weapon.energy_per_shot)
	_ranged_cooldown_timer = ranged_weapon.cooldown()


## Step 10 — the attacker's on-hit interlocks, called back by the `Hurtbox`
## that resolved the hit.
##
## The refill amount arrives on the attack, sourced from the weapon resource,
## so this method never learns which weapon is equipped and V2 can switch the
## whole intertwined kit off by zeroing a field on three items.
func on_hit_landed(attack: Attack, _result: DamageResult) -> void:
	if attack.ammo_on_hit > 0:
		add_ammo(attack.ammo_on_hit)


func add_ammo(amount: int) -> void:
	# No overflow banking: meleeing at full ammo should feel like the wrong
	# choice, not like saving up.
	var before: int = ammo
	ammo = mini(ammo + amount, max_ammo)
	if ammo != before:
		Events.ammo_changed.emit(ammo, max_ammo)


func spend_ammo(amount: int) -> void:
	var before: int = ammo
	ammo = maxi(ammo - amount, 0)
	if ammo != before:
		Events.ammo_changed.emit(ammo, max_ammo)


## Called by our own `Hurtbox` when something lands on us.
##
## The direction comes from the hit but the magnitude is our own, much smaller
## constant: enemy-side knockback is juice, player-side knockback is loss of
## control, and the two want opposite budgets.
func apply_knockback(impulse: Vector2) -> void:
	if combat_config == null:
		return
	var direction: float = signf(impulse.x)
	if is_zero_approx(direction):
		direction = float(-facing)
	velocity.x = direction * combat_config.player_hurt_knockback


func _on_damaged(_amount: int, _attack: Attack) -> void:
	Events.hp_changed.emit(health.hp, health.max_hp)


func _on_died() -> void:
	Events.player_died.emit()
	# M2 respawns at the room's entry point. Save-point respawn is M5's, once
	# save points exist; the slice default (respawn, keep everything) is the
	# target behaviour and nothing here should assume otherwise.
	respawn()


func respawn() -> void:
	health.restore()
	velocity = Vector2.ZERO
	global_position = _spawn_position
	ammo = max_ammo
	Events.hp_changed.emit(health.hp, health.max_hp)
	Events.ammo_changed.emit(ammo, max_ammo)


## An invulnerability the player cannot see is indistinguishable from the
## hitbox missing, so the i-frame window is always drawn.
func _update_iframe_flash() -> void:
	if health == null or combat_config == null:
		return
	if not health.is_invulnerable():
		if not is_equal_approx(_visual.modulate.a, 1.0):
			_visual.modulate.a = 1.0
		return
	var phase: float = fmod(
		Time.get_ticks_msec() / 1000.0 * combat_config.iframe_flash_hz, 1.0
	)
	_visual.modulate.a = 0.3 if phase < 0.5 else 1.0
