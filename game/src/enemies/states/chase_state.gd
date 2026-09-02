class_name EnemyChaseState
extends EnemyState
## Closing the distance, looking for a lunge.
##
## Gives up on distance from *home* rather than from the player: leashing to
## the spawn point keeps an enemy inside the encounter it was placed for, and
## stops one Scav dragging the whole district behind the player.

func enter(_previous: StringName) -> void:
	enemy.tint(enemy.config.color_chase)


func physics_update(delta: float) -> StringName:
	enemy.apply_gravity(delta)

	if not enemy.has_player():
		return &"Patrol"
	if enemy.distance_from_home() > enemy.config.give_up_range:
		return &"Patrol"
	if enemy.distance_to_player() > enemy.config.detection_range:
		return &"Patrol"

	if enemy.distance_to_player() <= enemy.config.lunge_range and enemy.can_lunge():
		return &"Windup"

	var direction: int = enemy.direction_to_player()
	if direction == 0:
		enemy.brake(delta)
		return &""

	enemy.walk(direction, enemy.config.chase_speed)
	return &""
