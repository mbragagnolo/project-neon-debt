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


# --- M3: the sheet and the loadout go through the file ----------------------

func test_progression_survives_a_real_round_trip_through_json() -> void:
	# The unit tests round-trip through dictionaries; this one goes through the
	# file, which is where JSON gets its say. Every number comes back as a
	# float and every PackedStringArray as a plain Array, so a restore that
	# assigned straight across would load level 3.0 and own nothing.
	PlayerStats.reset()
	Inventory.reset()
	PlayerStats.grant_xp(200)
	PlayerStats.grant_credits(75)
	Inventory.grant(&"breaker_maul")
	Inventory.grant(&"work_boots")
	Inventory.equip(&"breaker_maul")

	assert_true(SaveLoad.save_to_slot(SLOT, GameState.snapshot()))
	PlayerStats.reset()
	Inventory.reset()
	assert_eq(PlayerStats.level, 1, "the reset did not take")

	GameState.restore(SaveLoad.load_from_slot(SLOT))

	assert_eq(PlayerStats.level, 3)
	assert_eq(PlayerStats.xp, 200)
	assert_eq(PlayerStats.credits, 75)
	assert_true(Inventory.owns(&"work_boots"))
	assert_eq(Inventory.equipped_melee().id, &"breaker_maul")
	assert_eq(Inventory.equipped(Item.Slot.LEGS).id, &"work_boots")
	# And the derived half followed, rather than the raw fields loading while
	# the effective sheet stayed at level 1.
	assert_eq(PlayerStats.effective_max_hp(), 50)
	assert_eq(PlayerStats.effective_defense(), 1)

	PlayerStats.reset()
	Inventory.reset()
	GameState.reset()


func test_a_version_one_save_loads_as_a_fresh_sheet() -> void:
	# Saves written before M3 carry no "stats" or "inventory" key at all. The
	# rule is that a missing key restores from an empty dictionary, so an old
	# file degrades to a fresh run rather than to a crash.
	PlayerStats.grant_xp(400)
	Inventory.grant(&"nailgun")
	SaveLoad.save_to_slot(SLOT, {
		"version": 1,
		"flags": ["door.breach_01"],
		"visited_rooms": ["stacks_01"],
		"current_save_point": "terminal_hub",
		"play_time": 12.5,
	})

	GameState.restore(SaveLoad.load_from_slot(SLOT))
	assert_true(GameState.has_flag(&"door.breach_01"), "the old keys still load")
	assert_eq(PlayerStats.level, 1)
	assert_false(Inventory.owns(&"nailgun"))

	PlayerStats.reset()
	Inventory.reset()
	GameState.reset()
