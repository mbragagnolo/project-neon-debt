# world/

Rooms, doors, save points, and the graph that ties them together (DESIGN.md §3.4).

- `room.gd` — base script for every room scene (present)
- `door.gd`, `save_point.gd`, `world_graph.tres` — **M5**

Room ids are snake_case and stable: they end up in the save file and on the map
screen, so renaming one invalidates saves.
