# Elite Scav: character brief

From `enemies/elite_scav.json`; the numbers are the machine's, the look is the design's. Rendered by enemy-designer/scripts/brief.py; edit the json, not this file.

**Role.** The quest-area wall. Same silhouette and moveset as the Scav, faster, and no overcommit: the lunge recovers safely, so bait-and-punish stops working and everything else has to be applied. Archetype: veteran; the encounter's role: gate.

**Look.** The Scav's body and rig, re-dressed. Coat and hood in black and concrete grey, cleaner and better-fitting than any Scav's: he is paid. The pipe is a red-painted rebar cutter with a lick of tape at the grip. The eye is magenta, not amber: somebody else's money is behind it. Stands straighter than a Scav in idle, hunches only to lunge.

**Silhouette.** Identical to the Scav. That is the point. The body box is 44x80 px and does not move for art; feet on its bottom edge.

**Colour.** Accent `magenta`; palette `black_l`, `concrete1`, `red`, `red_d`, `magenta`. One accent, two at most.

**The tell as a pose.** The state tint blends over the sprite in the engine, so the pose has to agree with it, never carry it alone:

- `windup` (Windup) holds 0.34 s (21 frames) for the `lunge` attack: plants, the loudest tint on screen; aims once on entry
- `recover` (Recover) holds 0.12 s: drained tint; the punish window

**Rig parts.** the Scav's, re-textured.

**Clips.** The state names are the clip names; a missing clip falls back to `idle` in the engine.

| clip | state | held for | |
|---|---|---|---|
| `idle` | Patrol | until it changes its mind | a beat of patrol_range px each side of home, patrol_pause s at each end; turns at walls |
| `run` | Patrol | until it changes its mind | a beat of patrol_range px each side of home, patrol_pause s at each end; turns at walls |
| `run` | Chase | until it changes its mind | closes at chase_speed; leashes home past give_up_range |
| `windup` | Windup | 0.34 s (21 f) | plants, the loudest tint on screen; aims once on entry |
| `lunge` | Lunge | 0.2 s (12 f) |  |
| `recover` | Recover | 0.12 s (8 f) | drained tint; the punish window |
| `stagger` | Stagger | 0.28 s (17 f) |  |
| `dead` | Dead | 0.6 s (36 f) |  |

**Boxes the art must agree with.**

- `lunge`: the attack box is 80x80 px at (44, -40) from the feet; it reaches 84 px in front and the lunge carries 156 px, so the reach pose is a full extension that far.
- contact: the body box, armed while alive.

Stats (from `stats.csv`, row `elite_scav`): hp 40, hits for 9, DEF 2, threshold 8, tags none.
