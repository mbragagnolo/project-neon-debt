class_name EnemyLungeState
extends EnemyState
## The commitment: a fixed burst along the facing chosen at windup, with the
## attack box armed at full `attack_power`.
##
## Gravity still applies, so a lunge off a ledge falls. That is deliberate — a
## Scav that flies horizontally off a platform is funny once and wrong every
## time after.

var _remaining: float = 0.0


func enter(_previous: StringName) -> void:
	enemy.tint(enemy.config.color_lunge)
	enemy.start_lunge()
	_remaining = enemy.config.lunge_time


func exit() -> void:
	enemy.end_lunge()


func physics_update(delta: float) -> StringName:
	enemy.apply_gravity(delta)

	_remaining -= delta
	if _remaining > 0.0:
		return &""
	return &"Recover"
