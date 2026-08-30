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

## Open sections (in discussion order)

1. DEF mechanics & minimum damage floor
2. What grows on level-up (proposal: HP/RAM/STR/DEX/INT on the curve, DEF
   gear-only)
3. Number scale (proposal: small — hits 3–25, HP 40–90)
4. RAM & ammo governance (proposal: resources with caps, not stat-scaled)
5. Enemy stat block (proposal: reduced sheet — HP, damage, DEF, XP, credits)
6. Starting values, per-level increments, XP curve constants (`TUNE`, solved
   against district XP total once the enemy roster lands)
