class_name EnemyRecoverState
extends EnemyState
## The overcommit — the punishable half, and the reason the Scav is the
## tutorial for spacing rather than just the first thing in the way.
##
## It is drained of colour on purpose: recovery should *look* like an opening,
## because it is one. M6's Elite Scav runs this exact state with
## `recover_time` cut to almost nothing, which is how "the tutorial answer
## stops working" is implemented — same silhouette, same moveset, one number.

var _remaining: float = 0.0


func enter(_previous: StringName) -> void:
	enemy.tint(enemy.config.color_recover)
	_remaining = enemy.config.recover_time


func exit() -> void:
	# Counted from the end of recovery rather than the start of the lunge, so
	# shortening the overcommit really does mean lunging again sooner.
	enemy.start_lunge_cooldown()


func physics_update(delta: float) -> StringName:
	enemy.apply_gravity(delta)
	enemy.brake(delta)

	_remaining -= delta
	if _remaining > 0.0:
		return &""

	if enemy.has_player() and enemy.distance_to_player() <= enemy.config.detection_range:
		return &"Chase"
	return &"Patrol"
