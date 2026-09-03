# ui/

HUD (HP, RAM, ammo pips, hack quickslot, XP/level, credits) and the pause menu
(map / inventory-equip / quest log / settings) — DESIGN.md §3.7.

Everything here reads the signal bus; no UI node reaches into gameplay nodes.

- `debug_combat_hud.gd` — **M2**, gym only. HP, ammo and the last damage
  number, so the melee→ammo interlock is visible while it is being tuned; you
  cannot tune "one wrench hit buys one zipgun shot" by feel if the pool is
  imaginary. The real HUD is M7's and will hang off exactly these signals.
- `hud/` — **M2 onward, grown per milestone**
- `menus/`, `map_screen/` — **M5**
