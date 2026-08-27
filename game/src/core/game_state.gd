extends Node
## Persistent world state (autoload `GameState`).
##
## Single source of truth for everything that must survive a room change or a
## save/load round trip: opened doors, looted chests, defeated bosses, visited
## rooms, the active save point (DESIGN.md §3.4).
##
## Deliberately dumb: a flag store plus a visited-room set. Systems with richer
## state (inventory, quests, stats) own their own data and will fold it into
## `snapshot()` / `restore()` in later milestones.
##
## All state lives in plain Variants so `snapshot()` is JSON-serializable and
## the whole thing is unit-testable without a scene tree.

const SAVE_VERSION := 1

## Arbitrary world flags, e.g. "door.stacks_breach_01" -> true.
var _flags: Dictionary = {}
## Room ids the player has entered at least once (drives the map screen).
var _visited_rooms: Dictionary = {}
## Where respawn puts the player. Empty until the first save point is used.
var current_save_point: StringName = &""
## Seconds of play time accumulated across sessions.
var play_time: float = 0.0


func _ready() -> void:
	# Keep counting while a menu pauses the rest of the game.
	process_mode = Node.PROCESS_MODE_ALWAYS


func _process(delta: float) -> void:
	play_time += delta


# --- Flags ------------------------------------------------------------------

func set_flag(flag: StringName, value: bool = true) -> void:
	if value:
		_flags[String(flag)] = true
	else:
		_flags.erase(String(flag))


func has_flag(flag: StringName) -> bool:
	return _flags.has(String(flag))


func flag_count() -> int:
	return _flags.size()


# --- Rooms ------------------------------------------------------------------

func mark_room_visited(room_id: StringName) -> void:
	_visited_rooms[String(room_id)] = true


func has_visited(room_id: StringName) -> bool:
	return _visited_rooms.has(String(room_id))


## Sorted so the map screen and save files have a stable order.
func visited_rooms() -> PackedStringArray:
	var ids := PackedStringArray(_visited_rooms.keys())
	ids.sort()
	return ids


# --- Serialization ----------------------------------------------------------

## Plain-data snapshot of the whole state. JSON-safe by construction.
func snapshot() -> Dictionary:
	var flags := PackedStringArray(_flags.keys())
	flags.sort()
	return {
		"version": SAVE_VERSION,
		"flags": flags,
		"visited_rooms": visited_rooms(),
		"current_save_point": String(current_save_point),
		"play_time": play_time,
	}


## Inverse of `snapshot()`. Missing keys fall back to defaults so a save
## written by an older build still loads.
func restore(data: Dictionary) -> void:
	reset()
	for flag: Variant in data.get("flags", []):
		set_flag(StringName(str(flag)))
	for room: Variant in data.get("visited_rooms", []):
		mark_room_visited(StringName(str(room)))
	current_save_point = StringName(str(data.get("current_save_point", "")))
	play_time = float(data.get("play_time", 0.0))


func reset() -> void:
	_flags.clear()
	_visited_rooms.clear()
	current_save_point = &""
	play_time = 0.0
