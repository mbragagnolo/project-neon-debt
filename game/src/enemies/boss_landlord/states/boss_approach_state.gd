class_name BossApproachState
extends EnemyState
## The Landlord closing in, picking his next move by distance.
##
## His Chase. No leash and no giving up: the arena is locked, and a boss
## that wanders back to a patrol beat is a boss the player can ignore.

func enter(_previous: StringName) -> void:
	enemy.tint(enemy.config.color_chase)


func physics_update(delta: float) -> StringName:
	enemy.apply_gravity(delta)
	if not enemy.has_player():
		enemy.brake(delta)
		return &""

	var landlord: Landlord = enemy as Landlord
	if landlord.can_attack():
		var next: StringName = landlord.pick_attack()
		if next != &"":
			return next

	var direction: int = enemy.direction_to_player()
	# Do not crowd: hold a little short of baton range so the swing is a
	# decision, not a collision.
	if direction == 0 or enemy.distance_to_player() < enemy.config.lunge_range * 0.6:
		enemy.brake(delta)
		enemy.set_facing(direction)
		enemy.play(&"idle")
		return &""
	enemy.walk(direction, landlord.approach_speed())
	enemy.play(&"run")
	return &""
