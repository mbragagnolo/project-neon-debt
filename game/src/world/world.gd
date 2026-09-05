class_name World
extends Node2D
## The district at runtime (DESIGN.md §3.4): one persistent player, one room
## at a time, and the travel between them.
##
## The player lives *here*, not in the room scenes, so HP, RAM, ammo and the
## camera survive a door: a room is instanced under `RoomHost`, the player is
## placed at the arrival door, and the old room is freed. Rooms therefore
## never contain a player — the gyms do, and that is what makes a gym a
## standalone scene and a district room not.
##
## Death is the slice default (DESIGN.md §7): respawn at the last care
## terminal with everything kept; the room reloads, so enemies come back.

const ROOM_DIR := "res://rooms/stacks"
const START_ROOM := &"unit_14c"
const FADE_SECONDS := 0.16

@onready var _host: Node2D = $RoomHost
@onready var player: Player = $Player
@onready var _fade: ColorRect = $Fade/Black

var current_room: Room
var current_room_id: StringName = &""
var _travelling: bool = false


func _ready() -> void:
	player.handles_own_respawn = false
	player.frozen = true
	Events.room_travel_requested.connect(_on_travel_requested)
	Events.player_died.connect(_on_player_died)
	_fade.modulate.a = 1.0
	# A save picked from the title screen (M7) lands at its terminal; a fresh
	# run wakes up in 14-C.
	if GameState.current_save_point != &"":
		await travel(GameState.current_save_point, &"save")
	else:
		await travel(START_ROOM, &"start")
		Events.bark_requested.emit(Lines.BARK_WAKE)


static func room_path(room_id: StringName) -> String:
	return "%s/%s.tscn" % [ROOM_DIR, room_id]


## Swaps rooms. `door_id` is the arrival door in the new room, `&"start"`
## for the room's `PlayerSpawn` marker, `&"save"` for its care terminal.
func travel(room_id: StringName, door_id: StringName) -> void:
	if _travelling:
		return
	_travelling = true
	player.frozen = true
	await _fade_to(1.0)

	if current_room != null:
		_host.remove_child(current_room)
		current_room.queue_free()
		current_room = null
	var scene: PackedScene = load(room_path(room_id))
	if scene == null:
		push_error("World: no room at %s" % room_path(room_id))
		_travelling = false
		player.frozen = false
		return
	current_room = scene.instantiate()
	current_room_id = room_id
	_host.add_child(current_room)

	var arrival: Door = null
	var spawn: Vector2 = _spawn_point(door_id)
	if door_id != &"start" and door_id != &"save":
		arrival = current_room.get_node_or_null("Doors/%s" % door_id) as Door
		if arrival != null:
			arrival.disarm()
		else:
			push_warning("World: %s has no door '%s'" % [room_id, door_id])
	player.global_position = current_room.to_global(spawn)
	# Through a floor or ceiling the momentum carries; through a wall it does
	# not — arriving at a run into the next room's first Scav is nobody's
	# idea of a door.
	if arrival == null or arrival.side == Door.Side.LEFT or arrival.side == Door.Side.RIGHT:
		player.velocity = Vector2.ZERO
	if arrival != null:
		player.set_facing(1 if arrival.side == Door.Side.LEFT else (-1 if arrival.side == Door.Side.RIGHT else player.facing))
	player.apply_room_limits(current_room)
	player.camera.reset_smoothing()
	if not GameState.has_visited(room_id) or door_id == &"start":
		Events.toast_requested.emit(current_room.display_name.to_upper())
	current_room.enter()

	await _fade_to(0.0)
	player.frozen = false
	_travelling = false


func _spawn_point(door_id: StringName) -> Vector2:
	if door_id == &"save":
		var terminal: Node = _first_in_group_under(current_room, &"save_points")
		if terminal is Node2D:
			return current_room.to_local((terminal as Node2D).global_position)
	if door_id == &"start" or door_id == &"save":
		var marker: Node = current_room.get_node_or_null("PlayerSpawn")
		if marker is Node2D:
			return (marker as Node2D).position
		return Vector2(120.0, 0.0)
	var door: Door = current_room.get_node_or_null("Doors/%s" % door_id) as Door
	if door != null:
		return door.spawn_point
	var marker: Node = current_room.get_node_or_null("PlayerSpawn")
	return (marker as Node2D).position if marker is Node2D else Vector2.ZERO


func _first_in_group_under(root: Node, group: StringName) -> Node:
	for node: Node in get_tree().get_nodes_in_group(group):
		if root.is_ancestor_of(node):
			return node
	return null


func _on_travel_requested(room_id: StringName, door_id: StringName) -> void:
	travel(room_id, door_id)


func _on_player_died() -> void:
	player.frozen = true
	await get_tree().create_timer(0.7).timeout
	player.velocity = Vector2.ZERO
	if GameState.current_save_point != &"":
		await travel(GameState.current_save_point, &"save")
	else:
		await travel(START_ROOM, &"start")
	player.restore_all()


func _fade_to(alpha: float) -> void:
	var tween := create_tween()
	tween.tween_property(_fade, "modulate:a", alpha, FADE_SECONDS)
	await tween.finished
