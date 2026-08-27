# rpg/

The Castlevania layer: HP/RAM/STR/DEX/INT/DEF, XP curve, gear (DESIGN.md §3.3).

Levels auto-allocate a base stat curve; **gear does the differentiation**. Items
are `Resource` files so balance is data, not code.

- `stats.gd`, `xp_curve.tres` — **M3**
- `items/` (melee, ranged, head, body, legs) — **M3**
- `inventory.gd` — **M3**
