# Stats & curves

**Status: LOCKED.** Every section is closed; the file's exports to later
milestones are listed at the bottom. Constants marked `TUNE` are locked
*decisions* whose *values* stay open to tuning — the XP curve's `base` in
particular is re-solved in M5 against the real roster.

## Stat scaling — LOCKED

Weapon is the base, the stat is a saturating multiplier:

```
damage_raw = weapon_power × stat_multiplier(stat)
stat_multiplier(stat) = 1 + max_bonus × stat / (stat + half_point)
```

| Constant | Value | Meaning |
|---|---|---|
| `max_bonus` | 2.0 `TUNE` | The most a stat can ever add (asymptote: ×3.0 total, never reached) |
| `half_point` | 40 `TUNE` | Stat value at which half of `max_bonus` is earned |

Same curve for STR (melee), DEX (ranged), INT (hacks). Per-verb constants stay
possible later — the constants live in a tuning resource, not code.

Reference values at the placeholder constants:

| Stat | Multiplier | Marginal gain of the previous 10 points |
|---|---|---|
| 0 | ×1.00 | — |
| 10 | ×1.40 | +0.40 |
| 20 | ×1.67 | +0.27 |
| 30 | ×1.86 | +0.19 |
| 40 | ×2.00 | +0.14 |
| 60 | ×2.20 | +0.20 over 20 points |
| 99 | ×2.42 | +0.03 |

### Why

- **Weapon-as-base** makes a found weapon an immediate, visible jump — the
  reward for exploring — while levels compound quietly. This is "gear does the
  differentiation" (DESIGN.md §3.3) expressed in math.
- **Saturation instead of linear** because linear scaling has no ceiling: at
  STR 99 it would multiply a weapon ×5 and force retuning every enemy for
  late-game levels. The soft cap bounds damage forever, so enemy HP tuned for
  the slice survives V2.
- **Early points are the juicy ones, later points never hit zero** — they just
  get quiet. No dead stat, no hard cap cliff.
- The slice itself lives on the steep part of the curve (auto-allocated stats
  reach ~5–20 over six levels). The soft cap is insurance for **V2's manual
  allocation**, decided now so V2 doesn't need a rebalance.
- Rejected alternative: Souls-style piecewise breakpoints ("full value to 30,
  half after"). More quotable to players, but kinked and more knobs — and V1
  players never allocate a point, so that legibility currently buys nothing.
  If V2 wants it visible, the UI can show this smooth curve's effective
  multiplier instead.

## DEF & the damage floor — LOCKED

```
damage = max(1, damage_raw − DEF)
```

- **Floor at 1:** every landed hit does at least 1 damage. DEF can never make
  a target unhittable with the "wrong" verb (V2's every-verb-viable promise
  will demand this anyway), and chip-killing a tank 1 hp at a time stays a
  legitimate desperate tactic instead of a softlock.
- **Flat subtraction's heavy-hit bias is kept as texture, not fixed.** Flat
  DEF taxes fast weak hits proportionally harder than slow heavy ones
  (DEF 4: a 6-damage dagger loses 66%, a 20-damage hammer loses 20%), which
  naturally pushes players toward heavy hits and hacks against armored
  enemies — the Riot unit's job description. It needs real playtesting, and
  it is tuned with **two levers, not one: weapon damage AND attack speed** —
  DPS through armor is `(raw − DEF) × attacks_per_second`, so a fast weapon
  can buy its viability back with speed.
- Consequence for items and the M2 pipeline: **weapons carry `attack_speed`
  as a first-class tuning field**, not something buried in animation timing.
- Tuning warning: at small numbers, low-end enemy DEF values are sensitive —
  DEF 2 vs 4 is a large swing against light weapons. Set enemy DEF last,
  after weapon numbers exist.

## Growth on level-up — LOCKED

The auto-curve raises **HP, RAM, STR, DEX, INT**. **DEF comes from gear
only** — no level ever grants it.

- Level-ups are the system's background hum (auto-allocated, no decision).
  Gear is the only place the player expresses anything, so clothing gets a
  monopoly on survivability: the quest-reward piece is not "+2 of what levels
  already give," it is the only way to take smaller hits.
- Grinding levels makes you hit harder but never tank better — the game
  quietly rewards exploring (find gear) over grinding, the right bias for a
  metroidvania.
- All three attack stats rise in lockstep, so the verbs stay balanced by
  default; differentiation comes from weapons and clothing modifiers only.
- Reference point: SotN raises defense with level indirectly (CON) under
  gear's big swings — and can afford to because it abandons difficulty after
  the first castle. Our boss targets 3–8 attempts, so the damage-taken axis
  stays on one knob (gear). If gear-only DEF proves too punishing in
  playtest, the fallback is a token trickle (+1 DEF every other level) —
  cheap to add, expensive to remove.

## Stat pickups — LOCKED

SotN-style permanent Max Up pickups hidden in exploration spots:

- **2–3 × HP Max Up** and **2–3 × RAM Max Up** in the district (final count
  set during M5 layout; `TUNE` for the size of each bump).
- Implementation: a GameState flag + a stat bump — exploration rewards that
  are not gear, so hidden rooms have something to hold besides the ten items.
- Ranged energy capacity stays a vendor purchase (ammo capacity, DESIGN.md
  §3.3), mirroring SotN's split: the casting resource grows by finding, the
  ammo resource by buying.

## Number scale — LOCKED

Small numbers. Anchor values every stat block is written against (all `TUNE`
as constants, but the *scale* is locked):

| Anchor | Value |
|---|---|
| Player HP, level 1 | ~40 — three big mistakes kill you, not ten |
| Basic melee hit, early | ~6–8 |
| Heavy melee hit, early | ~15–20 |
| Scav HP | ~15–20 — dies in 2–3 melee hits |
| Enemy DEF across the slice | 0–5 (set last; low-end DEF is swingy vs light weapons) |
| Boss HP | low hundreds, never four digits |

- Solo tuning happens in a spreadsheet: `max(1, 7×1.4−3)` is mental math.
  The DEF floor and the heavy-hit bias stay intuitive at this scale.
- Big numbers buy cosmetic meatiness at the cost of ×10 on every tuning
  decision. If hits need to *feel* bigger, that is juice (hitstop, shake,
  SFX) — not zeros.
- Accepted consequence: granularity is coarse. A 6→8 damage weapon is a +33%
  upgrade; there is no room for "+3% better" items. For ten items that is a
  feature — every upgrade is felt. V2's larger pool must differentiate via
  modifiers, not fine damage steps.

## RAM — LOCKED

A capped resource, never stat-scaled — INT scales hack damage only.

- **Cap growth:** the level curve + RAM Max Up pickups (both locked above).
- **Regen:** slow passive trickle everywhere (`TUNE` rate). **Saving fully
  restores RAM**, alongside the save's full heal.
- **Regen rate is a gear-modifier axis** — the gloves' `ram_regen_mult`
  (items.md, Modifier table). Gear is the only way to improve the trickle.

## Ammo / ranged energy — LOCKED

A capped resource, never stat-scaled — DEX scales ranged damage only.

Three faucets, one hierarchy:

1. **Melee hits** — the primary in-combat refill (the locked §3.2 interlock;
   the shoot → close → melee rhythm). Refill per hit `TUNE`.
2. **Enemy drops** — deliberately **rare** (`TUNE`, erring stingy): a
   between-fights top-up, never a reliable income. If playtesters stop
   meleeing because drops keep them stocked, the drop rate is too high.
3. **Vendor** — sells refills, and is the **only** source of cap upgrades.

Rationale: the melee-regen loop is the mechanical spine of the intertwined
kit and the thing a 40-minute playtest can demonstrate; drops and vendor
cover "opened the fight at zero" without competing with it. The rejected
alternative (drops/vendor only — scavenged-commodity ammo) is recorded for
V2 consideration: its scarcity-economy flavor fits The Stacks, and stingy
drop tuning under this model approximates it without deleting the interlock.

## Enemy stat block — LOCKED

Enemies do not run the player's six-stat sheet. Reduced block:

| Field | Notes |
|---|---|
| `hp` | |
| `attack_power` | **Flat** — no stat multiplier on the enemy side. What you author is what it hits for (player DEF and the floor still apply). |
| `def` | 0–5 across the slice; set last (locked tuning warning) |
| `xp_reward` | Feeds the XP curve solve |
| `credit_reward` | Feeds the economy |
| drop table | Includes the rare ammo drops |
| resistance tags | **Binary tags, not percentages** — e.g. `immune_ranged_frontal` (Riot unit), `stunned_by_breach` (mechanical). At our number scale a "30% resist" is invisible; tags are what players can read mid-fight. |

- A Scav with an INT score is bookkeeping with no gameplay output.
- Flat attack keeps threat exactly as authored — no derived math between
  "I typed 8" and "it hits for 8" — which matters when one person tunes
  thirty rooms of encounters.
- V2-safe: independent builds change player scaling, never what a drone
  hits for.

## Starting values & the level curve — LOCKED

The auto-allocated sheet. No player ever spends a point in V1; this table is
the entire progression the level-up moment delivers.

| Stat | Level 1 | Per level | Level 6 | Growth from anywhere else |
|---|---|---|---|---|
| HP | 40 | +5 | 65 | HP Max Up pickups (2–3) |
| RAM | 12 | +2 | 22 | Cyberdeck (pool expansion), RAM Max Up pickups (2–3) |
| STR | 5 | +3 | 20 | — |
| DEX | 5 | +3 | 20 | — |
| INT | 5 | +3 | 20 | — |
| DEF | 0 | **+0** | 0 | **Gear only** — locked above, no level ever grants it |

- **HP 40** is the locked anchor ("three big mistakes kill you"). +5/level is
  sized to hold that sentence roughly true as enemy damage climbs toward the
  boss, rather than to outrun it: 65 HP against a boss hitting for ~15 is
  still four mistakes.
- **RAM 12 = three Firewall casts** at 4 RAM each — the pool-sizing rule
  hacks.md already locked ("a full early pool ≈ 3 casts"). +2/level is
  deliberately stingy: the Cyberdeck is advertised as *the* capacity upgrade
  (DESIGN.md §2), and it cannot be that if six levels already doubled the
  pool. Level-up does **not** refill RAM — the full restore stays a save
  point's job, so the pool has a real cost curve between terminals.
- **STR/DEX/INT 5 → 20** is the "~5–20 over six levels" band the stat-scaling
  section above already promised. In multiplier terms the slice runs
  ×1.22 → ×1.67: **+36% damage from six levels of grinding, against +125%
  for swapping the wrench (8) for the maul (18).** That ratio *is* "gear does
  the differentiation, levels compound quietly" — stated as a number so a
  later retune can be checked against it.
- All three attack stats rise in lockstep, as locked above: the verbs stay
  balanced by default and only weapons and clothing differentiate them.

### What this does to M2's playtest

One number moves. At STR 5 the wrench's authored 8 lands as **10**, not 8.
The Scav still dies in two hits (16 HP), and the lunge, contact and knockback
numbers are flat on the enemy side and therefore untouched — so the M2 tuning
session's conclusions survive contact with the stat sheet. That is the whole
delta, and it is recorded here because "the numbers quietly changed under a
playtested feel" is the failure mode this milestone is most exposed to.

## XP curve — LOCKED (`base` re-solved in M5)

```
xp_to_next(level) = round(base × growth^(level − 1))
```

| Constant | Value | Meaning |
|---|---|---|
| `base` | 60 `TUNE` | XP for the first level-up. The one knob M5 re-solves. |
| `growth` | 1.5 `TUNE` | Per-level multiplier |

| Level | XP for next | Cumulative to reach |
|---|---|---|
| 1 → 2 | 60 | 60 |
| 2 → 3 | 90 | 150 |
| 3 → 4 | 135 | 285 |
| 4 → 5 | 203 | 488 |
| 5 → 6 | 304 | 792 |
| 6 → 7 | 456 | 1248 |

First level-up at 60 XP is six Scavs — minutes in, and deliberately *before*
the first gear pickup (items.md pacing: nothing found in the first ~10
minutes). Levels open the game, gear punctuates it.

### The district budget it was solved against

The open question this section inherited was that the curve wants a district
XP total that does not exist until M5 lays out rooms and M6 finishes the
roster. Rather than defer the whole milestone, the curve is solved against an
**assumed** roster, written down here so the assumption is auditable and
M5 re-solves by editing one constant:

| Enemy | Assumed count | XP each | Total |
|---|---|---|---|
| Scav | 28 | 10 | 280 |
| Watcher drone | 12 | 14 | 168 |
| Riot unit | 8 | 22 | 176 |
| Elite Scav | 3 | 45 | 135 |
| The Landlord | 1 | 200 | 200 |
| | | **Assumed district total** | **959** |

Counts are ~50 enemies across the 25–35 rooms of DESIGN.md §2 — roughly two
per room once traversal and hub rooms are discounted. The per-enemy values
keep the ratios the enemy stat block already implies (`xp_reward` is authored
on the config; only the Scav's 10 exists today, the rest are this table's
proposal for M6).

Against that total:

| Player | XP earned | Lands at |
|---|---|---|
| Skips what it can | ~70% (671) | **Level 5**, most of the way to 6 |
| Clears the critical path | ~85% (815) | **Level 6** |
| Kills everything | 100% (959) | **Level 6**, not halfway to 7 |

Which is DESIGN.md §2's "~level 5–6" for every play style — and level 7 is
unreachable in the slice by construction (1248 > 959), so the curve needs no
level cap and V2 can extend it without a cliff.

**The guard is a test, not vigilance.** `tests/test_xp_curve.gd` asserts that
the cumulative XP to level 6 sits between 70% and 90% of the district budget
recorded above. When M5 lands real room counts and M6 real `xp_reward`
values, the test fails loudly and `base` is re-solved — the curve's shape and
every other number here stay put.

## Exports

- **M3 builds:** the stat sheet and this curve as `PlayerStats` +
  `xp_curve.tres`, the effective-stats layer that folds equipment in
  (items.md modifier table), and `Attack.stat` finally fed from STR/DEX at
  step 4 of the pipeline.
- **The enemy DEF pass** that damage-pipeline.md hands to M3 has, on
  inspection, nothing to act on: the M3 roster is one Scav, whose teaching
  role is spacing and whose DEF stays **0** — armour is the Riot unit's
  lesson. The pass is therefore **deferred to M6**, where the enemies that
  want DEF exist and the full weapon trio is playtested. The gym's DEF-5
  station remains where the number gets felt in the meantime.
- **Credits are a counter in M3** — enemies already author `credit_reward`,
  and M3 accumulates and displays it. Prices, vendor stock and the
  `economy.md` that holds them are **M5's**: writing prices now would be
  inventing numbers for a shop with nothing in it.
- **M4 needs:** the RAM pool above as a live resource, `ram_regen_mult` from
  the gloves consulted by the regen tick, and INT fed to step 4 the same way
  STR and DEX are here.
- **M5 needs:** to re-solve `base` against the real roster, and to spend the
  Cyberdeck's pool expansion and the four Max Up pickups against the RAM and
  HP columns.
