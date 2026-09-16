# Elite Scav: encounter note

From `enemies/elite_scav.json` and `enemies/player.json`. Rendered by enemy-designer/scripts/brief.py; edit the json, not this file.

**Role:** gate. **Room:** defaulter_den. **Arrival kit:** pipe_wrench, utility_blade, breaker_maul, zipgun, nailgun, firewall, overload, breach, mag_hook, cyberdeck. **Met at level:** 5.

**Teaches.** The quest-area wall. Same silhouette and moveset as the Scav, faster, and no overcommit: the lunge recovers safely, so bait-and-punish stops working and everything else has to be applied.

Guards the memory chip at the bottom of the Gut, behind the second Breach door, with two Scavs. The tutorial answer is gone; the maul's interrupt, Overload and the i-frames on contact are what is left.

**The answer, measured** (reaction time from player.json; margins in frames):

- `lunge`: dash out -4 f; jump over -1 f; walk out -10 f
  punish in the 0.12 s recovery: Powered utility blade x1

**What the geometry has to give it.**

- A beat: it patrols 200 px each side of where it is placed (444 px (7.4 tiles) of floor) and turns at walls.
- The `lunge` fight wants 678 px (11.3 tiles) of floor: it commits from 150 px, reaches 240 px, and the player's dash-out is 288 px. Less floor and the dash-out is a wall-bump.
- Headroom to jump over it: the box top is 80 px up, the player needs the jump's 168 px plus the body (256 px (4.3 tiles) of air over the floor).
- It notices the player at 560 px and gives up 1000 px from home: placement decides whether it is met at the door or in the middle.

Never type a gap or a floor length from this note into a spec: the level-designer's census reads the reach; this note says what the enemy needs, the census says what the room has.
