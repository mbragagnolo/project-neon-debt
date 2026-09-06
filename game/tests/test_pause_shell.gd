extends GutTest
## The pause shell and its tabs (docs/ui/screens.md, M5).

var _shell: PauseShell


func before_each() -> void:
	GameState.reset()
	Quests.reset()
	Inventory.reset()
	PlayerStats.reset()
	_shell = PauseShell.new()
	add_child_autofree(_shell)


func after_each() -> void:
	_shell.close()
	get_tree().paused = false
	GameState.reset()
	Quests.reset()


func _press(action: StringName) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = true
	_shell._input(event)


func test_the_system_tab_is_the_last_stop_on_the_cycle() -> void:
	_press(&"pause")
	_press(&"hack_prev")
	assert_eq(_shell.current_tab(), PauseShell.Tab.SYSTEM)
	var system: Node = _shell.get_node("System")
	assert_true(system is SystemTab)
	assert_true(system.visible)
	_press(&"hack_next")
	assert_eq(_shell.current_tab(), PauseShell.Tab.MAP)


func test_pause_opens_on_the_map_and_pauses_the_tree() -> void:
	assert_false(_shell.is_open())
	_press(&"pause")
	assert_true(_shell.is_open())
	assert_eq(_shell.current_tab(), PauseShell.Tab.MAP)
	assert_true(get_tree().paused)
	_press(&"pause")
	assert_false(_shell.is_open())
	assert_false(get_tree().paused)


func test_the_loadout_key_opens_its_tab_directly_and_closes_from_it() -> void:
	_press(&"toggle_inventory")
	assert_true(_shell.is_open())
	assert_eq(_shell.current_tab(), PauseShell.Tab.LOADOUT)
	_press(&"toggle_inventory")
	assert_false(_shell.is_open(), "the key that opened the tab should close it")


func test_the_map_key_switches_tabs_when_already_open() -> void:
	_press(&"toggle_inventory")
	_press(&"toggle_map")
	assert_true(_shell.is_open())
	assert_eq(_shell.current_tab(), PauseShell.Tab.MAP)


func test_the_shoulder_keys_cycle_the_tabs() -> void:
	_press(&"pause")
	_press(&"hack_next")
	assert_eq(_shell.current_tab(), PauseShell.Tab.LOADOUT)
	_press(&"hack_next")
	assert_eq(_shell.current_tab(), PauseShell.Tab.QUESTS)
	_press(&"hack_next")
	assert_eq(_shell.current_tab(), PauseShell.Tab.SYSTEM)
	_press(&"hack_next")
	assert_eq(_shell.current_tab(), PauseShell.Tab.MAP, "did not wrap")
	_press(&"hack_prev")
	assert_eq(_shell.current_tab(), PauseShell.Tab.SYSTEM)
	_press(&"hack_prev")
	assert_eq(_shell.current_tab(), PauseShell.Tab.QUESTS)


func test_the_embedded_loadout_does_not_own_the_pause() -> void:
	# The shell pauses; the tab must not fight it on close.
	var loadout: Node = _shell.get_node("Loadout")
	assert_false(bool(loadout.get("standalone")))
	_press(&"toggle_inventory")
	assert_true(loadout.visible)
	_press(&"pause")
	assert_false(get_tree().paused)


func test_only_one_tab_is_visible_at_a_time() -> void:
	_press(&"pause")
	_press(&"hack_next")
	var visible: int = 0
	for tab_name: String in ["Map", "Loadout", "Quests"]:
		if (_shell.get_node(tab_name) as CanvasLayer).visible:
			visible += 1
	assert_eq(visible, 1)


func test_the_map_knows_the_district_and_where_you_are() -> void:
	var map: MapScreen = _shell.get_node("Map")
	assert_gte(map.graph.rooms.size(), 25, "the map has no district")
	Events.room_entered.emit(&"mezz")
	assert_eq(map.current_room, &"mezz")


func test_the_quest_log_lists_what_has_been_asked() -> void:
	var log: QuestLog = _shell.get_node("Quests")
	_press(&"pause")
	_press(&"hack_prev")
	_press(&"hack_prev")
	assert_eq(_shell.current_tab(), PauseShell.Tab.QUESTS)
	var rows: VBoxContainer = log._rows
	assert_eq(rows.get_child_count(), 1, "an empty log is one line")
	Quests.start(Quests.MEMORY_CHIP)
	log.open()
	assert_gt(rows.get_child_count(), 2, "the active quest is not listed")


func test_a_dialogue_holding_the_tree_keeps_the_shell_shut() -> void:
	get_tree().paused = true
	_press(&"pause")
	assert_false(_shell.is_open(), "the shell opened over another screen")
	get_tree().paused = false
