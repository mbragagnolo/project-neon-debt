# combat/

Elaborates DESIGN.md §3.2. The V1 kit is **intertwined** (locked): melee feeds
ranged energy, hacks set up the other verbs, enemies force switching.

Specs:
- `damage-pipeline.md` — **done**: the eleven-step ordered pipeline,
  hitstop tiers, knockback, i-frames, multi-hit, attack speed, contact
  damage, ranged aiming, death, and the melee→ammo interlock carried as
  weapon data rather than hard-wired logic (the V2 requirement)
- `hacks.md` — **done**: Firewall / Overload / Breach (defense / damage /
  control), costs, the 1s global cooldown, casting model, acquisition order
