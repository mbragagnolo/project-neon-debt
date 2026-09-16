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
## Shared energy pool for every ranged weapon (docs/rpg/stats-and-curves.md).
## The authored base; the vendor's cells raise it through the sheet.
@export var base_max_ammo: int = 8
## In a gym the player respawns itself at the room's entry. Under the world
## (M5) death is the world's to handle — travel back to the terminal.
@export var handles_own_respawn: bool = true

@onready var _state_machine: PlayerStateMachine = $StateMachine
@onready var _visual: Node2D = $Visual
@onready var camera: Camera2D = $Camera2D
@onready var health: Health = $Health
@onready var hurtbox: Hurtbox = $Hurtbox
@onready var melee_hitbox: Hitbox = $MeleeHitbox
@onready var hacks: HackKit = $Hacks
@onready var _sprite: PixelAnim = $Visual/Sprite
@onready var _glow: Sprite2D = $Visual/Glow

## What is in hand. Not exported: `Inventory` is the single source of the
## loadout, because from M5 this node is re-instanced at every door and a kit
## authored on the scene would be a kit handed back on every room change.
var melee_weapon: MeleeWeapon
var ranged_weapon: RangedWeapon
## +1 right, -1 left.
var facing: int = Facing.RIGHT
## -1, 0 or +1 from the move_left/move_right actions this frame.
var input_direction: int = 0
var ammo: int = 0
var max_ammo: int = 8
## Set by the world while a room is swapping or a death plays out: no input,
## no physics. A door is not a place to keep falling.
var frozen: bool = false
## The casting pool (docs/rpg/stats-and-curves.md, RAM). The sheet owns the
## ceiling, this node owns the current number — same split as HP.
var ram: int = 0
var max_ram: int = 0
## Edge-triggered input, sampled once per frame in `_read_input`. States read
## these rather than polling `Input` themselves: one sample point per frame
## means two states can never disagree about whether a button was tapped, and
## the answer cannot change depending on how deep into the frame it is asked.
var _dash_pressed: bool = false
var _jump_released: bool = false
var _melee_pressed: bool = false
var _ranged_pressed: bool = false
var _hack_pressed: bool = false
var _hack_next_pressed: bool = false
var _hack_prev_pressed: bool = false

var _coyote_timer: float = 0.0
var _jump_buffer_timer: float = 0.0
var _dash_cooldown_timer: float = 0.0
var _wall_jump_lockout_timer: float = 0.0
var _melee_cooldown_timer: float = 0.0
var _ranged_cooldown_timer: float = 0.0
var _air_dash_used: bool = false
## The wall the last wall jump left, and how long it stays refused. A single
## wall must not be climbable by re-sticking after a jump off it (DESIGN.md
## §3.1): the refusal outlasts the jump's whole flight, so by the time this
## wall accepts the player again they are below where they left it. The
## *other* wall is always accepted — that is what a shaft is.
var _last_wall_jump_dir: int = 0
var _was_airborne: bool = false
var _same_wall_lockout_timer: float = 0.0
## Where the player last stood on solid ground clear of hazards. A void drop
## puts them back here.
var last_safe_position: Vector2 = Vector2.ZERO
var _safe_timer: float = 0.0
var _melee_shape: RectangleShape2D
var _swing_visual: SwingTell
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
	if frozen:
		return
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
	# Hacks have no state for the same reason ranged has none: a cast is
	# auto-targeted and instant, so it costs a cooldown and never commitment.
	if _hack_next_pressed:
		hacks.select_next()
	if _hack_prev_pressed:
		hacks.select_prev()
	if _hack_pressed:
		hacks.try_cast()
	move_and_slide()
	_settle_after_move()


func _process(_delta: float) -> void:
	_update_iframe_flash()
	_update_animation()


## The state machine decides the move; the clip follows it. Rising and
## falling are one Air state and two clips, which is the only place the
## picture knows something the machine does not bother to.
func _update_animation() -> void:
	if _sprite == null:
		return
	var clip: StringName = &"idle"
	match state_name():
		&"Run": clip = &"run"
		&"Air": clip = &"jump" if velocity.y < 0.0 else &"fall"
		&"Dash": clip = &"dash"
		&"WallSlide": clip = &"wall"
		&"MeleeAttack": clip = &"attack"
	_sprite.play(clip)


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
	_hack_pressed = Input.is_action_just_pressed("hack_cast")
	_hack_next_pressed = Input.is_action_just_pressed("hack_next")
	_hack_prev_pressed = Input.is_action_just_pressed("hack_prev")
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
	_same_wall_lockout_timer = maxf(_same_wall_lockout_timer - delta, 0.0)
	if _same_wall_lockout_timer <= 0.0:
		_last_wall_jump_dir = 0


func _settle_after_move() -> void:
	if is_on_floor():
		if _was_airborne:
			_was_airborne = false
			Events.player_action.emit(&"land", global_position, facing)
		# Refresh coyote every grounded frame; it only starts draining once we
		# actually leave the floor, which is exactly the grace window we want.
		_coyote_timer = config.coyote_time
		_air_dash_used = false
		_last_wall_jump_dir = 0
		_same_wall_lockout_timer = 0.0
		# Safe ground is ground stood on for a moment without being hurt —
		# the lip of a pit counts, the tile you were knocked back onto from
		# live water does not.
		_safe_timer += get_physics_process_delta_time()
		if _safe_timer >= 0.25 and not health.is_invulnerable():
			last_safe_position = global_position
	else:
		_safe_timer = 0.0
		_was_airborne = true


func _apply_camera_limits() -> void:
	apply_room_limits(_find_room())


## Clamps the camera to a room. The gyms find their room above them; the
## world hands its current room in, because there the player is the room's
## sibling rather than its child.
func apply_room_limits(room: Room) -> void:
	if room == null:
		return
	if room.camera_limits.size == Vector2i.ZERO:
		camera.limit_left = -10000000
		camera.limit_top = -10000000
		camera.limit_right = 10000000
		camera.limit_bottom = 10000000
		return
	var limits: Rect2i = room.camera_limits
	var origin: Vector2 = room.global_position
	camera.limit_left = int(origin.x) + limits.position.x
	camera.limit_top = int(origin.y) + limits.position.y
	camera.limit_right = int(origin.x) + limits.end.x
	camera.limit_bottom = int(origin.y) + limits.end.y


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
	Events.player_action.emit(&"jump", global_position, facing)


func start_wall_jump(wall_direction: int) -> void:
	velocity = Vector2(-wall_direction * config.wall_jump_push, config.wall_jump_velocity())
	_wall_jump_lockout_timer = config.wall_jump_lockout_time
	_last_wall_jump_dir = wall_direction
	_same_wall_lockout_timer = config.same_wall_lockout_time()
	set_facing(-wall_direction)
	consume_jump()
	Events.player_action.emit(&"wall_jump", global_position, wall_direction)


## Variable jump height: releasing early clips the rise short (DESIGN.md §3.1).
func cut_jump() -> void:
	if velocity.y < 0.0:
		velocity.y *= config.jump_cut_multiplier


func start_dash() -> void:
	velocity = Vector2(facing * config.dash_speed(), 0.0)
	if not is_on_floor():
		_air_dash_used = true
	Events.player_action.emit(&"dash", global_position, facing)


func end_dash() -> void:
	# Bleed the dash off at run speed rather than dropping to zero, so a dash
	# into a run keeps flowing.
	velocity.x = clampf(velocity.x, -config.run_speed, config.run_speed)
	velocity.y = 0.0
	# A dash that ran off a ledge does not get a jump at its end. Without
	# this, the coyote window opened by leaving the ground mid-dash lets a
	# buffered jump fire in mid-air, and the starting kit's reach across a gap
	# becomes "dash off the edge, then jump" — which is the Sidewinder's job
	# (docs/level-design/stacks.md, the envelope). Dash-jump from the ground
	# is untouched: on a floor the coyote timer refreshes every frame.
	if not is_on_floor():
		_coyote_timer = 0.0
	# Read through the stats layer, never straight off `MovementConfig` — the
	# boots' modifier exists here and nowhere else (docs/rpg/items.md).
	_dash_cooldown_timer = PlayerStats.effective_dash_cooldown(config.dash_cooldown)


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


## Grounded: the ground dash, on its cooldown. Airborne: the Sidewinder's air
## dash, one per airtime and **not** on the ground dash's cooldown — that is
## what makes dash → jump → air dash a chain rather than a timing puzzle, and
## it is the whole reason the implant extends reach past a dash-jump
## (docs/level-design/stacks.md, the envelope).
func can_dash() -> bool:
	if is_on_floor():
		return _dash_cooldown_timer <= 0.0
	return has_air_dash() and not _air_dash_used


## Possession, not tuning: the config says how an air dash behaves, the
## Sidewinder flag says whether the player has it (DESIGN.md §3.1).
func has_air_dash() -> bool:
	return config.can_dash_in_air and GameState.has_ability(GameState.ABILITY_SIDEWINDER)


## The Mag-Hook. Wall *slide* is always available — it teaches that walls are
## interactive — and the jump off one is the first gate in the game.
func can_wall_jump() -> bool:
	return GameState.has_ability(GameState.ABILITY_MAG_HOOK)


## Direction *toward* the wall being touched: -1 left, +1 right, 0 for none.
## A wall the player just jumped off is not a wall for a moment — see
## `_same_wall_lockout_timer`.
func wall_direction() -> int:
	if not is_on_wall():
		return 0
	var direction: int = -signi(int(signf(get_wall_normal().x)))
	if direction == _last_wall_jump_dir and _same_wall_lockout_timer > 0.0:
		return 0
	return direction


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

	# The sheet owns max HP and DEF; this node owns the current number. Both
	# arrive on the bus, so nothing here holds a reference to PlayerStats
	# beyond asking it for values.
	_refresh_loadout()
	_apply_sheet()
	health.restore()
	Events.item_equipped.connect(_on_item_equipped)
	Events.stats_changed.connect(_on_stats_changed)
	Events.level_gained.connect(_on_level_gained)

	# The swing box is sized from the weapon rather than the scene, so swapping
	# the maul in changes its reach without touching player.tscn.
	_melee_shape = RectangleShape2D.new()
	var collider := CollisionShape2D.new()
	collider.shape = _melee_shape
	melee_hitbox.add_child(collider)

	# The swing tell lives inside the hitbox, so it inherits the box's position
	# and facing mirror for free and cannot drift away from what it is drawing.
	_swing_visual = SwingTell.new()
	melee_hitbox.add_child(_swing_visual)

	max_ammo = PlayerStats.effective_max_ammo(base_max_ammo)
	ammo = max_ammo
	Events.ammo_changed.emit(ammo, max_ammo)
	Events.hp_changed.emit(health.hp, health.max_hp)
	ram = max_ram
	Events.ram_changed.emit(ram, max_ram)
	hacks.setup(self)
	PlayerStats.publish()


func _refresh_loadout() -> void:
	melee_weapon = Inventory.equipped_melee()
	ranged_weapon = Inventory.equipped_ranged()


## Max HP and DEF, folded from the level curve and the equipped clothing.
##
## Current HP is clamped down but never topped up when the ceiling rises.
## Granting the difference would read better for one frame and then be an
## exploit: equipping and re-equipping the jacket while wounded would heal 10
## a cycle, forever. The full heal belongs to the level-up, where it is
## earned.
func _apply_sheet() -> void:
	if health == null:
		return
	health.max_hp = PlayerStats.effective_max_hp()
	health.defense = PlayerStats.effective_defense()
	health.hp = mini(health.hp, health.max_hp)
	Events.hp_changed.emit(health.hp, health.max_hp)
	# RAM follows the same rule as HP: the ceiling moves, the current number
	# is clamped down and never topped up. A level-up does not refill RAM —
	# the full restore is a save terminal's job (stats-and-curves.md).
	max_ram = PlayerStats.effective_max_ram()
	ram = mini(ram, max_ram)
	Events.ram_changed.emit(ram, max_ram)
	max_ammo = PlayerStats.effective_max_ammo(base_max_ammo)
	ammo = mini(ammo, max_ammo)
	Events.ammo_changed.emit(ammo, max_ammo)


func _on_item_equipped(_slot: StringName, _item_id: StringName) -> void:
	_refresh_loadout()


func _on_stats_changed(_sheet: Dictionary) -> void:
	_apply_sheet()


## Level-up = full heal (DESIGN.md §3.3). The sheet is applied first: the
## signal arrives with the new level already set, so healing before raising
## the ceiling would top up to the old maximum and leave the difference empty.
func _on_level_gained(_new_level: int) -> void:
	_apply_sheet()
	health.restore()
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
	# Step 4: the weapon is the base, STR is the multiplier. Wired here rather
	# than inside the pipeline so the enemy side stays flat.
	attack.stat = PlayerStats.strength()
	# The hardhat's +1 rides along on the attack, so the interlock stays the
	# weapon's number bent by equipment rather than a constant in the pipeline.
	attack.ammo_on_hit = PlayerStats.effective_ammo_on_hit(melee_weapon)

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
	_swing_visual.show_swing(melee_weapon.hitbox_size, melee_weapon.swing_color)
	Events.player_action.emit(&"swing", global_position, facing)
	if _sprite != null:
		_sprite.play(&"attack", true)


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
		_swing_visual.set_alpha(alpha)


func can_fire_ranged() -> bool:
	if ranged_weapon == null or _ranged_cooldown_timer > 0.0:
		return false
	return ammo >= ranged_weapon.energy_per_shot


func fire_ranged() -> void:
	var direction: Vector2 = aim_direction()
	var attack := Attack.make(
		self, global_position, ranged_weapon.power, ranged_weapon.knockback
	)
	attack.stat = PlayerStats.dexterity()
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
		ranged_weapon.projectile_color,
		ranged_weapon.projectile_gravity,
		ranged_weapon.projectile_texture
	)

	spend_ammo(ranged_weapon.energy_per_shot)
	_ranged_cooldown_timer = ranged_weapon.cooldown()
	var weapon_id: String = String(ranged_weapon.id)
	var verb: StringName = &"shoot_bolt"
	if weapon_id.contains("nail"):
		verb = &"shoot_nail"
	elif weapon_id.contains("rivet"):
		verb = &"shoot_rivet"
	Events.player_action.emit(verb, global_position, facing)


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


# --- RAM (M4) ---------------------------------------------------------------

func add_ram(amount: int) -> void:
	var before: int = ram
	ram = mini(ram + amount, max_ram)
	if ram != before:
		Events.ram_changed.emit(ram, max_ram)


func spend_ram(amount: int) -> void:
	var before: int = ram
	ram = maxi(ram - amount, 0)
	if ram != before:
		Events.ram_changed.emit(ram, max_ram)


## The save terminal's full restore, and the gym's respawn convenience.
func restore_ram() -> void:
	ram = max_ram
	Events.ram_changed.emit(ram, max_ram)


## Everything a HUD draws, restated. A HUD built after the player already
## announced itself starts blank otherwise: the bus carries no history.
func publish_vitals() -> void:
	Events.hp_changed.emit(health.hp, health.max_hp)
	Events.ram_changed.emit(ram, max_ram)
	Events.ammo_changed.emit(ammo, max_ammo)
	if hacks != null and hacks.selected() != null:
		Events.hack_selected.emit(hacks.selected().id)
	PlayerStats.publish()


## The care terminal: full HP, full RAM, full pool.
func restore_all() -> void:
	health.restore()
	Events.hp_changed.emit(health.hp, health.max_hp)
	restore_ram()
	ammo = max_ammo
	Events.ammo_changed.emit(ammo, max_ammo)


## A drop into nothing. Back to the last safe ground, HP already docked by
## the pipeline; velocity cleared so the return does not carry the fall.
func void_return() -> void:
	velocity = Vector2.ZERO
	if last_safe_position != Vector2.ZERO:
		global_position = last_safe_position
	if camera.has_method(&"snap_to_target"):
		camera.call(&"snap_to_target")


## Live water. Up and away, so a pool is something you get out of.
func hazard_bounce(from: Vector2) -> void:
	velocity.y = config.jump_velocity() * 0.9
	Events.player_action.emit(&"hazard", global_position, facing)
	var direction: float = signf(global_position.x - from.x)
	if is_zero_approx(direction):
		direction = float(-facing)
	velocity.x = direction * 260.0


## Firewall's tell. A buff the player cannot see is a buff they will not trust
## enough to cast into a hit.
func set_guard_visual(active: bool, colour: Color) -> void:
	if _glow == null:
		return
	_glow.modulate = Color(colour.r, colour.g, colour.b, 0.55 if active else 0.0)


func is_guard_visible() -> bool:
	return _glow != null and _glow.modulate.a > 0.0


## Where a hack measures from and draws to: mid-body, not the feet.
func center() -> Vector2:
	return global_position + Vector2(0.0, -44.0)


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
	var guarded: bool = health.guard_mult < 1.0
	Events.player_action.emit(&"hurt_guard" if guarded else &"hurt", global_position, facing)


func _on_died() -> void:
	Events.player_died.emit()
	# A gym respawns at the room's entry point. The world respawns at the last
	# care terminal (DESIGN.md §7: respawn, enemies respawn, keep everything).
	if handles_own_respawn:
		respawn()


func respawn() -> void:
	health.restore()
	velocity = Vector2.ZERO
	global_position = _spawn_position
	ammo = max_ammo
	Events.hp_changed.emit(health.hp, health.max_hp)
	Events.ammo_changed.emit(ammo, max_ammo)
	restore_ram()


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
