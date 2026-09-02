class_name Encounter
extends Node2D
## A group of enemies that belong to one fight.
##
## Spawns one enemy per `Marker2D` child at ready, and — when `respawn_delay`
## is above zero — repopulates once the group has been cleared. The respawn is
## a tuning convenience: the M2 exit test is "fighting 3 Scavs is legible and
## satisfying", and judging that means fighting them more than once without
## restarting the game.
##
## M5 owns the real version of this. Room population there has to answer to
## `GameState` (a boss stays dead, a cleared room stays cleared), which is a
## different job from "put the fight back so it can be felt again" — so this
## deliberately knows nothing about persistence.

## Emitted when the last enemy of the group dies.
signal cleared()

@export var enemy_scene: PackedScene
## Seconds after the group is cleared before it repopulates. 0 = never, which
## is what any shipped room will want.
@export var respawn_delay: float = 2.5

var _alive: Array[Node] = []
var _respawn_timer: float = 0.0
var _spawned_once: bool = false


func _ready() -> void:
	spawn_all()


func _process(delta: float) -> void:
	_alive = _alive.filter(func(node: Node) -> bool: return is_instance_valid(node))
	if not _alive.is_empty():
		return

	if _spawned_once:
		_spawned_once = false
		cleared.emit()

	if respawn_delay <= 0.0:
		return
	_respawn_timer -= delta
	if _respawn_timer <= 0.0:
		spawn_all()


func spawn_all() -> void:
	if enemy_scene == null:
		push_warning("Encounter '%s' has no enemy scene." % name)
		return

	for marker: Node in get_children():
		if not (marker is Marker2D):
			continue
		var enemy: Node = enemy_scene.instantiate()
		add_child(enemy)
		(enemy as Node2D).global_position = (marker as Marker2D).global_position
		_alive.append(enemy)

	_spawned_once = not _alive.is_empty()
	_respawn_timer = respawn_delay


func alive_count() -> int:
	_alive = _alive.filter(func(node: Node) -> bool: return is_instance_valid(node))
	return _alive.size()
