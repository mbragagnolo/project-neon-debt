class_name PlayerStateMachine
extends Node
## Owns the current movement state and performs transitions.
##
## States are child nodes; a state's node name *is* its id (`Idle`, `Run`,
## `Air`, `Dash`, `WallSlide`). Adding a state is adding a child — no
## registration list to keep in sync.

## Node name of the state to start in.
@export var initial_state: StringName = &"Idle"

var _player: Player
var _states: Dictionary = {}
var _current: PlayerState
var _current_name: StringName = &""


func setup(player: Player) -> void:
	_player = player
	for child: Node in get_children():
		if child is PlayerState:
			_states[child.name] = child
			(child as PlayerState).setup(player)
		else:
			push_warning("'%s' under StateMachine is not a PlayerState." % child.name)

	if not _states.has(initial_state):
		push_error("StateMachine has no state named '%s'." % initial_state)
		return
	_current_name = initial_state
	_current = _states[initial_state]
	_current.enter(&"")


func physics_update(delta: float) -> void:
	if _current == null:
		return
	var next: StringName = _current.physics_update(delta)
	if next != &"":
		transition_to(next)


func transition_to(next_name: StringName) -> void:
	if not _states.has(next_name):
		push_error("No state named '%s'." % next_name)
		return
	if next_name == _current_name:
		return
	var previous: StringName = _current_name
	_current.exit()
	_current_name = next_name
	_current = _states[next_name]
	_current.enter(previous)


func current_state_name() -> StringName:
	return _current_name
