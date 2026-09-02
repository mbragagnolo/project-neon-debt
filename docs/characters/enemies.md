# Enemy roster

**Status: locked** (identities, rules, behaviors, reward ratios). Absolute
numbers `TUNE`; enemy DEF is set last, after weapon numbers exist
(stats-and-curves.md tuning warning). Stat block format per
stats-and-curves.md: hp, flat attack_power, def, xp/credit rewards, drop
table, binary resistance tags.

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

| | Scav | Watcher drone | Riot unit | Elite Scav |
|---|---|---|---|---|
| Teaches | Spacing | Vertical threat, ranged verb | Heavy hits & hacks | The quest-area wall |
| HP | 16 | 10 | 35 | 40 |
| attack_power | 6 | 5 (projectile) | 10 | 9 |
| stagger_threshold | 1 | 1 | 12 | 8 |
| Tags | — | `mechanical` | `mechanical`, `immune_ranged_frontal` | — |
| Rewards (× Scav) | 1× | 1.5× | 3× | 4× |

All values `TUNE`; ratios between rewards are the locked part — the XP curve
constants get solved against them once M5 fixes enemy counts.

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

### Riot unit — the shield wall
Mechanical crowd-suppression frame behind a full-height shield. Advances
slowly; frontal `immune_ranged` (nails and rivets ping off the shield);
ignores light hits (threshold 12 — the maul and rivet gun interrupt it,
the wrench does not). Answers: get behind it (dash through), hit it heavy,
or hack it — Breach stuns it, Overload ignores the shield entirely. Human
Scavs shrug at Breach; the Riot unit crumples — tags mean something.

### Elite Scav — the quest guard
A Scav that learned. Same silhouette and moveset, faster, and **no
overcommit** — the lunge recovers safely, so the tutorial answer stops
working and the player must apply everything else. Guards the memory-chip
room in the hazard area. Rewards like a miniboss.

## Exports

- Reward *ratios* above feed the XP/credit curve solve
  (stats-and-curves.md, last open section — now waiting only on M5 enemy
  counts).
- Contact damage requires player hurt i-frames in the M2 pipeline (already
  planned, DESIGN.md §3.2).
- Drop tables carry the rare ammo drops (rate locked stingy in
  stats-and-curves.md).
