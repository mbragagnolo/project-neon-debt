extends GutTest
## Guards the input map (DESIGN.md §3.7: "controller + keyboard from day one").
##
## Every action the game will bind must exist, and must be reachable on both a
## keyboard and a gamepad. Deleting a binding in the editor breaks CI here
## instead of breaking a playtest.

const EXPECTED_ACTIONS := [
	"move_left", "move_right", "move_up", "move_down",
	"jump", "dash",
	"attack_melee", "attack_ranged",
	"hack_cast", "hack_next", "hack_prev",
	"interact", "pause", "toggle_map", "toggle_inventory",
]


func test_every_expected_action_exists() -> void:
	for action: String in EXPECTED_ACTIONS:
		assert_true(InputMap.has_action(action), "missing input action '%s'" % action)


func test_every_action_has_a_keyboard_binding() -> void:
	for action: String in EXPECTED_ACTIONS:
		if not InputMap.has_action(action):
			continue
		var has_key := false
		for event: InputEvent in InputMap.action_get_events(action):
			if event is InputEventKey:
				has_key = true
		assert_true(has_key, "action '%s' has no keyboard binding" % action)


func test_every_action_has_a_gamepad_binding() -> void:
	for action: String in EXPECTED_ACTIONS:
		if not InputMap.has_action(action):
			continue
		var has_pad := false
		for event: InputEvent in InputMap.action_get_events(action):
			if event is InputEventJoypadButton or event is InputEventJoypadMotion:
				has_pad = true
		assert_true(has_pad, "action '%s' has no gamepad binding" % action)


func test_movement_keys_are_physical_so_azerty_still_works() -> void:
	# WASD bound by keycode would strand AZERTY/Dvorak players on ZQSD.
	for action: String in ["move_left", "move_right", "move_up", "move_down"]:
		for event: InputEvent in InputMap.action_get_events(action):
			if event is InputEventKey:
				assert_ne(
					(event as InputEventKey).physical_keycode, 0,
					"'%s' has a key event bound by keycode instead of physical_keycode" % action
				)
