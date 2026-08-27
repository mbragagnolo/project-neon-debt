extends GutTest
## A corrupt or missing save must degrade to "fresh run", never to a crash.

const GameStateScript := preload("res://src/core/game_state.gd")
const SLOT := 0


func before_each() -> void:
	SaveLoad.delete_slot(SLOT)


func after_each() -> void:
	SaveLoad.delete_slot(SLOT)


func test_no_save_reports_missing() -> void:
	assert_false(SaveLoad.has_save(SLOT))
	assert_eq(SaveLoad.load_from_slot(SLOT), {})


func test_save_then_load_round_trip() -> void:
	var state: Node = autofree(GameStateScript.new())
	state.set_flag(&"door.breach_01")
	state.mark_room_visited(&"stacks_01")
	state.current_save_point = &"terminal_hub"

	assert_true(SaveLoad.save_to_slot(SLOT, state.snapshot()))
	assert_true(SaveLoad.has_save(SLOT))

	var restored: Node = autofree(GameStateScript.new())
	restored.restore(SaveLoad.load_from_slot(SLOT))
	assert_true(restored.has_flag(&"door.breach_01"))
	assert_true(restored.has_visited(&"stacks_01"))
	assert_eq(restored.current_save_point, &"terminal_hub")


func test_saving_twice_overwrites_rather_than_merges() -> void:
	SaveLoad.save_to_slot(SLOT, {"flags": ["first"]})
	SaveLoad.save_to_slot(SLOT, {"flags": ["second"]})
	var loaded: Dictionary = SaveLoad.load_from_slot(SLOT)
	assert_eq(loaded.get("flags"), ["second"])


func test_corrupt_save_loads_as_empty_instead_of_crashing() -> void:
	DirAccess.make_dir_recursive_absolute(SaveLoad.SAVE_DIR)
	var file := FileAccess.open(SaveLoad.slot_path(SLOT), FileAccess.WRITE)
	file.store_string("{ this is not json")
	file.close()

	var loaded: Dictionary = SaveLoad.load_from_slot(SLOT)
	assert_eq(loaded, {})
	assert_push_error("slot 0 is corrupt", "the bad slot is reported, not swallowed")


func test_valid_json_that_is_not_an_object_is_refused() -> void:
	DirAccess.make_dir_recursive_absolute(SaveLoad.SAVE_DIR)
	var file := FileAccess.open(SaveLoad.slot_path(SLOT), FileAccess.WRITE)
	file.store_string("[1, 2, 3]")
	file.close()

	assert_eq(SaveLoad.load_from_slot(SLOT), {})
	assert_push_error("not a save object")


func test_out_of_range_slots_are_refused() -> void:
	assert_false(SaveLoad.save_to_slot(-1, {"flags": []}))
	assert_false(SaveLoad.save_to_slot(SaveLoad.SLOT_COUNT, {"flags": []}))
	assert_eq(SaveLoad.load_from_slot(99), {})
	assert_push_error("slot -1 out of range")
	assert_push_error("slot 3 out of range")


func test_delete_slot() -> void:
	SaveLoad.save_to_slot(SLOT, {"flags": []})
	assert_true(SaveLoad.delete_slot(SLOT))
	assert_false(SaveLoad.has_save(SLOT))
	assert_false(SaveLoad.delete_slot(SLOT), "deleting a missing slot reports false")
