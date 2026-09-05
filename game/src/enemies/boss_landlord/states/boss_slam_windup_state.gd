class_name BossSlamWindupState
extends EnemyState
## The telegraph for the shockwave: crouched, lit, still.
##
## Long enough to read (0.7s against the Scav's 0.48) because the answer —
## get off the floor — takes a moment to act on. A hit landing here that
## meets the threshold interrupts it, like any windup.

var _remaining: float = 0.0


func enter(_previous: StringName) -> void:
	enemy.tint(enemy.config.color_windup)
	_remaining = (enemy as Landlord).slam_windup
	enemy.set_facing(enemy.direction_to_player())
	enemy.visual.scale = Vector2(1.15, 0.85)


func exit() -> void:
	enemy.visual.scale = Vector2.ONE


func physics_update(delta: float) -> StringName:
	enemy.apply_gravity(delta)
	enemy.brake(delta)
	_remaining -= delta
	if _remaining > 0.0:
		return &""
	(enemy as Landlord).slam()
	Events.camera_shake_requested.emit(6.0, 0.25)
	return &"Recover"
