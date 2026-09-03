class_name EnemyStaggerState
extends EnemyState
## Interrupted. Entered from anywhere by `Health.staggered`, which fires when a
## single hit meets `stagger_threshold`.
##
## Bleeds the knockback off at `knockback_friction` rather than holding it.
##
## This started out frictionless, on the theory that letting the impulse carry
## makes a hit feel landed. In the hand it did the opposite: every other body in
## the game decays knockback, so a staggered enemy slid roughly three times
## further than the training dummy the numbers were tuned against, and the read
## was \"this weapon is absurdly overpowered\" rather than \"this enemy has no
## friction\". The impulse is still visible — it just stops travelling.
##
## `stagger_time` must stay under the player's fastest weapon cooldown, or
## melee becomes a stunlock and the spacing lesson evaporates — there is a test
## pinning exactly that.

var _remaining: float = 0.0


func enter(_previous: StringName) -> void:
	enemy.tint(enemy.config.color_stagger)
	# A hit landing mid-lunge has to disarm the attack, or an interrupted Scav
	# still hits you with a swing it never finished.
	enemy.end_lunge()
	_remaining = enemy.config.stagger_time


func physics_update(delta: float) -> StringName:
	enemy.apply_gravity(delta)
	enemy.brake(delta, enemy.config.knockback_friction)

	_remaining -= delta
	if _remaining > 0.0:
		return &""

	if enemy.has_player() and enemy.distance_to_player() <= enemy.config.detection_range:
		return &"Chase"
	return &"Patrol"
