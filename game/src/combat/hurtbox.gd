class_name Hurtbox
extends Area2D
## The receiving half of the shared component pair (DESIGN.md §3.2).
##
## Owns steps 7–11: apply the number the pipeline resolved, emit the signal the
## HUD and M7's juice hang off, spend the hitstop and knockback, run the
## attacker's interlocks, and let death fall out of `Health`.
##
## Sits on its combatant's hurtbox layer and masks nothing — hurtboxes are
## found, they do not go looking.

const CONFIG_PATH := "res://src/combat/combat_config.tres"

@export var health: Health
@export var config: CombatConfig

## The body knockback is applied to. Defaults to this box's parent, which is
## the shape every combatant in the game happens to have.
@onready var _body: Node = get_parent()


func _ready() -> void:
	if health == null:
		health = _find_health()
	if config == null and ResourceLoader.exists(CONFIG_PATH):
		config = load(CONFIG_PATH) as CombatConfig
	if health == null:
		push_error("Hurtbox on '%s' has no Health — it cannot be hurt." % name)


## Runs one attack through the pipeline and makes the outcome real.
##
## Returns the result rather than a bool so a caller — or a test — can tell a
## whiff from a shield from an i-frame window. Those are four different bugs
## and they all look like "took no damage".
func receive(attack: Attack) -> DamageResult:
	if health == null or config == null:
		return DamageResult.rejected(DamageResult.Rejection.INVULNERABLE)

	var result: DamageResult = Damage.resolve(attack, health, config)
	if not result.landed:
		return result

	# Step 7 — apply, then announce. The signal is the subscription point for
	# the HUD, SFX and M7's screen shake; none of them are pipeline steps.
	health.apply_damage(result.damage, attack)
	Events.damage_dealt.emit(_body, result.damage, attack.source)

	# Step 9 — hitstop, then knockback. Contact damage skips both: it is a
	# continuous condition, not an event, and freezing on it would stutter the
	# entire time a player is pinned against a Scav.
	if not attack.is_contact:
		var frames: int = config.hitstop_frames_for(result.damage)
		if frames > 0:
			Events.hitstop_requested.emit(frames)
	_apply_knockback(attack, result)

	# Step 10 — the attacker's on-hit interlocks. Duck-typed rather than
	# type-checked so the pipeline never has to know what a Player is; the
	# melee→ammo refill lives on the weapon resource, not here.
	if not attack.is_contact and attack.source != null:
		if attack.source.has_method(&"on_hit_landed"):
			attack.source.call(&"on_hit_landed", attack, result)

	# Step 3's other half: the i-frame window opens once damage is applied.
	# Data-driven, so enemies (iframe_time 0) never get one and a timer here
	# can never silently throttle the nailgun.
	if health.iframe_time > 0.0:
		health.grant_iframes(health.iframe_time)

	# Step 11 is `Health.died`, which fires from `apply_damage` above.
	return result


## Horizontal only, away from where the hit came from. Never radial: radial
## knockback launches bodies upward, and upward is where this game's
## platforming lives.
func _apply_knockback(attack: Attack, result: DamageResult) -> void:
	if is_zero_approx(attack.knockback) or _body == null:
		return
	if not _body.has_method(&"apply_knockback"):
		return

	var magnitude: float = attack.knockback
	if not result.staggered:
		# A hit that lands but fails to stagger only nudges. This is what makes
		# `stagger_threshold` visible without a single pixel of UI.
		magnitude *= config.flinch_knockback_mult

	var direction: float = signf((_body as Node2D).global_position.x - attack.origin.x)
	if is_zero_approx(direction):
		direction = 1.0
	_body.call(&"apply_knockback", Vector2(direction * magnitude, 0.0))


func _find_health() -> Health:
	var parent := get_parent()
	if parent == null:
		return null
	for child: Node in parent.get_children():
		if child is Health:
			return child as Health
	return null
