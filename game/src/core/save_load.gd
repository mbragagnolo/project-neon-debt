class_name SaveLoad
extends RefCounted
## Save file reader/writer (DESIGN.md §3.4).
##
## Static-only helper: takes a `GameState.snapshot()` dictionary in, writes JSON
## to `user://`, and reads it back. Keeping it free of node references is what
## lets `tests/test_save_load.gd` run headless.
##
## Every function returns an explicit success/failure value — a corrupt or
## missing save must never crash the game, it must fall back to a fresh run.

const SAVE_DIR := "user://saves"
const SLOT_COUNT := 3


static func slot_path(slot: int) -> String:
	return "%s/slot_%d.json" % [SAVE_DIR, slot]


static func has_save(slot: int) -> bool:
	return FileAccess.file_exists(slot_path(slot))


## Writes `data` to `slot`. Returns true on success.
static func save_to_slot(slot: int, data: Dictionary) -> bool:
	if not _is_valid_slot(slot):
		push_error("SaveLoad: slot %d out of range" % slot)
		return false
	DirAccess.make_dir_recursive_absolute(SAVE_DIR)
	var file := FileAccess.open(slot_path(slot), FileAccess.WRITE)
	if file == null:
		push_error("SaveLoad: cannot write %s (%s)" % [
			slot_path(slot), error_string(FileAccess.get_open_error())
		])
		return false
	file.store_string(JSON.stringify(data, "\t", true))
	file.close()
	return true


## Reads `slot`. Returns an empty Dictionary if the slot is missing, unreadable
## or not valid JSON — callers treat that as "no save".
static func load_from_slot(slot: int) -> Dictionary:
	if not _is_valid_slot(slot) or not has_save(slot):
		return {}
	var file := FileAccess.open(slot_path(slot), FileAccess.READ)
	if file == null:
		push_error("SaveLoad: cannot read %s (%s)" % [
			slot_path(slot), error_string(FileAccess.get_open_error())
		])
		return {}
	var text := file.get_as_text()
	file.close()
	# JSON.parse_string() prints an engine-level ERROR on bad input, which would
	# both dirty the log and trip the boot check in CI. The instance API reports
	# the same failure quietly and tells us where it went wrong.
	var json := JSON.new()
	if json.parse(text) != OK:
		push_error("SaveLoad: slot %d is corrupt, ignoring (line %d: %s)" % [
			slot, json.get_error_line(), json.get_error_message()
		])
		return {}
	if typeof(json.data) != TYPE_DICTIONARY:
		push_error("SaveLoad: slot %d is not a save object, ignoring" % slot)
		return {}
	return json.data


static func delete_slot(slot: int) -> bool:
	if not has_save(slot):
		return false
	return DirAccess.remove_absolute(slot_path(slot)) == OK


static func _is_valid_slot(slot: int) -> bool:
	return slot >= 0 and slot < SLOT_COUNT
