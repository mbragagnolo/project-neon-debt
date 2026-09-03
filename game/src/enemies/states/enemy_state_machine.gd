class_name EnemyStateMachine
extends Node
## Owns the current behaviour state and performs transitions.
##
## States are child nodes and a state's node name *is* its id (`Patrol`,
## `Chase`, `Windup`, `Lunge`, `Recover`, `Stagger`, `Dead`). Giving an enemy a
## new behaviour is adding a child; giving it *fewer* behaviours — a turret
## that never patrols — is removing one, with no registration list to keep in
## sync either way.

@export var initial_state: StringName = &"Patrol"

var _enemy: Enemy
var _states: Dictionary = {}
var _current: EnemyState
var _current_name: StringName = &""


func setup(enemy: Enemy) -> void:
	_enemy = enemy
	for child: Node in get_children():
		if child is EnemyState:
			_states[child.name] = child
			(child as EnemyState).setup(enemy)
		else:
			push_warning("'%s' under StateMachine is not an EnemyState." % child.name)

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
	if _current == null:
		return
	# Death is terminal. Without this, a projectile landing on a corpse during
	# its fade would walk it back into Stagger and then into Patrol.
	if _current_name == &"Dead":
		return
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
