class_name PlayerDashState
extends PlayerState
## A fixed-distance burst with gravity suspended (DESIGN.md §3.1).
##
## There is no jump cancel here on purpose: a jump pressed mid-dash is caught by
## the jump buffer and fires the instant the dash ends, which gives dash-jump
## for free without letting a 0.16s commitment be wriggled out of.

var _remaining: float = 0.0


func enter(_previous: StringName) -> void:
	player.set_facing(player.input_direction)
	player.start_dash()
	_remaining = player.config.dash_duration


func exit() -> void:
	player.end_dash()


func physics_update(delta: float) -> StringName:
	_remaining -= delta
	if _remaining > 0.0:
		return &""
	if player.is_on_floor():
		return &"Run" if player.input_direction != 0 else &"Idle"
	return &"Air"
