class_name EnemyStunnedState
extends EnemyState
## Breached. Entered by `Enemy.stun()`, which only mechanical enemies answer
## (docs/combat/hacks.md - Breach "does nothing to humans: tags mean
## something").
##
## A stun is a setup verb's payoff, so it has to be *worth* the two RAM: the
## attack box and the contact box are both disarmed for the duration, and a
## hit landing here does **not** knock the enemy out of it - the base refuses
## the Stagger transition while stunned. Breach, walk in, swing freely is the
## whole loop, and a stun that ends on the first punch is a stun that teaches
## the player not to bother.
##
## Gravity still applies. That is deliberate and it is the drone's entire
## reaction: "Breach drops it out of the air for a beat" (enemies.md).

var _remaining: float = 0.0


func enter(_previous: StringName) -> void:
	enemy.tint(enemy.config.color_stunned)
	enemy.end_lunge()
	enemy.disarm_contact()
	_remaining = enemy.stun_duration


func exit() -> void:
	enemy.arm_contact()


func physics_update(delta: float) -> StringName:
	# Forced: a stunned flier drops.
	enemy.apply_gravity(delta, true)
	enemy.brake(delta, enemy.config.knockback_friction)

	_remaining -= delta
	if _remaining > 0.0:
		return &""
	return enemy.after_recover_state()
