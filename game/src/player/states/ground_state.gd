class_name PlayerGroundState
extends PlayerState
## Shared behaviour for the grounded states. Idle and Run differ only in what
## they transition to, so everything that makes standing on a floor work —
## jumping, dashing, falling off an edge — lives here once.


func physics_update(delta: float) -> StringName:
	player.apply_gravity(delta)
	player.apply_horizontal(delta, true)
	player.set_facing(player.input_direction)

	if player.has_buffered_jump() and player.can_jump():
		player.start_jump()
		return &"Air"

	if player.wants_melee() and player.can_melee():
		return &"MeleeAttack"

	if player.wants_dash() and player.can_dash():
		return &"Dash"

	if not player.is_on_floor():
		return &"Air"

	return _grounded_transition()


## What to become while still on the floor.
func _grounded_transition() -> StringName:
	return &""
