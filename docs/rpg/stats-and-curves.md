# Stats & curves

**Status: in progress** — sections get locked one decision at a time; open
sections are listed at the bottom. Constants marked `TUNE` are placeholders
until combat exists to tune against.

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
- **Regen rate is a gear-modifier axis** — "+X% RAM regen" (already the
  canonical example modifier in DESIGN.md §3.3). Gear is the only way to
  improve the trickle.

## Open sections (in discussion order)

1. **Ammo refill model — conflict to resolve before locking.** Proposed:
   refills from enemy drops or vendor purchase, cap grows via vendor only.
   This collides with the locked §3.2 interlock "ammo regenerates on melee
   hits" (the shoot → close → melee rhythm named as the intertwined kit's
   flagship link). Additive or replacement — see discussion.
2. Enemy stat block (proposal: reduced sheet — HP, damage, DEF, XP, credits)
3. Starting values, per-level increments, XP curve constants (`TUNE`, solved
   against district XP total once the enemy roster lands)
