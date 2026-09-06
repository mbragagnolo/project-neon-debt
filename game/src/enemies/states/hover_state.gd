class_name EnemyHoverState
extends EnemyState
## A flier idling near home, bobbing, waiting to notice you.
##
## The flier's Patrol. It drifts in a slow loop around where it spawned so it
## reads as alive, and it never leaves that loop until the player is inside
## detection range.

var _phase: float = 0.0


func enter(_previous: StringName) -> void:
	enemy.tint(enemy.config.color_idle)
	enemy.play(&"hover")
	_phase = randf() * TAU


func physics_update(delta: float) -> StringName:
	if enemy.has_player() and enemy.distance_to_player() <= enemy.config.detection_range:
		return &"Track"
	_phase += delta * 1.6
	var target: Vector2 = enemy.home + Vector2(cos(_phase), sin(_phase * 2.0) * 0.5) * enemy.config.drift_radius
	enemy.fly_toward(target, enemy.config.fly_speed * 0.5, delta)
	return &""
