# ui/

HUD (HP, RAM, ammo pips, hack quickslot, XP/level, credits) and the pause menu
(map / inventory-equip / quest log / settings) — DESIGN.md §3.7.

Everything here reads the signal bus; no UI node reaches into gameplay nodes.

- `hud/` — **M2 onward, grown per milestone**
- `menus/`, `map_screen/` — **M5**
