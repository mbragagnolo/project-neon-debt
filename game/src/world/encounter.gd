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
##
## **Tracks instance ids, not nodes.** A dead enemy `queue_free`s itself, and a
## freed node left in an `Array[Node]` is a dangling `Object` that no longer
## satisfies a typed `Node` parameter — so every read of the list threw from
## the first death onward. An id is a plain int: it cannot dangle, and
## `is_instance_id_valid` answers the only question this class actually has.

## Emitted when the last enemy of the group dies.
signal cleared()

@export var enemy_scene: PackedScene
## Seconds after the group is cleared before it repopulates. 0 = never, which
## is what any shipped room will want.
@export var respawn_delay: float = 2.5

var _alive_ids: Array[int] = []
var _respawn_timer: float = 0.0
var _spawned_once: bool = false


func _ready() -> void:
	spawn_all()


func _process(delta: float) -> void:
	if alive_count() > 0:
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

	_alive_ids.clear()
	for marker: Node in get_children():
		if not (marker is Marker2D):
			continue
		var enemy: Node = enemy_scene.instantiate()
		add_child(enemy)
		(enemy as Node2D).global_position = (marker as Marker2D).global_position
		_alive_ids.append(enemy.get_instance_id())

	_spawned_once = not _alive_ids.is_empty()
	_respawn_timer = respawn_delay


## Living members of the group, pruning any that have been freed since the last
## call. Ints all the way through, so nothing here can hold a dead reference.
func alive_count() -> int:
	var living: Array[int] = []
	for id: int in _alive_ids:
		if is_instance_id_valid(id):
			living.append(id)
	_alive_ids = living
	return _alive_ids.size()
