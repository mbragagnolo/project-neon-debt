class_name Room
extends Node2D
## Base script for every room scene (DESIGN.md §3.4).
##
## A room is the unit of the map: it announces itself on the signal bus when
## entered and records itself in `GameState` so the map screen (M5) can reveal
## it. Door/transition wiring and the `WorldGraph` resource land in M5 — this
## is the hook they attach to.

## Stable id used by the world graph, save file and map screen.
## Must be unique across the district; keep it snake_case.
@export var room_id: StringName = &""
## Human-readable name shown on the map screen.
@export var display_name: String = ""


func _ready() -> void:
	if room_id == &"":
		push_warning("Room '%s' has no room_id — it cannot be saved or mapped." % name)
		return
	GameState.mark_room_visited(room_id)
	Events.room_entered.emit(room_id)


func _exit_tree() -> void:
	if room_id != &"":
		Events.room_exited.emit(room_id)
