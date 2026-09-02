# enemies/

Shared `Enemy` base (patrol → aggro → attack → stagger, XP + loot on death) and
one folder per roster entry (DESIGN.md §3.5, stat blocks and teaching roles in
`docs/characters/enemies.md`).

- `enemy_base.gd`, `enemy_config.gd`, `states/` — **M2**
- `scav/` — **M2**, the first fight of the game
- `training_dummy/` — **M2**, gym only, never shipped in a room
- `drone/`, `riot/`, `boss_landlord/` — **M6**

Each enemy exists to teach one thing: Scav = spacing, Watcher drone = vertical
threat, Riot unit = frontal ranged immunity. The teaching role is the anchor —
stats serve it, and a tuning change that breaks the lesson is wrong even if the
numbers look better.

## An enemy is a resource, not a subclass

`Enemy` owns the physics and the hitboxes; the state machine under it owns the
decisions; `EnemyConfig` owns every number. So far there is no `scav.gd` at
all — the Scav is `enemy_base.gd` plus `scav.tres`.

That is the point, and it is what makes a promise in the roster doc cheap to
keep: the **Elite Scav** is "same silhouette and moveset, faster, and no
overcommit". That is one more `.tres` with `recover_time` cut and the speeds
raised. No new script, no subclass, no copy of the state machine.

## The split, and why the states are separate files

| State | Owns |
|---|---|
| `Patrol` | The beat, the pause at each end, turning at walls |
| `Chase` | Closing, and the leash back to `home` |
| `Windup` | **The telegraph.** Aims once, then stops choosing |
| `Lunge` | The commitment, attack box armed at full `attack_power` |
| `Recover` | **The overcommit** — the punishable window |
| `Stagger` | Interrupted, entered from anywhere by `Health.staggered` |
| `Dead` | Terminal; the machine refuses every transition out of it |

Windup/Lunge/Recover could have been three phases of one attack state. They are
separate because each one's duration *is* a design decision — the lesson is
"bait the yellow, punish the grey" — and separate states mean a test can assert
on the phase by name and a tuning session can find the number by opening the
file named after the thing that feels wrong.

## Rules that are easy to break by accident

- **The windup does not track the player.** It aims once on entry. A lunge that
  re-aims is a homing missile with a warning light, and the spacing lesson
  dies with it.
- **`stagger_time` must stay under the player's fastest weapon cooldown**, or
  melee is a stunlock and every Scav is solved by walking in and holding one
  button.
- **`recover_time` must exceed the swing's `commit_time`**, or the punish
  window is fake.
- **Contact damage is armed for as long as the enemy lives**, at half
  `attack_power`. It is a condition, not an action — the player's i-frames are
  what make it fair.

Both invariants above have tests (`tests/test_scav.gd`) that fail loudly rather
than letting a plausible-looking tuning session quietly delete the tutorial.

## Enemies do not run the player's stat sheet

The reduced block is `hp`, flat `attack_power`, `def`, rewards, drops, and
binary resistance tags — nothing else (`docs/rpg/stats-and-curves.md`). Flat
attack means what an encounter author types is what the thing hits for.

- **Enemies never get timed i-frames.** They get per-swing multi-hit rejection
  instead, so a timer can never silently cap a fast weapon's fire rate.
- **Every enemy ships at `def = 0` through M2.** Enemy DEF is set *last*, after
  weapon numbers exist — and now after they have been *tuned*, since the
  wrench moved to 1.6/s.
