extends GutTest
## The title screen (M7): CONTINUE appears only with a save, a new run over
## a save asks twice, and picking a slot loads or resets the state.
##
## Slots are real files under user://, so whatever was there is put back.

const TEST_SLOT := 2

var _backup: Dictionary = {}
var _had_backup: bool = false
var _slot_before: int = 0


func before_each() -> void:
	_slot_before = GameState.active_slot
	_had_backup = SaveLoad.has_save(TEST_SLOT)
	_backup = SaveLoad.load_from_slot(TEST_SLOT) if _had_backup else {}
	SaveLoad.delete_slot(TEST_SLOT)
	GameState.reset()
	Quests.reset()
	Inventory.reset()
	PlayerStats.reset()


func after_each() -> void:
	SaveLoad.delete_slot(TEST_SLOT)
	if _had_backup:
		SaveLoad.save_to_slot(TEST_SLOT, _backup)
	GameState.active_slot = _slot_before
	GameState.reset()
	Quests.reset()
	Music.reset()


func _title() -> TitleScreen:
	var title := TitleScreen.new()
	add_child_autofree(title)
	return title


func _write_save(flag: StringName) -> void:
	GameState.reset()
	GameState.set_flag(flag)
	GameState.current_save_point = &"hall_13"
	GameState.play_time = 65.0
	PlayerStats.credits = 140
	SaveLoad.save_to_slot(TEST_SLOT, GameState.snapshot())
	GameState.reset()
	PlayerStats.reset()


func _saves_elsewhere() -> bool:
	for slot: int in SaveLoad.SLOT_COUNT:
		if slot != TEST_SLOT and SaveLoad.has_save(slot):
			return true
	return false


func test_continue_is_offered_only_with_a_save() -> void:
	if _saves_elsewhere():
		pass_test("another slot holds a save on this machine; skipping the empty case")
		return
	var title: TitleScreen = _title()
	assert_false(&"continue" in title._entries)
	_write_save(&"test.flag")
	title._show_main()
	assert_eq(title._entries[0], &"continue")


func test_the_summary_reads_the_save() -> void:
	var title: TitleScreen = _title()
	assert_eq(title.summary({}), "— EMPTY —")
	_write_save(&"test.flag")
	var text: String = title.summary(SaveLoad.load_from_slot(TEST_SLOT))
	assert_string_contains(text, "LVL 1")
	assert_string_contains(text, "FLOOR 13")
	assert_string_contains(text, "1:05")
	assert_string_contains(text, "140 cr")


func test_continue_loads_the_slot() -> void:
	_write_save(&"test.flag")
	var title: TitleScreen = _title()
	title.fresh_run = false
	title.pick_slot(TEST_SLOT)
	assert_true(GameState.has_flag(&"test.flag"))
	assert_eq(GameState.active_slot, TEST_SLOT)
	assert_eq(GameState.current_save_point, &"hall_13")
	await wait_seconds(1.0)


func test_continue_on_an_empty_slot_does_nothing() -> void:
	var title: TitleScreen = _title()
	title.fresh_run = false
	GameState.set_flag(&"still.here")
	title.pick_slot(TEST_SLOT)
	assert_true(GameState.has_flag(&"still.here"))


func test_a_new_run_over_a_save_asks_twice_then_wipes_it() -> void:
	_write_save(&"test.flag")
	var title: TitleScreen = _title()
	title.fresh_run = true
	title.pick_slot(TEST_SLOT)
	assert_true(SaveLoad.has_save(TEST_SLOT), "first press only asks")
	assert_eq(title._confirm_slot, TEST_SLOT)
	title.pick_slot(TEST_SLOT)
	assert_false(SaveLoad.has_save(TEST_SLOT))
	assert_false(GameState.has_flag(&"test.flag"))
	assert_eq(GameState.current_save_point, &"", "a fresh run wakes in 14-C")
	await wait_seconds(1.0)


func test_the_menu_walks_on_the_movement_keys() -> void:
	var title: TitleScreen = _title()
	var count: int = title._entries.size()
	title._input(_action(&"move_down"))
	assert_eq(title.menu_index, 1 % count)
	title._input(_action(&"move_up"))
	assert_eq(title.menu_index, 0)
	title.activate(&"settings")
	assert_eq(title.page, TitleScreen.Page.SETTINGS)
	title._input(_action(&"pause"))
	assert_eq(title.page, TitleScreen.Page.MAIN)


func test_the_title_plays_its_track() -> void:
	_title()
	assert_eq(Music.current, &"title")


func _action(name: StringName) -> InputEventAction:
	var event := InputEventAction.new()
	event.action = name
	event.pressed = true
	return event
