# Systems log

One row per knob tried, appended by tune.py: the date, the knob and its move, what the sim's medians did, the targets before and after, and why. Rows marked `applied` were written into the tables.

- 2026-09-15 knob enemies.landlord.attack_power 14.0 -> 24: no median moved; targets 2/4 -> 2/4 (what it takes for the Landlord to threaten a geared level-6 player: 14 lands 9 through DEF 5, 11 hits to die)
- 2026-09-15 knob players.thorough.fight_fraction_revisit 0.5 -> 0: thorough level_at_boss 7 -> 5, thorough xp 1493 -> 975, thorough credits_earned 841 -> 578, thorough minutes 36.1138 -> 35.7833; targets 1/2 -> 1/2 (level 7 at the boss comes from re-fighting respawns on the way back, not from the district's 947 XP)
- 2026-09-15 knob gear.linesman_gloves.defense 1 -> 0: no median moved; targets 3/6 -> 3/6 (applied) (one DEF off the gear stack (5 to 4): a Scav's 6 lands 2 on a geared player, not 1; the gloves' identity is RAM regen, not armour)
- 2026-09-15 knob enemies.landlord.hp 240 -> 270; enemies.landlord.def 4 -> 5: decent minutes 21.5739 -> 21.6155, novice minutes 28.6169 -> 28.6765; targets 2/4 -> 2/4 (applied) (the Landlord raised slightly: 270 HP and DEF 5 (the top of the locked range), so the maul lands 24 and needs 12 hits)
