# Autoplayer: 2026-09-15-retune

110 runs, policy route, 2 seeds, 113.4 s of wall time; diffed against 2026-09-15.

## What changed

- collections_lift: hits taken per run 3.7 -> 3.2
- east_ledges: reach failures per run 0.8 -> 1.0
- east_ledges: hits taken per run 4.5 -> 5.2
- gut_lift: reach failures per run 3.6 -> 3.2
- lift_shaft: deaths per run 0.2 -> 0.0
- lift_shaft: hits taken per run 3.5 -> 2.2
- mezz: hits taken per run 1.0 -> 0.0 (no enemy attacked: a hazard)

## Rooms

| room | runs | exits taken / tried | never taken | seconds to exit (p50) | deaths | hits taken | enemy attacks | landed | kills | reach fails | fell back | talks | worst waypoint |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| armory | 4 | 2 / 2 | - | 2: 7 | 0.0 | 1.5 | 1.0 | 2.5 | 0.5 | 0.0 | 0.0 | 0.0 |  |
| armory_chute | 6 | 2 / 2 | - | 2: 3 | 0.0 | 0.0 | 0.0 | 0.0 | 0.0 | 0.0 | 0.0 | 0.0 |  |
| breach_gate_room | 4 | 2 / 2 | - | 2: 42 | 0.0 | 0.0 | 0.0 | 0.0 | 0.0 | 2.5 | 0.0 | 0.0 | (390, 1020) x2 |
| catwalks | 2 | 0 / 0 | - | - | 0.0 | 0.0 | 0.0 | 0.0 | 0.0 | 0.0 | 0.0 | 0.0 |  |
| collections | 2 | 0 / 0 | - | - | 0.0 | 0.0 | 0.0 | 0.0 | 0.0 | 0.0 | 0.0 | 0.0 |  |
| collections_lift | 6 | 2 / 4 | 2 | 1: 14 | 0.0 | 3.2 | 2.8 | 4.0 | 1.3 | 1.0 | 0.0 | 0.0 | (1410, 1020) x2 |
| collections_lobby | 4 | 4 / 4 | - | 1: 4, 2: 4 | 0.0 | 0.0 | 0.0 | 0.0 | 0.0 | 0.0 | 0.0 | 0.0 |  |
| defaulter_den | 4 | 4 / 4 | - | 1: 10, 2: 10 | 0.0 | 4.0 | 3.5 | 7.5 | 2.0 | 0.0 | 0.0 | 0.0 |  |
| drain_riser | 8 | 0 / 2 | 2 | - | 0.0 | 0.0 | 0.5 | 0.5 | 0.2 | 1.2 | 0.0 | 0.0 | (510, 4260) x2 |
| east_ledges | 4 | 4 / 4 | 2 | 1: 0, 3: 8 | 0.5 | 5.2 | 13.0 | 3.0 | 1.5 | 1.0 | 0.0 | 0.0 | (3270, 540) x2 |
| gut_cistern | 2 | 0 / 0 | - | - | 0.0 | 0.0 | 0.0 | 0.0 | 0.0 | 0.0 | 0.0 | 0.0 |  |
| gut_deep | 4 | 2 / 2 | - | 2: 8 | 0.0 | 2.0 | 2.5 | 4.5 | 1.5 | 0.0 | 0.0 | 0.0 |  |
| gut_lift | 10 | 4 / 8 | 3 | 1: 0, 2: 4 | 0.0 | 1.2 | 2.8 | 0.1 | 0.1 | 3.2 | 0.0 | 0.0 | (390, 1020) x4 |
| gut_pumps | 8 | 2 / 12 | 1, 2 | 3: 2 | 1.0 | 5.8 | 2.4 | 1.5 | 0.5 | 1.5 | 0.0 | 0.0 | (1470, 1020) x2 |
| gut_stair | 8 | 2 / 8 | 1 | 2: 2 | 0.0 | 0.5 | 1.2 | 1.8 | 0.8 | 1.0 | 0.5 | 0.0 | (510, 420) x2 |
| hall_13 | 8 | 4 / 4 | - | 1: 9, 2: 10 | 0.0 | 0.0 | 0.5 | 2.0 | 1.0 | 0.0 | 0.0 | 0.0 |  |
| hall_14 | 6 | 4 / 4 | - | 1: 10, 2: 9 | 0.0 | 0.0 | 0.7 | 1.3 | 0.7 | 0.0 | 0.0 | 0.0 |  |
| lift_base | 16 | 4 / 8 | - | 1: 8, 2: 0 | 0.0 | 0.0 | 0.0 | 0.0 | 0.0 | 1.5 | 0.1 | 0.0 | (1590, 1020) x4 |
| lift_shaft | 4 | 2 / 7 | 2 | 1: 3 | 0.0 | 2.2 | 8.2 | 0.5 | 0.5 | 0.5 | 0.8 | 0.0 | (1110, 1020) x2 |
| maintenance_closet | 2 | 0 / 0 | - | - | 0.0 | 0.0 | 0.0 | 0.0 | 0.0 | 0.0 | 0.0 | 0.0 |  |
| mezz | 6 | 4 / 4 | - | 2: 33, 3: 29 | 0.0 | 0.0 | 0.0 | 0.0 | 0.0 | 0.3 | 0.0 | 1.3 | (1350, 720) x2 |
| mezz_east | 10 | 6 / 8 | - | 1: 0, 2: 10, 3: 9 | 0.0 | 1.0 | 1.2 | 1.6 | 0.8 | 1.0 | 0.0 | 0.0 | (930, 60) x4 |
| pawn_back | 10 | 6 / 4 | - | 1: 0, 2: 4, 3: 0 | 0.0 | 0.0 | 0.0 | 0.0 | 0.0 | 0.0 | 0.0 | 0.0 |  |
| roof_access | 10 | 12 / 12 | - | 1: 2, 2: 3, 3: 3 | 0.0 | 0.0 | 0.0 | 0.0 | 0.0 | 0.0 | 0.0 | 0.0 |  |
| roof_gap | 8 | 2 / 2 | - | 1: 4 | 0.0 | 0.0 | 0.5 | 0.0 | 0.0 | 0.0 | 0.0 | 0.0 |  |
| roof_span | 10 | 4 / 4 | - | 1: 17, 2: 0 | 0.0 | 0.4 | 2.6 | 2.4 | 1.2 | 0.0 | 0.0 | 0.0 |  |
| server_nook | 4 | 4 / 4 | - | 1: 4, 2: 4 | 0.0 | 0.0 | 2.0 | 0.0 | 0.0 | 0.0 | 0.0 | 0.0 |  |
| service_tunnel | 8 | 4 / 4 | - | 1: 14, 2: 18 | 0.0 | 2.2 | 1.5 | 5.2 | 1.5 | 0.0 | 0.0 | 0.0 |  |
| stairwell_east | 12 | 4 / 6 | 1 | 2: 22 | 0.0 | 0.0 | 0.0 | 0.0 | 0.0 | 1.2 | 0.0 | 0.0 | (810, 1020) x2 |
| underpass | 10 | 12 / 12 | - | 1: 5, 2: 15, 3: 5 | 0.0 | 3.0 | 2.2 | 9.0 | 2.8 | 0.0 | 0.0 | 0.0 |  |
| unit_14c | 110 | 2 / 2 | - | 1: 4 | 0.0 | 0.0 | 0.0 | 0.0 | 0.0 | 0.0 | 0.0 | 0.0 |  |
| west_stair | 8 | 2 / 8 | 2, 3 | 1: 10 | 0.0 | 0.5 | 1.2 | 1.8 | 0.8 | 5.2 | 0.0 | 0.0 | (810, 1620) x4 |

Where the deaths cluster (120 px cells, count):

- east_ledges: (3000, 960) x1
- gut_pumps: (2880, 2040) x4

## The bot against the enemies

| enemy | attacks seen | hits taken | taken per attack | landed | kills |
|---|---|---|---|---|---|
| drone | 152 | 55 | 0.36 | 7 | 7 |
| elite_scav | 8 | 8 | 1.00 | 10 | 0 |
| riot | 42 | 79 | 1.88 | 102 | 20 |
| scav | 91 | 55 | 0.60 | 218 | 96 |

Over every run: 197 hits taken from 293 enemy attacks (0.67 per attack), 337 hits landed in 2185 s of aggro (0.15 per second). These are the bot's numbers for the systems-designer's players.csv (mistake rate, uptime), not a person's; a person's come from a playtest.
