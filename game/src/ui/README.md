# ui/

HUD (HP, RAM, ammo pips, hack quickslot, XP/level, credits) and the pause menu
(map / inventory-equip / quest log / settings) — DESIGN.md §3.7.

Everything here reads the signal bus; no UI node reaches into gameplay nodes.

- `debug_combat_hud.gd` — **M2**, gym only. HP, ammo and the last damage
  number, so the melee→ammo interlock is visible while it is being tuned; you
  cannot tune "one wrench hit buys one zipgun shot" by feel if the pool is
  imaginary. **M3** grew it by level, XP, credits, DEF, the level-up
  announcement and pickup toasts, every one hanging off a signal declared on
  the bus in M0. The real HUD is M7's and will hang off exactly these signals.
- `menus/equip_screen.gd` — **M3.** The inventory/equip screen
  (docs/ui/screens.md). Built in code for the same reason the debug HUD is:
  it is greybox, and a `.tscn` would be four hundred lines of node text nobody
  can diff. Its load-bearing rule is that every number on it comes from the
  same effective-stats layer the damage pipeline uses — a screen that reads a
  weapon's authored `power` agrees with the item file and disagrees with the
  game.
- `hud/` — **M7**, when the real HUD replaces the gym readout
- `menus/` (pause, quest log), `map_screen/` — **M5**
