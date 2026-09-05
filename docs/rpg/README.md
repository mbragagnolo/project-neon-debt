# rpg/

Elaborates DESIGN.md §3.3. Locked so far: credits-only currency; six equip
slots (melee, ranged, head, body, legs, hands); stats auto-allocate on a fixed
curve — gear does the differentiation.

Specs:
- [`stats-and-curves.md`](stats-and-curves.md) — **locked.** Stat scaling, DEF
  and the damage floor, growth on level-up, starting values, the XP curve and
  the district budget it was solved against.
- [`items.md`](items.md) — the ten items: identities, stats, one modifier
  each, and where each is found. Locked but for their names, which wait on
  `narrative/`.
- [`economy.md`](economy.md) — **built (M5).** Stitch's stock and prices,
  the income the district holds, and the one rule: credits never touch an
  unlock.
