# Enemy roster

**Status: locked, built (M6).** Absolute numbers `TUNE` in M7; the DEF pass
was done in M6 against the tuned weapons (see the block below). Stat block
format per stats-and-curves.md: hp, flat attack_power, def, xp/credit
rewards, binary resistance tags. Drop tables are deferred: the vendor's
refill and the melee interlock cover ammo, and V1 ships no drops.

Every enemy exists to teach one thing. The teaching role is the anchor —
stats serve it, and any tuning change that breaks the lesson is wrong even
if the numbers look better.

## Cross-cutting rules — LOCKED

**Contact damage: on, at half attack_power** (`TUNE`). Brushing an enemy
hurts. Genre-standard, nearly free to implement, and it makes spacing matter
*always*, not only during attack windups. Player i-frames on hurt (M2) are
what keep it fair.

**Stagger: one field, `stagger_threshold`** — the single-hit damage required
to interrupt an enemy into its stagger state. This turns stagger into a
teaching tool and gives the heavy sidegrades a second job beyond
DEF-piercing: the Riot unit ignoring a wrench *is* the lesson.

## Roster

| | Scav | Watcher drone | Riot unit | Elite Scav | The Landlord |
|---|---|---|---|---|---|
| Teaches | Spacing | Vertical threat, ranged verb | Heavy hits & hacks | The quest-area wall | Every verb has a job |
| HP | 16 | 10 | 35 | 40 | 240 |
| attack_power | 6 | 5 (projectile) | 10 | 9 | 14 |
| **DEF** (M6 pass) | 0 | 0 | 3 | 2 | 4 |
| stagger_threshold | 1 | 1 | 12 | 8 | 16 |
| Tags | — | `mechanical` | `mechanical`, `immune_ranged_frontal` | — | — |
| XP / credits | 10 / 5 | 14 / 7 | 22 / 15 | 45 / 25 | 200 / 100 |
| Placed | 29 | 17 | 8 | 1 | 1 |

Ratios between rewards are the locked part. The placed roster holds 949 XP;
the XP curve's `base` held at 60 against it (stats-and-curves.md).

### The DEF pass (M6)

Set last, after the trio was tuned, at level 5 — the sheet the armoured
enemies are met with (STR/DEX/INT 17, ×1.6):

| Weapon | vs Riot unit (DEF 3) | vs Landlord (DEF 4) |
|---|---|---|
| Wrench 13 | 10 — flinch | 9 — flinch |
| Blade 8 | 5 — the wrong tool | 4 |
| Maul 29 | 26 — **interrupts** | 25 — **interrupts** |
| Rivet gun 24 | pings off the front; 21 from behind | 20 — **interrupts** |
| Overload 24 | 21 — **interrupts**, through the shield | 20 — **interrupts** |

The Scav and the drone stay at 0: they die to being reached. The Elite's 2
keeps the wrench (11) over its threshold of 8, so the fight is about the
missing recovery window, not about armour.

### Scav — melee rusher
Human scavenger. Patrols a short beat; on aggro, closes and **lunges with a
telegraphed overcommit** that leaves it punishable. Dies in 2–3 wrench hits.
The first fight of the game and the tutorial for spacing: bait the lunge,
step in, punish.

### Watcher drone — flying sentry
Hovers above melee reach, lobs slow, dodgeable projectiles. Fragile once
reached — the puzzle is *reaching* it, and the intended answer is the zipgun
(this is the enemy the ranged verb is taught with). `mechanical`: Breach
drops it out of the air for a beat.

*Built:* it holds 210px above the player's centre and 240px to one side —
the side it is already on, so it never crosses over your head when you turn
— and every 2.2s it stops, lights up for 0.45s, and fires a 340px/s shot at
where you are when the tell ends. Move during the tell and it misses.
Stunned or dead it falls; when the stun ends it climbs back. Two zipgun
shots kill it.

### Riot unit — the shield wall
Mechanical crowd-suppression frame behind a full-height shield. Advances
slowly; frontal `immune_ranged` (nails and rivets ping off the shield);
ignores light hits (threshold 12 — the maul and rivet gun interrupt it,
the wrench does not). Answers: get behind it (dash through), hit it heavy,
or hack it — Breach stuns it, Overload ignores the shield entirely. Human
Scavs shrug at Breach; the Riot unit crumples — tags mean something.

*Built:* the Scav's scene shape with its own numbers — chase 110 against
the Scav's 235, a 0.6s shield-bash tell, a short heavy lunge. The shield is
a `Facing` visual that flips with it. Enemies are not solid to the player,
so "get behind it" is a jump over or a dash through, paid for in contact
damage the i-frames make fair.

### Elite Scav — the quest guard
A Scav that learned. Same silhouette and moveset, faster, and **no
overcommit** — the lunge recovers safely, so the tutorial answer stops
working and the player must apply everything else. Guards the memory-chip
room in the hazard area. Rewards like a miniboss.

*Built:* the Scav scene with `elite_scav.tres` — recovery 0.12s against the
wrench's 0.16s commit (the punish window is gone), chase 300, lunge 780,
windup 0.34, cooldown 0.45. It stays dead once killed (`persist_flag`).

### The Landlord
See [`boss-landlord.md`](boss-landlord.md).

## Exports

- Reward *ratios* above feed the XP/credit curve solve
  (stats-and-curves.md, last open section — now waiting only on M5 enemy
  counts).
- Contact damage requires player hurt i-frames in the M2 pipeline (already
  planned, DESIGN.md §3.2).
- Drop tables carry the rare ammo drops (rate locked stingy in
  stats-and-curves.md).
