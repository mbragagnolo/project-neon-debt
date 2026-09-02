class_name PlayerMeleeAttackState
extends PlayerState
## The swing — the one attack that gets a state, because it is the one that
## costs commitment (DESIGN.md §3.2: anim lock ~0.2s max).
##
## Ranged deliberately has no state: a shot costs a cooldown, not a commitment,
## so it stays legal from every other state and the nailgun's 4/s fire rate
## never becomes a state-machine problem.
##
## Momentum is preserved rather than zeroed. Locking the horizontal axis is
## what makes the swing a commitment; *stopping* the player would make it a
## punishment, and swinging while running is the whole reason to swing.

var _remaining: float = 0.0
var _active_remaining: float = 0.0


func enter(_previous: StringName) -> void:
	# Facing is fixed at the moment of the swing. A hitbox that follows a turn
	# mid-swing would let the player cover both sides with one press.
	player.set_facing(player.input_direction)
	player.start_melee()
	_remaining = player.melee_weapon.commit_time
	_active_remaining = player.melee_weapon.active_time


func exit() -> void:
	player.end_melee()


func physics_update(delta: float) -> StringName:
	player.apply_gravity(delta)

	# The box is armed for less time than the swing lasts, so the tail is
	# recovery the player can be punished during — the same shape the Scav's
	# overcommit teaches them to look for.
	_active_remaining -= delta
	if _active_remaining <= 0.0 and player.melee_hitbox.is_active():
		player.melee_hitbox.deactivate()

	_remaining -= delta
	if _remaining > 0.0:
		return &""

	if not player.is_on_floor():
		return &"Air"
	return &"Run" if player.input_direction != 0 else &"Idle"
