# ui/

Elaborates DESIGN.md §3.7. HUD: HP, RAM, ammo pips, hack quickslot, XP/level,
credits. Pause: map / inventory-equip / quest log / settings.

Specs:
- [`screens.md`](screens.md) — the pause shell and its screens. The
  inventory-equip screen is locked (**M3**); map screen and quest log are M5,
  settings M7. Also records M3's HUD additions and the signals they read.
- `hud.md` — the real HUD's layout, **M7**. Until then the gym readout in
  `src/ui/debug_combat_hud.gd` grows one milestone at a time.
