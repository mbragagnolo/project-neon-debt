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

@export var config: EnemyConfig

@onready var health: Health = $Health
@onready var hurtbox: Hurtbox = $Hurtbox
@onready var attack_hitbox: Hitbox = $AttackHitbox
@onready var contact_hitbox: Hitbox = $ContactHitbox
@onready var visual: ColorRect = $Visual
@onready var _state_machine: EnemyStateMachine = $StateMachine

## +1 right, -1 left.
var facing: int = 1
## Where it spawned. Patrol beats and the aggro leash are both measured from
## here, so an enemy always has somewhere to go back to.
var home: Vector2 = Vector2.ZERO
var player: Node2D

var _gravity: float = 0.0
var _lunge_cooldown_timer: float = 0.0
var _combat_config: CombatConfig
var _attack_shape: RectangleShape2D


func _ready() -> void:
	if config == null:
		push_error("Enemy '%s' has no EnemyConfig — it cannot act." % name)
		set_physics_process(false)
		return

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

	_arm_contact()
	_state_machine.setup(self)
	tint(config.color_idle)


func _physics_process(delta: float) -> void:
	_lunge_cooldown_timer = maxf(_lunge_cooldown_timer - delta, 0.0)
	_state_machine.physics_update(delta)
	move_and_slide()


# --- Physics helpers used by the states -------------------------------------

func apply_gravity(delta: float) -> void:
	velocity.y += _gravity * delta


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


## Called by our own `Hurtbox` at step 9.
func apply_knockback(impulse: Vector2) -> void:
	velocity += impulse


func tint(colour: Color) -> void:
	if visual != null:
		visual.color = colour


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


func _arm_contact() -> void:
	var mult: float = _combat_config.contact_damage_mult if _combat_config != null else 0.5
	var attack := Attack.make(self, global_position, config.contact_power(mult))
	attack.scales_with_stat = false
	attack.is_contact = true
	contact_hitbox.activate(attack)


# --- Reactions --------------------------------------------------------------

func _on_damaged(_amount: int, _attack: Attack) -> void:
	pass


## A hit that meets `stagger_threshold` interrupts whatever was happening —
## including a windup, which is what makes "bait the lunge, step in, punish"
## produce a visible reward rather than just a number.
func _on_staggered() -> void:
	if health.is_dead():
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
