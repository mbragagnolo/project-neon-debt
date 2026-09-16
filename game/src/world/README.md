# world/

Rooms, doors, save points, and the graph that ties them together (DESIGN.md §3.4).

- `room.gd` — base script for every room scene (present)
- `encounter.gd` — **M2**. A group of enemies that belong to one fight:
  spawns one per `Marker2D` child, and repopulates when cleared so a tuning
  session can run the same fight repeatedly without restarting the game.
- `pickup.gd` / `pickup.tscn` — **M3.** An item waiting in the world: a chest,
  a crate, a dead worker's kit. One node rather than a chest/floor-item pair,
  because what differs between them is art that does not exist yet. Looting is
  a `GameState` flag, so a chest re-entered after a save stays open. **M4**
  gave it a `kind`: `HACK` pickups hand out programs instead of items.
- `breach_door.gd` / `breach_door.tscn` — **M4.** The sealed door with a
  terminal. Opens for free through the terminal if Breach is owned, or from a
  Breach cast in reach; the opening is a `GameState` flag (`door.<id>`).
- `gym_grants.gd` — gym-only. Sets every ability flag on load so a lab is
  fully testable wherever its feature sits in the district. Never shipped.
- `world.gd` / `rooms/world.tscn` — **M5.** The district at runtime: one
  persistent player, one room at a time under `RoomHost`, travel through
  doors with a fade, death back to the last terminal.
- `door.gd` — a room transition. Pairs name each other; an arrival door is
  disarmed until the player steps out of it.
- `save_point.gd` — the VESTA care terminal: save, full heal, full RAM, the
  respawn point.
- `hazard.gd` — live water (damage + bounce) and the void (damage + back to
  the last safe ground).
- `grate.gd` — the one-way shortcut, released from the far side.
- `lift.gd` — the freight platform in the drain riser.
- `npc.gd` — Stitch and Marisol; `sign.gd`, `tease.gd` — dressing.
- `room_spec.gd` — the ASCII room format the district is authored in;
  `world_graph.gd` — the map data the generator writes.

Room ids are snake_case and stable: they end up in the save file and on the map
screen, so renaming one invalidates saves.

`Encounter` deliberately knows nothing about persistence. M5 owns the real room
population, which has to answer to `GameState` — a boss stays dead, a cleared
room stays cleared. "Put the fight back so it can be felt again" is a different
job, and mixing the two would turn a gym convenience into a save-file bug.
