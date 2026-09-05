class_name InputPrompt
extends RefCounted
## The key a prompt should tell the player to press.
##
## Exists because M3 shipped four prompt strings naming E and I while the input
## map bound F and Tab (#4). A key name typed into a label is a second source of
## truth for a fact `InputMap` already owns, and it drifts silently: the wrong
## key produces no error and no log line, just a player pressing a button that
## does nothing.
##
## Static-only and node-free, so a prompt can ask for its key before it is in
## the tree — and so this runs headless.


## The first keyboard binding on `action`, as the player would name it, or ""
## if the action does not exist or has no key. A prompt for an unbound action is
## a bug, but an empty label is a better failure than a crash inside a `Label`.
static func key(action: StringName) -> String:
	if not InputMap.has_action(action):
		return ""
	for event: InputEvent in InputMap.action_get_events(action):
		if event is InputEventKey:
			var bound: InputEventKey = event
			# Movement is bound physically so AZERTY still works
			# (tests/test_input_map.gd); read that first and fall back for any
			# action bound the other way.
			var code: Key = (
				bound.physical_keycode if bound.physical_keycode != KEY_NONE
				else bound.keycode
			)
			return OS.get_keycode_string(code)
	return ""


## The same key, bracketed the way every prompt in the game writes it.
static func label(action: StringName) -> String:
	return "[%s]" % key(action).to_upper()
