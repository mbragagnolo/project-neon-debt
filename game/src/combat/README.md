# combat/

The shared damage pipeline every fighter runs through — player and enemies use
the same `Hitbox` / `Hurtbox` pair (DESIGN.md §3.2).

`damage = max(1, weapon_power × stat_multiplier − defense)`, where
`stat_multiplier` is a soft-capped saturating curve (constants in
`docs/rpg/stats-and-curves.md`) and damage floors at 1. Plus knockback,
hitstop (~2–3 frames) and i-frames on hurt.

**The spec is `docs/combat/damage-pipeline.md`.** Every rule below is written
down there with its reasoning; this file is only the map of where each step
lives in code.

## The split

One ordered eleven-step pipeline, no per-verb exceptions. The steps are shared
out so that the arithmetic can be tested without a scene:

| Steps | Owner | What |
|---|---|---|
| 1–2 | `hitbox.gd` | Overlap sweep, and the per-swing target set that stops multi-hit |
| 3–8 | `damage.gd` | Pure decisions and pure math: i-frames, stat curve, immunity, DEF, floor, stagger |
| 7–11 | `hurtbox.gd` | Applying it: damage, the signal, hitstop, knockback, interlocks, death |

`damage.gd` touches nothing in the tree on purpose. "Does DEF apply before or
after the floor" is answerable by reading one function, and provable by a test
that never instances a room.

## Rules that are easy to break by accident

- **Multi-hit is a target set, not a cooldown.** Any timer long enough to stop
  the wrench double-hitting also throttles the 4/s nailgun.
- **Immunity is checked before DEF.** A blocked hit is rejected, never reduced
  to the floor of 1 — otherwise a shield leaks chip damage.
- **Hitstop takes the maximum, never the sum.** Summing turns a three-enemy
  fight into a slideshow, and it reads as a performance bug.
- **Interlocks are weapon data, not logic.** `ammo_on_hit` lives on the melee
  weapon resource; V2 switches the intertwined kit off by zeroing a field on
  three items (the requirement this file used to carry).

## Files

- `damage.gd`, `attack.gd`, `damage_result.gd` — the pipeline and its payloads
- `health.gd`, `hitbox.gd`, `hurtbox.gd` — the components every fighter carries
- `hitstop.gd` — autoload `Hitstop`; global freeze via `Engine.time_scale`,
  counted in real milliseconds because scaled time cannot measure its own
  suspension
- `combat_config.tres` — every tuning number, same rule as `MovementConfig`
- `weapons/` — `Weapon` base plus the melee/ranged resources
- `projectiles/` — `Projectile`, which is just a `Hitbox` that moves and expires
