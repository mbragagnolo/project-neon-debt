class_name Door
extends Area2D
## A room transition (DESIGN.md §3.4).
##
## Sits in the opening a room's grid leaves in its wall. Walking into it asks
## the world to travel; the world does the rest — this node never loads a
## scene or moves a player, it only says where it leads. Rooms are connected
## by *pairs* of doors, each naming the other, which is what
## `tests/test_stacks.gd` checks: a door whose partner points somewhere else
## is a one-way trip the map cannot draw.
##
## A door the player just arrived through is disarmed until they step out of
## it, or arrival would bounce them straight back.

enum Side { LEFT, RIGHT, UP, DOWN }

## Unique within its room; the digit from the room grid.
@export var door_id: StringName = &""
@export var target_room: StringName = &""
@export var target_door: StringName = &""
## One of `Side`. Typed as int rather than as the enum on purpose: the enum
## is referenced from scripts this one is loaded alongside (the room spec,
## the world, the map), and Godot 4 refuses `Side = Side.LEFT` inside a
## dependency cycle with a confusing "Door.Side is not Side".
@export var side: int = Side.LEFT
## The trigger box, px.
@export var size: Vector2 = Vector2(60.0, 180.0)
## Room-local point an arriving player is placed at (feet).
@export var spawn_point: Vector2 = Vector2.ZERO
## The room's size, px, so the door can tell "left the trigger inward" from
## "left the trigger out of the room" — a body that falls out through a
## floor door must still travel.
@export var room_size: Vector2 = Vector2(1920.0, 1080.0)

var _armed: bool = true


func _ready() -> void:
	collision_layer = 2048  # room_transition
	collision_mask = 2  # player
	var rect := RectangleShape2D.new()
	rect.size = size
	var collider := CollisionShape2D.new()
	collider.shape = rect
	add_child(collider)
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


## Called by the world when it drops the player in through this door.
func disarm() -> void:
	_armed = false


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group(&"player") or not _armed:
		return
	_armed = false
	Events.room_travel_requested.emit(target_room, target_door)


func _on_body_exited(body: Node2D) -> void:
	if not body.is_in_group(&"player"):
		return
	_armed = true
	if _is_outside(body):
		_armed = false
		Events.room_travel_requested.emit(target_room, target_door)


## Past this door's edge of the room.
func _is_outside(body: Node2D) -> bool:
	var local: Vector2 = get_parent().get_parent().to_local(body.global_position)
	match side:
		Side.LEFT:
			return local.x < 0.0
		Side.RIGHT:
			return local.x > room_size.x
		Side.UP:
			return local.y < -20.0
		Side.DOWN:
			return local.y > room_size.y + 20.0
	return false
