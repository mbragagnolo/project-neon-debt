# world/

Rooms, doors, save points, and the graph that ties them together (DESIGN.md §3.4).

- `room.gd` — base script for every room scene (present)
- `encounter.gd` — **M2**. A group of enemies that belong to one fight:
  spawns one per `Marker2D` child, and repopulates when cleared so a tuning
  session can run the same fight repeatedly without restarting the game.
- `pickup.gd` / `pickup.tscn` — **M3.** An item waiting in the world: a chest,
  a crate, a dead worker's kit. One node rather than a chest/floor-item pair,
  because what differs between them is art that does not exist yet. Looting is
  a `GameState` flag, so a chest re-entered after a save stays open.
- `door.gd`, `save_point.gd`, `world_graph.tres` — **M5**

Room ids are snake_case and stable: they end up in the save file and on the map
screen, so renaming one invalidates saves.

`Encounter` deliberately knows nothing about persistence. M5 owns the real room
population, which has to answer to `GameState` — a boss stays dead, a cleared
room stays cleared. "Put the fight back so it can be felt again" is a different
job, and mixing the two would turn a gym convenience into a save-file bug.
