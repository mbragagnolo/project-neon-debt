class_name PlayerState
extends Node
## Base class for one movement state.
##
## A state decides; the player acts. States call the helpers on `player` rather
## than touching `velocity` directly, so the physics stays in one file and the
## states stay readable as intent.
##
## `physics_update` *returns* the next state instead of switching directly. That
## keeps transitions in one place, makes an accidental mid-frame double
## transition impossible, and lets a test call it and inspect the answer.

var player: Player


func setup(owning_player: Player) -> void:
	player = owning_player


## Called when this state becomes current.
func enter(_previous: StringName) -> void:
	pass


## Called when this state stops being current.
func exit() -> void:
	pass


## Return the name of the state to switch to, or `&""` to stay put.
func physics_update(_delta: float) -> StringName:
	return &""
