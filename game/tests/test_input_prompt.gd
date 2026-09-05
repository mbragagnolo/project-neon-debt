extends GutTest
## Prompts must name the key that is actually bound (#4).
##
## M3 shipped four prompt strings saying "[E] take" and "[I] close" while the
## input map bound F and Tab. Nothing errored: E fires `hack_next`, which no
## code reads until M4, and I is bound to nothing — so the only symptom was a
## player pressing a button that did nothing.
##
## The expected key is derived here independently of whatever production uses,
## so this stays a real assertion rather than a tautology.

const INPUT_PROMPT_PATH := "res://src/core/input_prompt.gd"


## The first keyboard binding on `action`, as the player would name it.
func _bound_key(action: StringName) -> String:
	for event: InputEvent in InputMap.action_get_events(action):
		if event is InputEventKey:
			var key: InputEventKey = event
			return OS.get_keycode_string(
				key.physical_keycode if key.physical_keycode != 0 else key.keycode
			)
	return ""


func test_the_helper_reports_the_bound_key() -> void:
	var script: GDScript = load(INPUT_PROMPT_PATH)
	assert_not_null(script, "no InputPrompt helper — prompts still hardcode their keys")
	if script == null:
		return
	assert_eq(script.key(&"interact"), _bound_key(&"interact"))
	assert_eq(script.key(&"toggle_inventory"), _bound_key(&"toggle_inventory"))


func test_the_helper_brackets_the_key_for_display() -> void:
	var script: GDScript = load(INPUT_PROMPT_PATH)
	if script == null:
		return
	assert_eq(script.label(&"interact"), "[%s]" % _bound_key(&"interact").to_upper())


func test_an_unbound_action_degrades_instead_of_crashing() -> void:
	# A prompt for an action nobody bound is a bug, but a crash in a label is
	# worse than a visibly empty one.
	var script: GDScript = load(INPUT_PROMPT_PATH)
	if script == null:
		return
	assert_eq(script.key(&"no_such_action"), "")
