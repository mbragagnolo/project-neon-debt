# Riot unit: encounter note

From `enemies/riot.json` and `enemies/player.json`. Rendered by enemy-designer/scripts/brief.py; edit the json, not this file.

**Role:** gate. **Room:** underpass. **Arrival kit:** pipe_wrench, zipgun, firewall, mag_hook, cyberdeck. **Met at level:** 3.

**Teaches.** Heavy hits and hacks. Shots ping off the front, light hits only flinch it; get behind it, hit it heavy, or hack it. Mechanical: Breach stuns it, Overload ignores the shield and interrupts it.

First met in the underpass among three Scavs, before Overload and the maul: the wrench flinches it and shots ping off, so the first answer is to get behind it.

**The answer, measured** (reaction time from player.json; margins in frames):

- `lunge`: dash out +11 f; jump over +14 f; walk out +12 f
  punish in the 0.5 s recovery: Hydraulic breaker maul x1, Powered utility blade x2, Pipe wrench x1

**What the geometry has to give it.**

- A beat: it patrols 120 px each side of where it is placed (300 px (5.0 tiles) of floor) and turns at walls.
- The `lunge` fight wants 628 px (10.5 tiles) of floor: it commits from 150 px, reaches 190 px, and the player's dash-out is 288 px. Less floor and the dash-out is a wall-bump.
- Headroom to jump over it: the box top is 93 px up, the player needs the jump's 168 px plus the body (256 px (4.3 tiles) of air over the floor).
- It notices the player at 520 px and gives up 900 px from home: placement decides whether it is met at the door or in the middle.

Never type a gap or a floor length from this note into a spec: the level-designer's census reads the reach; this note says what the enemy needs, the census says what the room has.
