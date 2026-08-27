# combat/

The shared damage pipeline every fighter runs through — player and enemies use
the same `Hitbox` / `Hurtbox` pair (DESIGN.md §3.2).

`damage = attack_stat_scaled × weapon_power − defense`, plus knockback,
hitstop (~2–3 frames) and i-frames on hurt.

- `hitbox.gd`, `hurtbox.gd`, `damage.gd` — **M2**
- `projectiles/` — **M2**
- `hacks/` (Overload, Static Wall, Breach; cost RAM) — **M4**
