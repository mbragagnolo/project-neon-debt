class_name Enemy
extends CharacterBody2D
## Shared base for every roster entry (DESIGN.md §3.5).
##
## Same split as the player controller: this node owns the *physics* — gravity,
## velocity, facing, the cooldown timers, the hitboxes — and the state machine
## under it owns the *decisions*. An enemy's whole personality is its
## `EnemyConfig` plus which states it has, so M6's roster is mostly `.tres`
## files rather than mostly code.
##
## Contact damage is armed here rather than in a state, because it is a
## condition rather than an action: an enemy is dangerous to touch the entire
## time it is alive (docs/characters/enemies.md, cross-cutting rules). The
## player's i-frames are what keep that fair.

const CONFIG_PATH := "res://src/combat/combat_config.tres"
const PLAYER_GROUP := &"player"
## Every enemy joins this group, which is how a hack finds its targets without
## the kit holding a list: the nearest member in radius is Overload's, every
## `mechanical` member in radius is Breach's.
const ENEMY_GROUP := &"enemies"

@export var config: EnemyConfig

@onready var health: Health = $Health
@onready var hurtbox: Hurtbox = $Hurtbox
@onready var attack_hitbox: Hitbox = $AttackHitbox
@onready var contact_hitbox: Hitbox = $ContactHitbox
## Either the greybox box (the dummy, tests) or a `PixelAnim` sheet.
@onready var visual: CanvasItem = $Visual
@onready var _state_machine: EnemyStateMachine = $StateMachine

## +1 right, -1 left.
var facing: int = 1
## Where it spawned. Patrol beats and the aggro leash are both measured from
## here, so an enemy always has somewhere to go back to.
var home: Vector2 = Vector2.ZERO
var player: Node2D
## Seconds the current stun lasts. Set by `stun()` just before the transition,
## read by the Stunned state on entry — the same hand-off shape as the lunge.
var stun_duration: float = 0.0

var _gravity: float = 0.0
var _lunge_cooldown_timer: float = 0.0
var _flash_timer: float = 0.0
var _last_tint: Color = Color.WHITE
var _fire_cooldown_timer: float = 0.0
var _combat_config: CombatConfig
var _attack_shape: RectangleShape2D
## Optional `Facing` child, mirrored with the facing so a shield or a gun
## sits on the side it is meant to.
var _facing_node: Node2D


func _ready() -> void:
	if config == null:
		push_error("Enemy '%s' has no EnemyConfig — it cannot act." % name)
		set_physics_process(false)
		return

	add_to_group(ENEMY_GROUP)
	home = global_position
	_gravity = float(ProjectSettings.get_setting("physics/2d/default_gravity", 980.0))
	_combat_config = load(CONFIG_PATH) as CombatConfig

	# The stat block lives on the config and is mirrored onto Health, the same
	# shape the training dummy uses: one authored source, and scene overrides
	# that survive being packed.
	health.max_hp = config.max_hp
	health.defense = config.defense
	health.stagger_threshold = config.stagger_threshold
	health.tags = config.tags
	health.restore()
	health.damaged.connect(_on_damaged)
	health.staggered.connect(_on_staggered)
	health.died.connect(_on_died)

	# The attack box is sized from the config, so an Elite Scav with longer
	# reach is a resource edit rather than a second scene.
	_attack_shape = RectangleShape2D.new()
	_attack_shape.size = config.attack_size
	var collider := CollisionShape2D.new()
	collider.shape = _attack_shape
	attack_hitbox.add_child(collider)

	_acquire_player()
	Events.player_spawned.connect(_on_player_spawned)
	_facing_node = get_node_or_null("Facing") as Node2D

	arm_contact()
	_state_machine.setup(self)
	tint(config.color_idle)


func _physics_process(delta: float) -> void:
	_lunge_cooldown_timer = maxf(_lunge_cooldown_timer - delta, 0.0)
	_fire_cooldown_timer = maxf(_fire_cooldown_timer - delta, 0.0)
	if _flash_timer > 0.0:
		_flash_timer -= delta
		if _flash_timer <= 0.0:
			tint(_last_tint)
	_state_machine.physics_update(delta)
	move_and_slide()


# --- Physics helpers used by the states -------------------------------------

## Fliers ignore gravity unless `force` — the Stunned and Dead states force
## it, which is how Breach drops a drone out of the air.
func apply_gravity(delta: float, force: bool = false) -> void:
	if config.flies and not force:
		return
	velocity.y += _gravity * delta


## Steer toward a point at `speed`, easing in so a flier settles rather than
## overshoots. Facing follows the horizontal component.
func fly_toward(target: Vector2, speed: float, delta: float) -> void:
	var to: Vector2 = target - global_position
	var distance: float = to.length()
	var wanted: Vector2 = Vector2.ZERO
	if distance > 4.0:
		wanted = to.normalized() * minf(speed, distance * 3.0)
	velocity = velocity.move_toward(wanted, config.fly_acceleration * delta)
	if absf(to.x) > 12.0:
		set_facing(signi(int(signf(to.x))))


func walk(direction: int, speed: float) -> void:
	velocity.x = float(direction) * speed
	set_facing(direction)


## Bleed horizontal speed off rather than zeroing it, so a knockback impulse
## and a lunge both decay visibly instead of vanishing between frames.
func brake(delta: float, rate: float = 1400.0) -> void:
	velocity.x = move_toward(velocity.x, 0.0, rate * delta)


func set_facing(direction: int) -> void:
	if direction == 0 or direction == facing:
		return
	facing = direction
	if _facing_node != null:
		_facing_node.scale.x = float(facing)
	if visual is Sprite2D:
		(visual as Sprite2D).flip_h = facing < 0


## Called by our own `Hurtbox` at step 9.
func apply_knockback(impulse: Vector2) -> void:
	velocity += impulse


## The state colour. On a coloured box it *is* the picture; on a sprite it
## is blended over the art — faint for the idle states, loud for the windup,
## a white flash for the stagger — so the read the greybox taught survives.
func tint(colour: Color) -> void:
	_last_tint = colour
	if visual == null:
		return
	if visual is ColorRect:
		(visual as ColorRect).color = colour
		return
	if colour == config.color_stagger:
		visual.modulate = Color(1.7, 1.7, 1.7, visual.modulate.a)
		return
	var strength: float = 0.15
	if colour == config.color_windup:
		strength = 0.7
	elif colour == config.color_lunge:
		strength = 0.5
	elif colour == config.color_recover or colour == config.color_stunned:
		strength = 0.45
	var blended: Color = Color.WHITE.lerp(colour, strength)
	visual.modulate = Color(blended.r, blended.g, blended.b, visual.modulate.a)


## The clip for a state. A sheet without the clip keeps whatever it plays;
## a coloured box has no clips and ignores this.
func play(clip: StringName) -> void:
	if visual is PixelAnim:
		var anim: PixelAnim = visual as PixelAnim
		anim.play(clip if anim.has_clip(clip) else &"idle")


# --- Queries used by the states ---------------------------------------------

func has_player() -> bool:
	return player != null and is_instance_valid(player)


func distance_to_player() -> float:
	if not has_player():
		return INF
	return global_position.distance_to(player.global_position)


## Horizontal direction toward the player: -1, 0 or +1.
func direction_to_player() -> int:
	if not has_player():
		return 0
	var delta_x: float = player.global_position.x - global_position.x
	if is_zero_approx(delta_x):
		return 0
	return signi(int(signf(delta_x)))


func distance_from_home() -> float:
	return absf(global_position.x - home.x)


func can_lunge() -> bool:
	return _lunge_cooldown_timer <= 0.0


func start_lunge_cooldown() -> void:
	_lunge_cooldown_timer = config.lunge_cooldown


func can_fire() -> bool:
	return config.fires and _fire_cooldown_timer <= 0.0


func start_fire_cooldown() -> void:
	_fire_cooldown_timer = config.fire_interval


## Where a state goes when it is done being interrupted or recovering. The
## roster's enemies chase or patrol; a boss overrides this with its own
## approach state.
func after_recover_state() -> StringName:
	var aware: bool = has_player() and distance_to_player() <= config.detection_range
	if config.flies:
		return &"Track" if aware else &"Hover"
	return &"Chase" if aware else &"Patrol"


## The centre of the body, for aiming at and from.
func center() -> Vector2:
	return global_position + Vector2(0.0, -40.0)


func state_name() -> StringName:
	return _state_machine.current_state_name()


# --- The lunge --------------------------------------------------------------

## Commits: a fixed horizontal burst with the attack box armed at full
## `attack_power`. Contact damage stays armed underneath at half — the player's
## i-frames mean only one of them can land, and the bigger number wins because
## the pipeline resolves the attack box first.
func start_lunge() -> void:
	velocity.x = float(facing) * config.lunge_speed
	attack_hitbox.position = Vector2(
		config.attack_offset.x * float(facing), config.attack_offset.y
	)
	var attack := Attack.make(
		self, global_position, config.attack_power, config.lunge_knockback
	)
	attack.scales_with_stat = false
	attack_hitbox.activate(attack)


func end_lunge() -> void:
	attack_hitbox.deactivate()


## Lobs one projectile at where the player is *now*. Flat power like every
## enemy hit, `is_ranged` so the pipeline treats it as a shot, and it stops at
## walls — masked to the world and the player's hurtbox only.
func fire_at_player() -> void:
	if not has_player():
		return
	var target: Vector2 = player.global_position + Vector2(0.0, -44.0)
	fire_toward(target)


func fire_toward(target: Vector2) -> Projectile:
	var origin: Vector2 = center()
	Events.sfx_requested.emit(&"drone_shot", origin)
	var direction: Vector2 = (target - origin).normalized()
	if direction == Vector2.ZERO:
		direction = Vector2(float(facing), 0.0)
	var attack := Attack.make(self, origin, config.attack_power, config.projectile_knockback)
	attack.scales_with_stat = false
	attack.is_ranged = true
	var shot := Projectile.new()
	shot.collision_layer = 512  # projectile
	shot.collision_mask = 1 | 8  # world + player_hurtbox
	get_parent().add_child(shot)
	shot.global_position = origin
	shot.launch(
		attack, direction, config.projectile_speed, config.projectile_lifetime,
		config.projectile_size, config.projectile_color, 0.0, config.projectile_texture
	)
	start_fire_cooldown()
	return shot


func arm_contact() -> void:
	if health.is_dead():
		return
	var mult: float = _combat_config.contact_damage_mult if _combat_config != null else 0.5
	var attack := Attack.make(self, global_position, config.contact_power(mult))
	attack.scales_with_stat = false
	attack.is_contact = true
	contact_hitbox.activate(attack)


func disarm_contact() -> void:
	contact_hitbox.deactivate()


# --- Hacks ------------------------------------------------------------------

## Breach's hook. Only `mechanical` enemies answer — a Scav shrugs at a
## handshake request, which is the whole reason the tag exists. Returns
## whether the stun took, so the caster can tell "nothing in reach" from
## "nothing in reach that cares".
func stun(seconds: float) -> bool:
	if health.is_dead() or not is_mechanical():
		return false
	if not has_node("StateMachine/Stunned"):
		return false
	stun_duration = seconds
	_state_machine.transition_to(&"Stunned")
	return true


func is_mechanical() -> bool:
	return health.tags.has(Health.TAG_MECHANICAL)


func is_stunned() -> bool:
	return state_name() == &"Stunned"


# --- Reactions --------------------------------------------------------------

func _on_damaged(_amount: int, _attack: Attack) -> void:
	flash()


## A white pop on the frame a hit lands (docs/art/direction.md). The state
## tint comes back when it fades.
func flash() -> void:
	if visual == null or visual is ColorRect or health.is_dead():
		return
	_flash_timer = 0.07
	visual.modulate = Color(2.4, 2.4, 2.4, visual.modulate.a)


## A hit that meets `stagger_threshold` interrupts whatever was happening —
## including a windup, which is what makes "bait the lunge, step in, punish"
## produce a visible reward rather than just a number.
func _on_staggered() -> void:
	if health.is_dead():
		return
	# A stunned enemy stays stunned. Knockback still lands (the hurtbox applied
	# it before this signal), but the setup verb's window is not spent by the
	# first hit that uses it.
	if is_stunned():
		return
	_state_machine.transition_to(&"Stagger")


func _on_died() -> void:
	end_lunge()
	contact_hitbox.deactivate()
	# Rewards resolve on the death event, not on the killing blow, so two hits
	# arriving in the same frame cannot both pay out.
	Events.enemy_died.emit(self, config.xp_reward, config.credit_reward)
	_state_machine.transition_to(&"Dead")


func _acquire_player() -> void:
	var found: Node = get_tree().get_first_node_in_group(PLAYER_GROUP)
	if found is Node2D:
		player = found as Node2D


func _on_player_spawned(spawned: Node) -> void:
	if spawned is Node2D:
		player = spawned as Node2D
