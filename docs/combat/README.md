# combat/

Elaborates DESIGN.md §3.2. The V1 kit is **intertwined** (locked): melee feeds
ranged energy, hacks set up the other verbs, enemies force switching.

Planned specs:
- `damage-pipeline.md` — formula constants, hitstop frames, knockback,
  i-frame durations, and the interlock table (all interlocks are tuning data,
  not hard-wired logic — V2 requirement)
- `hacks.md` — **done**: Firewall / Overload / Breach (defense / damage /
  control), costs, the 1s global cooldown, casting model, acquisition order
