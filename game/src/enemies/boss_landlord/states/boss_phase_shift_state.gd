class_name BossPhaseShiftState
extends EnemyState
## Half health: he stops, calls VESTA support, and comes back faster.
##
## Invulnerable for the beat (i-frames, so the pipeline rejects hits at
## step 3 rather than a special case), and the two drones arrive halfway
## through — the thing Breach is for, in a fight that otherwise has no
## machines in it.

var _remaining: float = 0.0
var _summoned: bool = false


func enter(_previous: StringName) -> void:
	var landlord: Landlord = enemy as Landlord
	enemy.tint(enemy.config.color_stagger)
	enemy.end_lunge()
	_remaining = landlord.phase_shift_time
	_summoned = false
	enemy.health.grant_iframes(landlord.phase_shift_time)
	Events.toast_requested.emit("THE LANDLORD: \"%s SUPPORT. TO ME.\"" % Lines.CORP)
	Events.camera_shake_requested.emit(8.0, 0.4)


func physics_update(delta: float) -> StringName:
	var landlord: Landlord = enemy as Landlord
	enemy.apply_gravity(delta)
	enemy.brake(delta)
	_remaining -= delta
	if not _summoned and _remaining <= landlord.phase_shift_time * 0.5:
		_summoned = true
		landlord.summon_drones()
	if _remaining > 0.0:
		return &""
	return &"Approach"
