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


## The first pad binding on `action`, named the way the buttons are printed
## on the common pads, or "" if there is none. The settings screen lists it
## beside the key (M7).
static func pad(action: StringName) -> String:
	if not InputMap.has_action(action):
		return ""
	for event: InputEvent in InputMap.action_get_events(action):
		if event is InputEventJoypadButton:
			return _button_name((event as InputEventJoypadButton).button_index)
		if event is InputEventJoypadMotion:
			var motion: InputEventJoypadMotion = event
			var stick: String = "LS" if motion.axis <= JOY_AXIS_LEFT_Y else ("RS" if motion.axis <= JOY_AXIS_RIGHT_Y else ("LT" if motion.axis == JOY_AXIS_TRIGGER_LEFT else "RT"))
			if motion.axis == JOY_AXIS_LEFT_X or motion.axis == JOY_AXIS_RIGHT_X:
				return "%s %s" % [stick, "→" if motion.axis_value > 0.0 else "←"]
			if motion.axis == JOY_AXIS_LEFT_Y or motion.axis == JOY_AXIS_RIGHT_Y:
				return "%s %s" % [stick, "↓" if motion.axis_value > 0.0 else "↑"]
			return stick
	return ""


static func _button_name(button: JoyButton) -> String:
	match button:
		JOY_BUTTON_A: return "A"
		JOY_BUTTON_B: return "B"
		JOY_BUTTON_X: return "X"
		JOY_BUTTON_Y: return "Y"
		JOY_BUTTON_LEFT_SHOULDER: return "LB"
		JOY_BUTTON_RIGHT_SHOULDER: return "RB"
		JOY_BUTTON_LEFT_STICK: return "L3"
		JOY_BUTTON_RIGHT_STICK: return "R3"
		JOY_BUTTON_START: return "START"
		JOY_BUTTON_BACK: return "SELECT"
		JOY_BUTTON_DPAD_UP: return "D-PAD ↑"
		JOY_BUTTON_DPAD_DOWN: return "D-PAD ↓"
		JOY_BUTTON_DPAD_LEFT: return "D-PAD ←"
		JOY_BUTTON_DPAD_RIGHT: return "D-PAD →"
	return "BTN %d" % button
