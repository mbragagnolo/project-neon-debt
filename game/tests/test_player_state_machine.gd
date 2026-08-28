extends GutTest
## The state machine's own contract, tested without physics.
##
## The movement tests cover what the states *do*; this covers the machine that
## runs them — mainly that a bad transition is loud rather than silent, because
## a typo'd state name that quietly does nothing is the kind of bug that reads
## as "the dash feels unreliable" three milestones later.

const MachineScript := preload("res://src/player/states/state_machine.gd")


class RecordingState:
	extends PlayerState

	var entered_from: Array[StringName] = []
	var exits: int = 0
	var next: StringName = &""

	func enter(previous: StringName) -> void:
		entered_from.append(previous)

	func exit() -> void:
		exits += 1

	func physics_update(_delta: float) -> StringName:
		return next


var _machine: PlayerStateMachine
var _alpha: RecordingState
var _beta: RecordingState


func before_each() -> void:
	_machine = MachineScript.new()
	_alpha = RecordingState.new()
	_alpha.name = "Alpha"
	_beta = RecordingState.new()
	_beta.name = "Beta"
	_machine.add_child(_alpha)
	_machine.add_child(_beta)
	_machine.initial_state = &"Alpha"
	add_child_autofree(_machine)


func test_starts_in_the_initial_state() -> void:
	_machine.setup(null)
	assert_eq(_machine.current_state_name(), &"Alpha")
	assert_eq(_alpha.entered_from, [&""] as Array[StringName],
		"the first state should be entered with no previous state")


func test_a_state_returning_a_name_transitions_to_it() -> void:
	_machine.setup(null)
	_alpha.next = &"Beta"
	_machine.physics_update(0.016)
	assert_eq(_machine.current_state_name(), &"Beta")
	assert_eq(_alpha.exits, 1, "the old state should be exited exactly once")
	assert_eq(_beta.entered_from, [&"Alpha"] as Array[StringName],
		"the new state should be told where it came from")


func test_returning_empty_stays_put() -> void:
	_machine.setup(null)
	_alpha.next = &""
	_machine.physics_update(0.016)
	_machine.physics_update(0.016)
	assert_eq(_machine.current_state_name(), &"Alpha")
	assert_eq(_alpha.exits, 0)


func test_transitioning_to_the_current_state_is_a_no_op() -> void:
	_machine.setup(null)
	_machine.transition_to(&"Alpha")
	assert_eq(_alpha.exits, 0, "re-entering the current state would reset its timers")
	assert_eq(_alpha.entered_from.size(), 1)


func test_an_unknown_state_name_is_an_error_not_a_silent_no_op() -> void:
	_machine.setup(null)
	_machine.transition_to(&"Nonexistent")
	assert_eq(_machine.current_state_name(), &"Alpha", "should stay put")
	assert_push_error("No state named", "the bad name is reported, not swallowed")


func test_states_are_registered_by_node_name() -> void:
	_machine.setup(null)
	_machine.transition_to(&"Beta")
	assert_eq(_machine.current_state_name(), &"Beta")
	_machine.transition_to(&"Alpha")
	assert_eq(_machine.current_state_name(), &"Alpha")
	assert_eq(_alpha.entered_from, [&"", &"Beta"] as Array[StringName])
