# Scav: encounter note

From `enemies/scav.json` and `enemies/player.json`. Rendered by enemy-designer/scripts/brief.py; edit the json, not this file.

**Role:** pressure. **Room:** hall_14. **Arrival kit:** pipe_wrench, zipgun, firewall. **Met at level:** 1.

**Teaches.** Spacing. Bait the lunge, step in, punish the recovery. The first fight of the game.

The first fight of the game, one Scav on the floor of a two-cell hall. Setup for the whole roster: the loudest tint is a tell, the drained tint is an opening.

**The answer, measured** (reaction time from player.json; margins in frames):

- `lunge`: dash out +4 f; jump over +8 f; walk out -1 f
  punish in the 0.75 s recovery: Hydraulic breaker maul x1, Powered utility blade x2, Pipe wrench x1

**What the geometry has to give it.**

- A beat: it patrols 170 px each side of where it is placed (384 px (6.4 tiles) of floor) and turns at walls.
- The `lunge` fight wants 625 px (10.4 tiles) of floor: it commits from 125 px, reaches 212 px, and the player's dash-out is 288 px. Less floor and the dash-out is a wall-bump.
- Headroom to jump over it: the box top is 78 px up, the player needs the jump's 168 px plus the body (256 px (4.3 tiles) of air over the floor).
- It notices the player at 460 px and gives up 820 px from home: placement decides whether it is met at the door or in the middle.

Never type a gap or a floor length from this note into a spec: the level-designer's census reads the reach; this note says what the enemy needs, the census says what the room has.
