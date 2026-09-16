class_name EnemyAimState
extends EnemyState
## The telegraph for a shot: still and lit for `fire_windup`, then the shot.
##
## Same shape as the Scav's Windup — the loudest colour on screen, and the
## body stops choosing. The shot is aimed at where the player is at the
## *end* of the windup, so a player who moves during the tell is not
## tracked; a player who stands still is hit. That is the whole lesson.
##
## A hit landing here interrupts into Stagger like any windup.

var _remaining: float = 0.0


func enter(_previous: StringName) -> void:
	enemy.tint(enemy.config.color_windup)
	enemy.play(&"aim")
	_remaining = enemy.config.fire_windup


func physics_update(delta: float) -> StringName:
	enemy.velocity = enemy.velocity.move_toward(Vector2.ZERO, enemy.config.fly_acceleration * delta)
	enemy.set_facing(enemy.direction_to_player())
	_remaining -= delta
	if _remaining > 0.0:
		return &""
	enemy.fire_at_player()
	return &"Track" if enemy.config.flies else enemy.after_recover_state()
