# combat/

The shared damage pipeline every fighter runs through — player and enemies use
the same `Hitbox` / `Hurtbox` pair (DESIGN.md §3.2).

`damage = max(1, weapon_power × stat_multiplier − defense)`, where
`stat_multiplier` is a soft-capped saturating curve (constants in
`docs/rpg/stats-and-curves.md`) and damage floors at 1. Plus knockback,
hitstop (~2–3 frames) and i-frames on hurt.

- `hitbox.gd`, `hurtbox.gd`, `damage.gd` — **M2**
- `projectiles/` — **M2**
- `hacks/` (Firewall, Overload, Breach; cost RAM) — **M4**
