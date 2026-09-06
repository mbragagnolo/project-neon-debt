class_name EnemyDeadState
extends EnemyState
## Terminal. The state machine refuses every transition out of here, so a
## stray projectile landing on a corpse mid-fade cannot walk it back into
## Stagger and then into Patrol.
##
## Rewards were already emitted on the death event by the base — this state
## only handles getting off the screen.

var _remaining: float = 0.0


func enter(_previous: StringName) -> void:
	_remaining = enemy.config.death_time
	enemy.velocity.x = 0.0
	enemy.play(&"dead")
	enemy.visual.modulate = Color(0.6, 0.6, 0.6, 0.55)


func physics_update(delta: float) -> StringName:
	# Forced: a dead flier falls.
	enemy.apply_gravity(delta, true)
	enemy.brake(delta)

	_remaining -= delta
	if _remaining <= 0.0:
		enemy.queue_free()
	return &""
