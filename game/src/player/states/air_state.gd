class_name PlayerAirState
extends PlayerState
## Airborne: rising, falling, and everything in between.
##
## Deliberately one state rather than separate Jump and Fall states. The
## transition between rising and falling is the moment a platformer feels
## worst if it stutters, and there is nothing to switch on — the gravity
## already differs by sign of velocity, and the jump cut only applies while
## rising.


func physics_update(delta: float) -> StringName:
	player.apply_gravity(delta)
	player.apply_horizontal(delta, false)
	if not player.horizontal_locked():
		# Mid wall-kick the facing belongs to the kick, not to the stick.
		player.set_facing(player.input_direction)

	if player.wants_jump_cut():
		player.cut_jump()

	if player.wants_melee() and player.can_melee():
		return &"MeleeAttack"

	if player.wants_dash() and player.can_dash():
		return &"Dash"

	if player.has_buffered_jump():
		if player.can_jump():
			# Still inside the coyote window — an ordinary jump, late.
			player.start_jump()
		else:
			var wall: int = player.wall_direction()
			if wall != 0:
				player.start_wall_jump(wall)

	if player.is_on_floor():
		return &"Run" if player.input_direction != 0 else &"Idle"

	if _should_wall_slide():
		return &"WallSlide"

	return &""


func _should_wall_slide() -> bool:
	var wall: int = player.wall_direction()
	# Requires holding *into* the wall: brushing one on the way past should
	# never grab it.
	return wall != 0 and wall == player.input_direction and player.velocity.y > 0.0
