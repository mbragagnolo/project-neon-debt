class_name EnemyStaggerState
extends EnemyState
## Interrupted. Entered from anywhere by `Health.staggered`, which fires when a
## single hit meets `stagger_threshold`.
##
## Deliberately does not brake: the knockback impulse the pipeline just applied
## is allowed to carry the body, because being visibly moved is most of what
## makes a hit feel landed.
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

	_remaining -= delta
	if _remaining > 0.0:
		return &""

	if enemy.has_player() and enemy.distance_to_player() <= enemy.config.detection_range:
		return &"Chase"
	return &"Patrol"
