class_name BossBeamWindupState
extends EnemyState
## The repo beam's telegraph (phase two): a line from his deck to where you
## are, held for `fire_windup`, then a fast shot along it.
##
## The line is the tell and the trap: it tracks you while it is drawn, and
## the shot goes where you were when it stopped. Move late and you are hit;
## move at all and you are not. Dash is the clean answer.

var _remaining: float = 0.0
var _line: Line2D


func enter(_previous: StringName) -> void:
	enemy.tint(enemy.config.color_windup)
	_remaining = enemy.config.fire_windup
	_line = Line2D.new()
	_line.width = 3.0
	_line.default_color = Color(0.35, 0.85, 1.0, 0.7)
	_line.z_index = 15
	enemy.add_child(_line)


func exit() -> void:
	if _line != null:
		_line.queue_free()
		_line = null


func physics_update(delta: float) -> StringName:
	enemy.apply_gravity(delta)
	enemy.brake(delta)
	enemy.set_facing(enemy.direction_to_player())
	if enemy.has_player() and _line != null:
		_line.points = PackedVector2Array([
			enemy.to_local(enemy.center()),
			enemy.to_local(enemy.player.global_position + Vector2(0.0, -44.0)),
		])
		_line.default_color.a = 0.4 + 0.6 * (1.0 - _remaining / enemy.config.fire_windup)
	_remaining -= delta
	if _remaining > 0.0:
		return &""
	enemy.fire_at_player()
	return &"Recover"
