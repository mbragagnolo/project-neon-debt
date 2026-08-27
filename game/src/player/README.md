# player/

The controller, its state machine, and `movement_config.tres`.

**Rule:** no movement constant is allowed to live in code. Everything the
controller reads comes from `MovementConfig` so tuning is an inspector session,
not a code change (DESIGN.md §3.1).

- `movement_config.gd` / `.tres` — the tuning surface (present)
- `player.gd`, `player.tscn`, `states/` — **M1**
