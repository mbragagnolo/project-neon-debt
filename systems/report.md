# Systems report: neon-debt

2026-09-15; 1000 runs per player, seed 1; reaction 0.25 s, dodge 0.16 s, crowd 0.5.

## The district as the rooms hold it

34 rooms, 34 specs read for door-level gates; start unit_14c, hub mezz, boss landlord in collections.

| enemy | placed in the rooms | `placed` in stats.csv | XP each | credits each |
|---|---|---|---|---|
| riot | 7 | 7 | 22 | 15 |
| scav | 31 | 31 | 10 | 5 |
| drone | 17 | 17 | 14 | 7 |
| landlord | 1 | 1 | 200 | 100 |
| elite_scav | 1 | 1 | 45 | 25 |

The district holds 947 XP and 504 credits killing everything once; the curve was solved against 949 XP (0.2% off).

## Targets

| metric | player | stat | want | got | verdict |
|---|---|---|---|---|---|
| level_at_boss | decent | p50 | 5 to 6 | 6 | PASS |
| level_at_boss | skipper | p50 | 5 to 6 | 5 | PASS |
| level_at_boss | thorough | p50 | 6 to 7 | 7 | PASS |
| boss_attempts | decent | p50 | 3 to 8 | 1 | MISS |
| boss_attempts | decent | p90 | 1 to 12 | 1 | PASS |
| minutes | decent | p50 | 30 to 45 | 22 | MISS |
| won | skipper | rate | 0.95 to 1 | 100% | PASS |
| stall_affordable | thorough | rate | 0.8 to 1 | 100% | PASS |
| stall_affordable | skipper | rate | 0 to 0.5 | 0% | PASS |

- boss_attempts for decent: the boss's exit test: beatable in three to eight attempts for a decent player
- minutes for decent: the pitch: a stranger plays it in thirty to forty-five minutes

## thorough

mistake rate 0.15, uptime 0.6, explores all, fights 100% of a new room and 50% of a revisited one, hacks on, quest yes, buys padded_jacket > hp_up > ammo_cap > ammo_refill. 1000 runs, won 100%.

| metric | p10 | p50 | p90 | mean |
|---|---|---|---|---|
| level_at_boss | 7 | 7 | 7 | 7 |
| xp | 1493 | 1493 | 1493 | 1493 |
| credits_earned | 841 | 841 | 841 | 841 |
| credits_spent | 300 | 300 | 300 | 300 |
| deaths | 0 | 0 | 0 | 0 |
| deaths_before_boss | 0 | 0 | 0 | 0 |
| boss_attempts | 1 | 1 | 1 | 1 |
| hits_taken | 6 | 9 | 13 | 9.29 |
| minutes | 36 | 36 | 36 | 36 |
| rooms_visited | 34 | 34 | 34 | 34 |
| farm ratio (XP earned over the district's 947) | | 1.58 | | |
| stall affordable by the last hub visit | | 100% | | |

Deaths: none in any run.
Credits earned by each hub visit (p10 / p50 / p90): visit 1 217 / 217 / 217; visit 2 467 / 467 / 467; visit 3 545 / 545 / 545.
Bought (share of runs): padded_jacket 100%, ammo_cap 100%, hp_up 100%.
Hits landed per run, by enemy: scav: utility_blade 56, pipe_wrench 26, breaker_maul 22; drone: utility_blade 32, breaker_maul 14, pipe_wrench 3; landlord: breaker_maul 10, overload 1; riot: breaker_maul 8, overload 6, pipe_wrench 5; elite_scav: overload 1, breaker_maul 1.

## decent

mistake rate 0.2, uptime 0.5, explores goals, fights 100% of a new room and 30% of a revisited one, hacks on, quest yes, buys padded_jacket > hp_up > ammo_cap. 1000 runs, won 100%.

| metric | p10 | p50 | p90 | mean |
|---|---|---|---|---|
| level_at_boss | 6 | 6 | 6 | 6 |
| xp | 1025 | 1025 | 1025 | 1025 |
| credits_earned | 603 | 603 | 603 | 603 |
| credits_spent | 300 | 300 | 300 | 300 |
| deaths | 0 | 0 | 0 | 0 |
| deaths_before_boss | 0 | 0 | 0 | 0 |
| boss_attempts | 1 | 1 | 1 | 1 |
| hits_taken | 9 | 13 | 17 | 13 |
| minutes | 22 | 22 | 22 | 22 |
| rooms_visited | 29 | 29 | 29 | 29 |
| farm ratio (XP earned over the district's 947) | | 1.08 | | |
| stall affordable by the last hub visit | | 100% | | |

Deaths: none in any run.
Credits earned by each hub visit (p10 / p50 / p90): visit 1 198 / 198 / 198; visit 2 443 / 443 / 443.
Bought (share of runs): padded_jacket 100%, hp_up 100%, ammo_cap 100%.
Hits landed per run, by enemy: scav: utility_blade 50, pipe_wrench 26; drone: utility_blade 28, pipe_wrench 3, breaker_maul 2; landlord: breaker_maul 10, overload 1; riot: breaker_maul 7, pipe_wrench 5, overload 5; elite_scav: overload 1, breaker_maul 1.

## skipper

mistake rate 0.2, uptime 0.5, explores goals, fights 70% of a new room and 20% of a revisited one, hacks off, quest no, buys padded_jacket. 1000 runs, won 100%.

| metric | p10 | p50 | p90 | mean |
|---|---|---|---|---|
| level_at_boss | 5 | 5 | 5 | 5 |
| xp | 783 | 783 | 783 | 783 |
| credits_earned | 418 | 418 | 418 | 418 |
| credits_spent | 140 | 140 | 140 | 140 |
| deaths | 0 | 0 | 0 | 0 |
| deaths_before_boss | 0 | 0 | 0 | 0 |
| boss_attempts | 1 | 1 | 1 | 1 |
| hits_taken | 4 | 7 | 9 | 6.55 |
| minutes | 18 | 18 | 18 | 18 |
| rooms_visited | 29 | 29 | 29 | 29 |
| farm ratio (XP earned over the district's 947) | | 0.83 | | |
| stall affordable by the last hub visit | | 0% | | |

Deaths: none in any run.
Credits earned by each hub visit (p10 / p50 / p90): visit 1 139 / 139 / 139; visit 2 270 / 270 / 270.
Bought (share of runs): padded_jacket 100%.
Hits landed per run, by enemy: scav: utility_blade 18, pipe_wrench 16, breaker_maul 5; drone: utility_blade 18, breaker_maul 3, pipe_wrench 2; landlord: breaker_maul 12; riot: breaker_maul 10, pipe_wrench 5; elite_scav: breaker_maul 2.

## novice

mistake rate 0.35, uptime 0.35, explores goals, fights 100% of a new room and 50% of a revisited one, hacks on, quest yes, buys padded_jacket > hp_up. 1000 runs, won 100%.

| metric | p10 | p50 | p90 | mean |
|---|---|---|---|---|
| level_at_boss | 6 | 6 | 6 | 6 |
| xp | 1083 | 1083 | 1083 | 1083 |
| credits_earned | 632 | 632 | 632 | 632 |
| credits_spent | 230 | 230 | 230 | 230 |
| deaths | 0 | 0 | 0 | 0.00 |
| deaths_before_boss | 0 | 0 | 0 | 0.00 |
| boss_attempts | 1 | 1 | 1 | 1 |
| hits_taken | 21 | 26 | 31 | 26 |
| minutes | 29 | 29 | 29 | 29 |
| rooms_visited | 29 | 29 | 29 | 29 |
| farm ratio (XP earned over the district's 947) | | 1.14 | | |
| stall affordable by the last hub visit | | 100% | | |

Deaths per run by room: armory 0.00, breach_gate_room 0.00.
Credits earned by each hub visit (p10 / p50 / p90): visit 1 217 / 217 / 217; visit 2 467 / 467 / 467.
Bought (share of runs): padded_jacket 100%, hp_up 100%.
Hits landed per run, by enemy: scav: utility_blade 56, pipe_wrench 26, breaker_maul 0; drone: utility_blade 26, breaker_maul 5, pipe_wrench 3; landlord: breaker_maul 10, overload 1, pipe_wrench 0; riot: breaker_maul 7, pipe_wrench 5, overload 5; elite_scav: breaker_maul 1, overload 1, pipe_wrench 0.

## The XP curve against the district

`xp_base` 60, `xp_growth` 1.5; the district holds 947 XP killing everything once (the curve assumed 949).

| level | XP to next | cumulative | share of the district | attack stat | multiplier | HP |
|---|---|---|---|---|---|---|
| 1 | 60 | 0 | 0% | 5 | x1.22 | 40 |
| 2 | 90 | 60 | 6% | 8 | x1.33 | 45 |
| 3 | 135 | 150 | 16% | 11 | x1.43 | 50 |
| 4 | 202 | 285 | 30% | 14 | x1.52 | 55 |
| 5 | 304 | 487 | 51% | 17 | x1.60 | 60 |
| 6 | 456 | 791 | 84% | 20 | x1.67 | 65 |
| 7 | 683 | 1247 | 132% | 23 | x1.73 | 70 |
| 8 | 1025 | 1930 | 204% | 26 | x1.79 | 75 |

## The kill table at the level each enemy is met

Landed damage through DEF (floor 1), hits to kill, seconds at the weapon's rate with the first hit at its commit; `stagger` when one hit meets the threshold; `blocked` when a tag stops the weapon's kind head on.

### scav: 16 HP, DEF 0, threshold 1, met at level 1

| weapon | landed | hits | seconds | note |
|---|---|---|---|---|
| breaker_maul | 22 | 1 | 0.2 | stagger |
| utility_blade | 6 | 3 | 0.8 | stagger |
| pipe_wrench | 10 | 2 | 0.8 | stagger |
| nailgun | 4 | 4 | 0.8 | stagger, 4 energy |
| rivet_gun | 18 | 1 | 0.0 | stagger, 3 energy |
| zipgun | 7 | 3 | 1.3 | stagger, 3 energy |
| overload (hack) | 18 | 1 | | 3 RAM each, stagger |

### elite_scav: 40 HP, DEF 2, threshold 8, met at level 5

| weapon | landed | hits | seconds | note |
|---|---|---|---|---|
| breaker_maul | 27 | 2 | 1.4 | stagger |
| utility_blade | 6 | 7 | 2.2 |  |
| pipe_wrench | 11 | 4 | 2.0 | stagger |
| nailgun | 3 | 14 | 3.2 | 14 energy |
| rivet_gun | 22 | 2 | 1.7 | stagger, 6 energy |
| zipgun | 8 | 5 | 2.7 | stagger, 5 energy |
| overload (hack) | 22 | 2 | | 3 RAM each, stagger |

### drone: 10 HP, DEF 0, threshold 1, met at level 2, tags mechanical

| weapon | landed | hits | seconds | note |
|---|---|---|---|---|
| breaker_maul | 24 | 1 | 0.2 | stagger |
| utility_blade | 7 | 2 | 0.4 | stagger |
| pipe_wrench | 11 | 1 | 0.2 | stagger |
| nailgun | 4 | 3 | 0.5 | stagger, 3 energy |
| rivet_gun | 20 | 1 | 0.0 | stagger, 3 energy |
| zipgun | 8 | 2 | 0.7 | stagger, 2 energy |
| overload (hack) | 20 | 1 | | 3 RAM each, stagger |

### riot: 35 HP, DEF 3, threshold 12, met at level 3, tags mechanical immune_ranged_frontal

| weapon | landed | hits | seconds | note |
|---|---|---|---|---|
| breaker_maul | 23 | 2 | 1.4 | stagger |
| utility_blade | 4 | 9 | 2.9 |  |
| pipe_wrench | 8 | 5 | 2.7 |  |
| nailgun | 1 | 35 | 8.5 | blocked from the front, 35 energy |
| rivet_gun | 18 | 2 | 1.7 | stagger, blocked from the front, 6 energy |
| zipgun | 6 | 6 | 3.3 | blocked from the front, 6 energy |
| overload (hack) | 18 | 2 | | 3 RAM each, stagger |

### landlord: 270 HP, DEF 5, threshold 16, met at level 5

| weapon | landed | hits | seconds | note |
|---|---|---|---|---|
| breaker_maul | 24 | 12 | 13.9 | stagger |
| utility_blade | 3 | 90 | 30.8 |  |
| pipe_wrench | 8 | 34 | 20.8 |  |
| nailgun | 1 | 270 | 67.2 | 270 energy |
| rivet_gun | 19 | 15 | 23.3 | stagger, 45 energy |
| zipgun | 5 | 54 | 35.3 | 54 energy |
| overload (hack) | 19 | 15 | | 3 RAM each, stagger |

## Hits to die

The player's HP at the level each enemy is met, against that enemy's hits: bare, and with every piece of gear worn (DEF 4, +10 HP). Contact is attack power x 0.5.

| enemy | level met | player HP bare / geared | hit bare / geared | hits to die bare / geared | contact hits to die bare |
|---|---|---|---|---|---|
| scav | 1 | 40 / 50 | 6 / 2 | 7 / 25 | 14 |
| elite_scav | 5 | 60 / 70 | 9 / 5 | 7 / 14 | 15 |
| drone | 2 | 45 / 55 | 5 / 1 | 9 / 55 | 23 |
| riot | 3 | 50 / 60 | 10 / 6 | 5 / 10 | 10 |
| landlord | 5 | 60 / 70 | 14 / 10 | 5 / 7 | 9 |

## The economy

| source | count | each | total |
|---|---|---|---|
| riot | 7 | 15 | 105 |
| scav | 31 | 5 | 155 |
| drone | 17 | 7 | 119 |
| landlord | 1 | 100 | 100 |
| elite_scav | 1 | 25 | 25 |
| quest memory_chip | 1 | 60 | 60 |
| **killing everything once** | | | **564** |

| sink | price | once |
|---|---|---|
| padded_jacket | 140 | yes |
| hp_up | 90 | yes |
| ammo_cap | 70 | yes |
| ammo_refill | 10 | no |
| **the stall, every once entry** | **300** | |

Margin killing everything once: 264 credits (1.88x the stall). Enemies come back on every room re-entry, so the district's total is a floor, not a cap; the players' `credits_earned` below say what a route really pays.

## What the model does not know

- The mistake rate and the uptime are the players' numbers, chosen in players.csv; the autoplayer or a playtest calibrates them. Until then a death count is a claim about the shape, and a comparison between two knob settings is what the sim is for.
- Fights are one enemy at a time with the rest of the room raising the chance of a hit; contact damage, projectiles dodged into other projectiles and falls are not modelled.
- Every room's enemies come back on re-entry, as the engine does it, so a player who fights on the way back farms XP and credits; the farm ratio says how much.
- Traversal seconds per room are the players' guesses; the minutes are a shape, not a promise.
