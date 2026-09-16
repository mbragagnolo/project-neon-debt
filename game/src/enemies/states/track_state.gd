class_name EnemyTrackState
extends EnemyState
## A flier holding station above and beside the player, waiting to shoot.
##
## The flier's Chase. It keeps `hover_height` above the player's centre and
## `hover_standoff` to one side — the side it is already on, so it does not
## cross over the player's head every time they turn. Above melee reach on
## purpose: the drone is the enemy the ranged verb is taught with
## (enemies.md), and the answer to it is to aim up.

var _side: int = 1


func enter(_previous: StringName) -> void:
	enemy.tint(enemy.config.color_chase)
	enemy.play(&"hover")
	_side = -enemy.direction_to_player()
	if _side == 0:
		_side = 1


func physics_update(delta: float) -> StringName:
	if not enemy.has_player():
		return &"Hover"
	if enemy.distance_from_home() > enemy.config.give_up_range:
		return &"Hover"
	if enemy.distance_to_player() > enemy.config.detection_range:
		return &"Hover"

	var player_centre: Vector2 = enemy.player.global_position + Vector2(0.0, -44.0)
	var station: Vector2 = player_centre + Vector2(float(_side) * enemy.config.hover_standoff, -enemy.config.hover_height)
	enemy.fly_toward(station, enemy.config.fly_speed, delta)
	# Face the player, not the way of travel: the shot comes from the front.
	enemy.set_facing(enemy.direction_to_player())

	if enemy.can_fire() and enemy.distance_to_player() <= enemy.config.fire_range:
		return &"Aim"
	return &""
