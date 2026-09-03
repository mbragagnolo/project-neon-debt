class_name EnemyPatrolState
extends EnemyState
## Walking a short beat, waiting to notice you.
##
## The pause at each end is what makes a patrol read as a patrol rather than as
## pacing — and it is also the window in which a player can get close before
## being seen, which is the first thing the Scav teaches without saying so.

var _direction: int = 1
var _pause_timer: float = 0.0


func enter(_previous: StringName) -> void:
	enemy.tint(enemy.config.color_idle)
	# Head back toward the beat if a chase or a knockback left us outside it.
	var offset: float = enemy.global_position.x - enemy.home.x
	_direction = -signi(int(signf(offset))) if absf(offset) > enemy.config.patrol_range else _direction
	if _direction == 0:
		_direction = 1


func physics_update(delta: float) -> StringName:
	enemy.apply_gravity(delta)

	if enemy.has_player() and enemy.distance_to_player() <= enemy.config.detection_range:
		return &"Chase"

	if _pause_timer > 0.0:
		_pause_timer -= delta
		enemy.brake(delta)
		return &""

	# Turn at the end of the beat, and at anything solid in the way — a patrol
	# that walks into a wall forever is the oldest bug in the genre.
	var offset: float = enemy.global_position.x - enemy.home.x
	if absf(offset) >= enemy.config.patrol_range and signf(offset) == signf(float(_direction)):
		_turn()
		return &""
	if enemy.is_on_wall():
		_turn()
		return &""

	enemy.walk(_direction, enemy.config.patrol_speed)
	return &""


func _turn() -> void:
	_direction = -_direction
	_pause_timer = enemy.config.patrol_pause
	enemy.set_facing(_direction)
