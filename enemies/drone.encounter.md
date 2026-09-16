# Watcher drone: encounter note

From `enemies/drone.json` and `enemies/player.json`. Rendered by enemy-designer/scripts/brief.py; edit the json, not this file.

**Role:** puzzle. **Room:** roof_span. **Arrival kit:** pipe_wrench, zipgun, firewall, mag_hook. **Met at level:** 2.

**Teaches.** Vertical threat, and the ranged verb. It hovers above melee reach and lobs slow, dodgeable shots; the answer is to aim up. Mechanical: Breach drops it out of the air.

First met on the roof with two of them over three Scavs. The puzzle is reaching it; the zipgun is the intended answer and the roof is open sky.

**The answer, measured** (reaction time from player.json; margins in frames):

- `shot`: step aside from its station +33 f; dash from its station +32 f

**What the geometry has to give it.**

- Air above the floor: at least 272 px (4.5 tiles) for it to hold its station (210 px over the player's centre). A lower ceiling pins it into melee reach and the lesson changes.
- Width: it stands off 240 px to one side and never crosses over; a room narrower than 532 px (8.9 tiles) pushes it into the wall.
- The shot travels 340 px/s for 2.4 s (816 px (13.6 tiles)); cover within that is cover.
- It notices the player at 620 px and gives up 1100 px from home: placement decides whether it is met at the door or in the middle.

Never type a gap or a floor length from this note into a spec: the level-designer's census reads the reach; this note says what the enemy needs, the census says what the room has.
