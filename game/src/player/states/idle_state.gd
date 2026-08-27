class_name PlayerIdleState
extends PlayerGroundState
## Standing still on a floor.


func _grounded_transition() -> StringName:
	if player.input_direction != 0:
		return &"Run"
	return &""
