extends GutTest
## GameState is what makes the world persistent (DESIGN.md §3.4), so the round
## trip through `snapshot()` / `restore()` has to be lossless.

const GameStateScript := preload("res://src/core/game_state.gd")

var _state: Node


func before_each() -> void:
	_state = autofree(GameStateScript.new())


func test_flags_start_empty() -> void:
	assert_false(_state.has_flag(&"door.breach_01"))
	assert_eq(_state.flag_count(), 0)


func test_setting_and_clearing_a_flag() -> void:
	_state.set_flag(&"door.breach_01")
	assert_true(_state.has_flag(&"door.breach_01"))
	_state.set_flag(&"door.breach_01", false)
	assert_false(_state.has_flag(&"door.breach_01"))
	assert_eq(_state.flag_count(), 0)


func test_setting_the_same_flag_twice_does_not_duplicate_it() -> void:
	_state.set_flag(&"boss.landlord_defeated")
	_state.set_flag(&"boss.landlord_defeated")
	assert_eq(_state.flag_count(), 1)


func test_visited_rooms_are_sorted_for_a_stable_save_file() -> void:
	_state.mark_room_visited(&"stacks_07")
	_state.mark_room_visited(&"stacks_02")
	_state.mark_room_visited(&"stacks_07")
	assert_eq(_state.visited_rooms(), PackedStringArray(["stacks_02", "stacks_07"]))
	assert_true(_state.has_visited(&"stacks_02"))
	assert_false(_state.has_visited(&"stacks_99"))


func test_snapshot_restore_round_trip() -> void:
	_state.set_flag(&"door.breach_01")
	_state.set_flag(&"chest.stacks_03_looted")
	_state.mark_room_visited(&"stacks_01")
	_state.current_save_point = &"terminal_hub"
	_state.play_time = 421.5
	var snapshot: Dictionary = _state.snapshot()

	var restored: Node = autofree(GameStateScript.new())
	restored.restore(snapshot)

	assert_true(restored.has_flag(&"door.breach_01"))
	assert_true(restored.has_flag(&"chest.stacks_03_looted"))
	assert_true(restored.has_visited(&"stacks_01"))
	assert_eq(restored.current_save_point, &"terminal_hub")
	assert_almost_eq(restored.play_time, 421.5, 0.001)
	assert_eq(restored.snapshot(), snapshot)


func test_restore_clears_previous_state() -> void:
	_state.set_flag(&"stale.flag")
	_state.mark_room_visited(&"stale_room")
	_state.restore({"flags": ["fresh.flag"], "visited_rooms": ["fresh_room"]})
	assert_false(_state.has_flag(&"stale.flag"))
	assert_false(_state.has_visited(&"stale_room"))
	assert_true(_state.has_flag(&"fresh.flag"))


func test_restore_tolerates_a_save_missing_keys() -> void:
	# An older build's save must load rather than crash the game.
	_state.restore({})
	assert_eq(_state.flag_count(), 0)
	assert_eq(_state.current_save_point, &"")
	assert_almost_eq(_state.play_time, 0.0, 0.001)


func test_snapshot_survives_json() -> void:
	_state.set_flag(&"door.breach_01")
	_state.mark_room_visited(&"stacks_01")
	var parsed: Variant = JSON.parse_string(JSON.stringify(_state.snapshot()))
	assert_eq(typeof(parsed), TYPE_DICTIONARY, "snapshot must be JSON-serializable")

	var restored: Node = autofree(GameStateScript.new())
	restored.restore(parsed as Dictionary)
	assert_true(restored.has_flag(&"door.breach_01"))
	assert_true(restored.has_visited(&"stacks_01"))


func test_reset_wipes_everything() -> void:
	_state.set_flag(&"door.breach_01")
	_state.mark_room_visited(&"stacks_01")
	_state.current_save_point = &"terminal_hub"
	_state.play_time = 99.0
	_state.reset()
	assert_eq(_state.flag_count(), 0)
	assert_eq(_state.visited_rooms(), PackedStringArray())
	assert_eq(_state.current_save_point, &"")
	assert_almost_eq(_state.play_time, 0.0, 0.001)
