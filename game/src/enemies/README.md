# enemies/

Shared `Enemy` base (patrol → aggro → attack → stagger, XP + loot on death) and
one folder per roster entry (DESIGN.md §3.5, stat blocks in
`docs/characters/enemies.md`).

- `training_dummy/` — **M2**, gym only, never shipped in a room
- `enemy_base.gd`, `scav/` — **M2**
- `drone/`, `riot/`, `boss_landlord/` — **M6**

Each enemy exists to teach one thing: Scav = spacing, Watcher drone = vertical
threat, Riot unit = frontal ranged immunity. The teaching role is the anchor —
stats serve it, and a tuning change that breaks the lesson is wrong even if the
numbers look better.

## Enemies do not run the player's stat sheet

The reduced block is `hp`, flat `attack_power`, `def`, rewards, drops, and
binary resistance tags — nothing else (`docs/rpg/stats-and-curves.md`). Flat
attack means what an encounter author types is what the thing hits for, with no
derived math in between. A Scav with an INT score is bookkeeping with no
gameplay output.

Two consequences that are already wired into the M2 pipeline:

- **Enemies never get timed i-frames.** They get per-swing multi-hit rejection
  instead, so a timer can never silently cap a fast weapon's fire rate.
- **Every enemy ships at `def = 0` through M2.** Enemy DEF is set *last*, after
  weapon numbers exist — low-end DEF is swingy against light weapons, so
  guessing it early would mistune the whole trio.
