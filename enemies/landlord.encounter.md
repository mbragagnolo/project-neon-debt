# The Landlord: encounter note

From `enemies/landlord.json` and `enemies/player.json`. Rendered by enemy-designer/scripts/brief.py; edit the json, not this file.

**Role:** gate. **Room:** collections. **Arrival kit:** pipe_wrench, utility_blade, breaker_maul, zipgun, nailgun, rivet_gun, firewall, overload, breach, mag_hook, cyberdeck, sidewinder. **Met at level:** 5.

**Teaches.** The wall worth climbing. DEF blunts light hits, only heavy hits and Overload interrupt him, the slam punishes standing on the floor, the beam punishes standing still, and the drones he calls are what Breach is for. Every verb has a job.

The arena seals while he lives: a flat floor for the slam, two one-way ledges and a dais in the middle so the slam has an answer, nothing to hide behind. Phase two calls two Watcher drones; Breach is what stops two guns in the air while he swings.

**The answer, measured** (reaction time from player.json; margins in frames):

- `baton`: dash out +5 f; jump over +6 f; walk out +7 f
  punish in the 0.6 s recovery: Hydraulic breaker maul x1, Powered utility blade x2, Pipe wrench x1
- `slam`: leave the floor +39 f
  punish in the 0.6 s recovery: Hydraulic breaker maul x1, Powered utility blade x2, Pipe wrench x1
- `beam`: step aside at its shortest range -1 f; dash at its shortest range -1 f; step aside at full range +63 f; dash at full range +64 f
  punish in the 0.6 s recovery: Hydraulic breaker maul x1, Powered utility blade x2, Pipe wrench x1

**What the geometry has to give it.**

- The `baton` fight wants 826 px (13.8 tiles) of floor: it commits from 250 px, reaches 288 px, and the player's dash-out is 288 px. Less floor and the dash-out is a wall-bump.
- Headroom to jump over it: the box top is 111 px up, the player needs the jump's 168 px plus the body (256 px (4.3 tiles) of air over the floor).
- The `slam` needs a floor for the waves and something off it to stand on: a ledge at least 52 px up within a jump (168 px).
- The `beam` fires from 380 px out; the room's width decides whether it is ever used.
- Phase two summons {'drone': 2}: air for them above the arena (see the drone's note).
- It notices the player at 4000 px and gives up 100000 px from home: placement decides whether it is met at the door or in the middle.

Never type a gap or a floor length from this note into a spec: the level-designer's census reads the reach; this note says what the enemy needs, the census says what the room has.
