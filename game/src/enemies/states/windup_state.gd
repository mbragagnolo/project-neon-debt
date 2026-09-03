class_name EnemyWindupState
extends EnemyState
## The telegraph. Everything the Scav exists to teach starts here.
##
## It stops moving and turns the loudest colour on screen for `windup_time`.
## Both halves matter: the colour is the readable signal, and planting the feet
## is what makes the lunge's direction *committed* — the player can step around
## a lunge only because the Scav stopped choosing where to send it.
##
## A hit landing here interrupts into Stagger, which is the reward half of
## "bait the lunge, step in, punish".

var _remaining: float = 0.0


func enter(_previous: StringName) -> void:
	enemy.tint(enemy.config.color_windup)
	_remaining = enemy.config.windup_time
	# Aim once, at the start. Tracking the player through the windup would
	# delete the whole lesson: a lunge you cannot sidestep is not a telegraph,
	# it is a homing missile with a warning light.
	enemy.set_facing(enemy.direction_to_player())


func physics_update(delta: float) -> StringName:
	enemy.apply_gravity(delta)
	enemy.brake(delta)

	_remaining -= delta
	if _remaining > 0.0:
		return &""
	return &"Lunge"
