# Matchup: reaction 0.25 s, dash 0.16 s / 288 px, jump 168 px in 0.36 s, run 450 px/s, body 48x88

## Watcher drone at level 2 (STR/DEX/INT 8, player HP 45); hp 10, DEF 0, threshold 1, tags ['mechanical']
teaches: Vertical threat, and the ranged verb. It hovers above melee reach and lobs slow, dodgeable shots; the answer is to aim up. Mechanical: Breach drops it out of the air.

contact: 2.5 a touch (18 touches kill at level 2); i-frames 0.85 s

### shot (projectile): tell 0.45 s, active 0.0 s, recovery 0.0 s, cooldown 2.2 s; hits for 5 (9 kill; 18 through Firewall)
| dodge | needs | margin | |
|---|---|---|---|
| step aside from its station | 0.39 s | +33 f yes | 319 px at 340 px/s = 0.94 s of flight; 64 px to clear |
| dash from its station | 0.41 s | +32 f yes | already moving when it fires: no reaction to pay |
punish: no recovery state; the interval between shots is the window

### reach
- Hydraulic breaker maul: at the jump's apex the box top is 20 px below the body's underside (reachable); horizontal reach 110 px against a 240 px stand-off, closed at 220 px/s
- Powered utility blade: at the jump's apex the box top is 8 px below the body's underside (reachable); horizontal reach 76 px against a 240 px stand-off, closed at 220 px/s
- Pipe wrench: at the jump's apex the box top is 12 px below the body's underside (reachable); horizontal reach 88 px against a 240 px stand-off, closed at 220 px/s

### kill (arrival kit: firewall, mag_hook, pipe_wrench, zipgun)
| with | kind | a hit | hits | seconds | |
|---|---|---|---|---|---|
| Hydraulic breaker maul | melee | 24 | 1 | 0.20 | interrupts; not in the arrival kit |
| Modified nailgun | ranged | 4 | 3 | 0.50 | interrupts; 3 energy; not in the arrival kit |
| Rivet gun | ranged | 20 | 1 | 0.00 | interrupts; 3 energy; not in the arrival kit |
| Powered utility blade | melee | 7 | 2 | 0.44 | interrupts; not in the arrival kit |
| Pipe wrench | melee | 11 | 1 | 0.16 | interrupts |
| Zipgun | ranged | 8 | 2 | 0.67 | interrupts; 2 energy |
| Breach | hack | 0 | 0 | 0.00 | stuns for 1.5 s; not in the arrival kit |
| Overload | hack | 20 | 1 | 0.00 | interrupts; 3 RAM; not in the arrival kit |

## Elite Scav at level 5 (STR/DEX/INT 17, player HP 60); hp 40, DEF 2, threshold 8, tags none
teaches: The quest-area wall. Same silhouette and moveset as the Scav, faster, and no overcommit: the lunge recovers safely, so bait-and-punish stops working and everything else has to be applied.

contact: 4.5 a touch (14 touches kill at level 5); i-frames 0.85 s

### lunge (melee): tell 0.34 s, active 0.2 s, recovery 0.12 s, cooldown 0.45 s; hits for 9 (7 kill; 14 through Firewall)
| dodge | needs | margin | |
|---|---|---|---|
| dash out | 0.41 s | -4 f NO | the dash carries 288 px past a lunge that reaches 240 px |
| jump over | 0.35 s | -1 f NO | feet clear the box top (80 px up) 0.10 s into the jump |
| walk out | 0.50 s | -10 f NO | from the trigger distance 150 px, 114 px to clear at 450 px/s |
| punish with | hits in the window | window | |
|---|---|---|---|
| Hydraulic breaker maul | 0 | -5 f | the swing outlasts the recovery |
| Powered utility blade | 1 | +1 f | 6 a hit |
| Pipe wrench | 0 | -2 f | the swing outlasts the recovery |
after a dash-out the player is 132 px from it: 0.29 s to close, which a jump-over does not pay

### kill (arrival kit: breach, breaker_maul, cyberdeck, firewall, mag_hook, nailgun, overload, pipe_wrench, utility_blade, zipgun)
| with | kind | a hit | hits | seconds | |
|---|---|---|---|---|---|
| Hydraulic breaker maul | melee | 27 | 2 | 1.45 | interrupts |
| Modified nailgun | ranged | 3 | 14 | 3.25 | flinch; 14 energy |
| Rivet gun | ranged | 22 | 2 | 1.67 | interrupts; 6 energy; not in the arrival kit |
| Powered utility blade | melee | 6 | 7 | 2.17 | flinch |
| Pipe wrench | melee | 11 | 4 | 2.04 | interrupts |
| Zipgun | ranged | 8 | 5 | 2.67 | interrupts; 5 energy |
| Breach | hack | 0 | 0 | 0.00 | does nothing: not mechanical |
| Overload | hack | 22 | 2 | 1.00 | interrupts; 6 RAM |

## The Landlord at level 5 (STR/DEX/INT 17, player HP 60); hp 270, DEF 5, threshold 16, tags none
teaches: The wall worth climbing. DEF blunts light hits, only heavy hits and Overload interrupt him, the slam punishes standing on the floor, the beam punishes standing still, and the drones he calls are what Breach is for. Every verb has a job.

contact: 7 a touch (9 touches kill at level 5); i-frames 0.85 s

### baton (melee): tell 0.5 s, active 0.3 s, recovery 0.6 s, cooldown 0.4 s; hits for 14 (5 kill; 9 through Firewall); phases [1, 2]
| dodge | needs | margin | |
|---|---|---|---|
| dash out | 0.41 s | +5 f yes | the dash carries 288 px past a lunge that reaches 288 px |
| jump over | 0.40 s | +6 f yes | feet clear the box top (111 px up) 0.15 s into the jump |
| walk out | 0.39 s | +7 f yes | from the trigger distance 250 px, 62 px to clear at 450 px/s |
| punish with | hits in the window | window | |
|---|---|---|---|
| Hydraulic breaker maul | 1 | +24 f | 24 a hit, interrupts: each hit adds 0.45 s of stagger |
| Powered utility blade | 2 | +30 f | 3 a hit |
| Pipe wrench | 1 | +26 f | 8 a hit |
after a dash-out the player is 126 px from it: 0.28 s to close, which a jump-over does not pay

### slam (projectile): tell 0.7 s, active 0.0 s, recovery 0.6 s, cooldown 1.1 s; hits for 12 (5 kill; 10 through Firewall); phases [1, 2]
| dodge | needs | margin | |
|---|---|---|---|
| leave the floor | 0.29 s | +39 f yes | tell 0.7 s plus 0.24 s of wave travel from his stand-off (150 px); the wave is 30 px tall |
| punish with | hits in the window | window | |
|---|---|---|---|
| Hydraulic breaker maul | 1 | +24 f | 24 a hit, interrupts: each hit adds 0.45 s of stagger |
| Powered utility blade | 2 | +30 f | 3 a hit |
| Pipe wrench | 1 | +26 f | 8 a hit |
answer: leave the floor: a ledge or the dais

### beam (projectile): tell 0.8 s, active 0.0 s, recovery 0.6 s, cooldown 3.0 s; hits for 14 (5 kill; 9 through Firewall); phases [2]
| dodge | needs | margin | |
|---|---|---|---|
| step aside at its shortest range | 0.42 s | -1 f NO | 380 px at 950 px/s = 0.40 s of flight; 78 px to clear |
| dash at its shortest range | 0.41 s | -1 f NO | already moving when it fires: no reaction to pay |
| step aside at full range | 0.42 s | +63 f yes | 1400 px at 950 px/s = 1.47 s of flight; 78 px to clear |
| dash at full range | 0.41 s | +64 f yes | already moving when it fires: no reaction to pay |
| punish with | hits in the window | window | |
|---|---|---|---|
| Hydraulic breaker maul | 1 | +24 f | 24 a hit, interrupts: each hit adds 0.45 s of stagger |
| Powered utility blade | 2 | +30 f | 3 a hit |
| Pipe wrench | 1 | +26 f | 8 a hit |

### kill (arrival kit: breach, breaker_maul, cyberdeck, firewall, mag_hook, nailgun, overload, pipe_wrench, rivet_gun, sidewinder, utility_blade, zipgun)
| with | kind | a hit | hits | seconds | |
|---|---|---|---|---|---|
| Hydraulic breaker maul | melee | 24 | 12 | 13.95 | interrupts |
| Modified nailgun | ranged | 1 | 270 | 67.25 | flinch; 270 energy |
| Rivet gun | ranged | 19 | 15 | 23.33 | interrupts; 45 energy |
| Powered utility blade | melee | 3 | 90 | 30.79 | flinch |
| Pipe wrench | melee | 8 | 34 | 20.79 | flinch |
| Zipgun | ranged | 5 | 54 | 35.34 | flinch; 54 energy |
| Breach | hack | 0 | 0 | 0.00 | does nothing: not mechanical |
| Overload | hack | 19 | 15 | 14.00 | interrupts; 45 RAM |

phase at 50% hp: 1.4 s invulnerable, summons {'drone': 2}, cooldown x0.7, speed x1.3, adds ['beam']

## Riot unit at level 3 (STR/DEX/INT 11, player HP 50); hp 35, DEF 3, threshold 12, tags ['mechanical', 'immune_ranged_frontal']
teaches: Heavy hits and hacks. Shots ping off the front, light hits only flinch it; get behind it, hit it heavy, or hack it. Mechanical: Breach stuns it, Overload ignores the shield and interrupts it.

contact: 5 a touch (10 touches kill at level 3); i-frames 0.85 s

### lunge (melee): tell 0.6 s, active 0.25 s, recovery 0.5 s, cooldown 0.9 s; hits for 10 (5 kill; 10 through Firewall)
| dodge | needs | margin | |
|---|---|---|---|
| dash out | 0.41 s | +11 f yes | the dash carries 288 px past a lunge that reaches 190 px |
| jump over | 0.37 s | +14 f yes | feet clear the box top (93 px up) 0.12 s into the jump |
| walk out | 0.39 s | +12 f yes | from the trigger distance 150 px, 64 px to clear at 450 px/s |
| punish with | hits in the window | window | |
|---|---|---|---|
| Hydraulic breaker maul | 1 | +18 f | 23 a hit, interrupts: each hit adds 0.4 s of stagger |
| Powered utility blade | 2 | +24 f | 4 a hit |
| Pipe wrench | 1 | +20 f | 8 a hit |
after a dash-out the player is 193 px from it: 0.43 s to close, which a jump-over does not pay

### kill (arrival kit: cyberdeck, firewall, mag_hook, pipe_wrench, zipgun)
| with | kind | a hit | hits | seconds | |
|---|---|---|---|---|---|
| Hydraulic breaker maul | melee | 23 | 2 | 1.45 | interrupts; not in the arrival kit |
| Modified nailgun | ranged | 1 | 35 | 8.50 | flinch; from behind only; 35 energy; not in the arrival kit |
| Rivet gun | ranged | 18 | 2 | 1.67 | interrupts; from behind only; 6 energy; not in the arrival kit |
| Powered utility blade | melee | 4 | 9 | 2.86 | flinch; not in the arrival kit |
| Pipe wrench | melee | 8 | 5 | 2.66 | flinch |
| Zipgun | ranged | 6 | 6 | 3.33 | flinch; from behind only; 6 energy |
| Breach | hack | 0 | 0 | 0.00 | stuns for 1.5 s; not in the arrival kit |
| Overload | hack | 18 | 2 | 1.00 | interrupts; 6 RAM; not in the arrival kit |

## Scav at level 1 (STR/DEX/INT 5, player HP 40); hp 16, DEF 0, threshold 1, tags none
teaches: Spacing. Bait the lunge, step in, punish the recovery. The first fight of the game.

contact: 3 a touch (14 touches kill at level 1); i-frames 0.85 s

### lunge (melee): tell 0.48 s, active 0.2 s, recovery 0.75 s, cooldown 0.55 s; hits for 6 (7 kill; 14 through Firewall)
| dodge | needs | margin | |
|---|---|---|---|
| dash out | 0.41 s | +4 f yes | the dash carries 288 px past a lunge that reaches 212 px |
| jump over | 0.35 s | +8 f yes | feet clear the box top (78 px up) 0.10 s into the jump |
| walk out | 0.50 s | -1 f NO | from the trigger distance 125 px, 111 px to clear at 450 px/s |
| punish with | hits in the window | window | |
|---|---|---|---|
| Hydraulic breaker maul | 1 | +33 f | 22 a hit, interrupts: each hit adds 0.3 s of stagger |
| Powered utility blade | 2 | +39 f | 6 a hit, interrupts: each hit adds 0.3 s of stagger |
| Pipe wrench | 1 | +35 f | 10 a hit, interrupts: each hit adds 0.3 s of stagger |
after a dash-out the player is 156 px from it: 0.35 s to close, which a jump-over does not pay

### kill (arrival kit: firewall, pipe_wrench, zipgun)
| with | kind | a hit | hits | seconds | |
|---|---|---|---|---|---|
| Hydraulic breaker maul | melee | 22 | 1 | 0.20 | interrupts; not in the arrival kit |
| Modified nailgun | ranged | 4 | 4 | 0.75 | interrupts; 4 energy; not in the arrival kit |
| Rivet gun | ranged | 18 | 1 | 0.00 | interrupts; 3 energy; not in the arrival kit |
| Powered utility blade | melee | 6 | 3 | 0.79 | interrupts; not in the arrival kit |
| Pipe wrench | melee | 10 | 2 | 0.79 | interrupts |
| Zipgun | ranged | 7 | 3 | 1.33 | interrupts; 3 energy |
| Breach | hack | 0 | 0 | 0.00 | does nothing: not mechanical; not in the arrival kit |
| Overload | hack | 18 | 1 | 0.00 | interrupts; 3 RAM; not in the arrival kit |

