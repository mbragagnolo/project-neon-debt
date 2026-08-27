class_name PlayerWallSlideState
extends PlayerState
## Clinging to a wall, descending at a capped speed.
##
## The stick timer is what stops a wall slide from punishing the player for
## flicking the stick away to line up a wall jump: letting go does not drop you
## for `wall_stick_time` seconds.

var _stick_remaining: float = 0.0


func enter(_previous: StringName) -> void:
	_stick_remaining = player.config.wall_stick_time
	# Back to the wall, facing out — where a wall jump will send you.
	player.set_facing(-player.wall_direction())


func physics_update(delta: float) -> StringName:
	var wall: int = player.wall_direction()
	player.apply_wall_slide(delta)

	if player.wants_dash() and player.can_dash():
		return &"Dash"

	if player.has_buffered_jump() and wall != 0:
		player.start_wall_jump(wall)
		return &"Air"

	if player.is_on_floor():
		return &"Run" if player.input_direction != 0 else &"Idle"

	if wall == 0:
		return &"Air"

	if player.input_direction == wall:
		_stick_remaining = player.config.wall_stick_time
	else:
		_stick_remaining -= delta
		if _stick_remaining <= 0.0:
			return &"Air"

	return &""
