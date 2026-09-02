class_name PlayerRunState
extends PlayerGroundState
## Moving along a floor. Held until the player has both let go and actually
## stopped, so the deceleration tail still reads as running.


func _grounded_transition() -> StringName:
	if player.input_direction == 0 and is_zero_approx(player.velocity.x):
		return &"Idle"
	return &""
