# enemies/

Shared `Enemy` base (patrol → aggro → attack → stagger, XP + loot on death) and
one folder per roster entry (DESIGN.md §3.5).

- `enemy_base.gd`, `scav/` — **M2**
- `drone/`, `riot/`, `boss_landlord/` — **M6**

Each enemy exists to teach one thing: Scav = spacing, Watcher drone = vertical
threat, Riot unit = frontal ranged immunity.
