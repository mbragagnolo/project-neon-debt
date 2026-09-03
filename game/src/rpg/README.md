# rpg/

The Castlevania layer: HP/RAM/STR/DEX/INT/DEF, XP curve, gear (DESIGN.md §3.3).

Levels auto-allocate a base stat curve; **gear does the differentiation**. Items
are `Resource` files so balance is data, not code.

- `item.gd` / `clothing.gd` — **M3.** The six-slot item model. `Weapon`
  extends `Item`, so a wrench and a jacket are the same kind of thing to the
  inventory and different kinds of thing to everyone else.
- `items/` — **M3.** The four clothing `.tres` files, plus `catalog.tres`:
  every item in the slice, the id → resource lookup a save file needs, and the
  starting kit as *data*. Weapon `.tres` files stay in `combat/weapons/` next
  to the scripts that give them behaviour — one home per item, and the split
  is by what reads them, not by what they are.
- `stats.gd` (autoload `PlayerStats`) + `xp_curve.tres` / `stat_curve.tres` —
  **M3.** Level, lifetime XP, credits, and the *effective* sheet that folds
  equipment in. Everything outside it asks for the effective values.
- `inventory.gd` (autoload `Inventory`) — **M3.** Owned ids plus one item per
  slot, and the four modifier reads.

Both are autoloads rather than nodes on the player: from M5 the player is
re-instanced per room, so progression or gear living on that node would be
handed back at every door. Both register with `GameState` to be saved.
