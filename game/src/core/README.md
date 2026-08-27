# core/

Cross-cutting singletons. Nothing here knows about gameplay specifics.

- `events.gd` — autoload `Events`, the signal bus. Systems talk through it
  instead of holding node references (DESIGN.md §4).
- `game_state.gd` — autoload `GameState`, persistent world flags, visited rooms,
  active save point. JSON-serializable by construction.
- `save_load.gd` — `SaveLoad`, static JSON read/write to `user://saves`. A
  corrupt or missing save degrades to "fresh run", never to a crash.
