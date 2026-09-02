class_name EnemyState
extends Node
## Base class for one enemy behaviour state.
##
## Same contract as `PlayerState`: the state decides, the enemy acts. States
## call helpers on `enemy` rather than touching `velocity`, and
## `physics_update` *returns* the next state rather than switching directly, so
## transitions happen in one place and a test can call it and inspect the
## answer.

var enemy: Enemy


func setup(owning_enemy: Enemy) -> void:
	enemy = owning_enemy


## Called when this state becomes current.
func enter(_previous: StringName) -> void:
	pass


## Called when this state stops being current.
func exit() -> void:
	pass


## Return the name of the state to switch to, or `&""` to stay put.
func physics_update(_delta: float) -> StringName:
	return &""
