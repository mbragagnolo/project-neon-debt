# Riot unit: character brief

From `enemies/riot.json`; the numbers are the machine's, the look is the design's. Rendered by enemy-designer/scripts/brief.py; edit the json, not this file.

**Role.** Heavy hits and hacks. Shots ping off the front, light hits only flinch it; get behind it, hit it heavy, or hack it. Mechanical: Breach stuns it, Overload ignores the shield and interrupts it. Archetype: wall; the encounter's role: gate.

**Look.** A crowd-suppression frame, not a robot with a face: a squat, heavy-shouldered chassis in matte steel with hydraulic lines at the joints and a narrow cyan visor slit where a face would be. An amber warning lamp on one shoulder blinks in idle and stays lit in the windup. It carries a full-height polycarbonate riot shield, scuffed and concrete-grey, with VESTA COLLECTIONS stencilled across it. The bash tell is the shield drawn back; the lunge is the shield driven forward with the whole frame behind it. Stunned, it sags at the knees and the visor goes dark.

**Silhouette.** A wall with legs. Wider than anything else that walks. The body box is 60x100 px and does not move for art; feet on its bottom edge.

**Colour.** Accent `amber`; palette `steel1`, `steel2`, `steel3`, `cyan`, `cyan_d`, `amber`, `concrete1`, `concrete2`, `black_l`. One accent, two at most.

**The tell as a pose.** The state tint blends over the sprite in the engine, so the pose has to agree with it, never carry it alone:

- `windup` (Windup) holds 0.6 s (36 frames) for the `lunge` attack: plants, the loudest tint on screen; aims once on entry
- `recover` (Recover) holds 0.5 s: drained tint; the punish window

**Rig parts.** head unit, torso, near upper arm, near forearm, far arm, near thigh, near shin, far leg, shield (its own node).

**Clips.** The state names are the clip names; a missing clip falls back to `idle` in the engine.

| clip | state | held for | |
|---|---|---|---|
| `idle` | Patrol | until it changes its mind | a beat of patrol_range px each side of home, patrol_pause s at each end; turns at walls |
| `run` | Patrol | until it changes its mind | a beat of patrol_range px each side of home, patrol_pause s at each end; turns at walls |
| `run` | Chase | until it changes its mind | closes at chase_speed; leashes home past give_up_range |
| `windup` | Windup | 0.6 s (36 f) | plants, the loudest tint on screen; aims once on entry |
| `lunge` | Lunge | 0.25 s (15 f) |  |
| `recover` | Recover | 0.5 s (30 f) | drained tint; the punish window |
| `stagger` | Stagger | 0.4 s (24 f) |  |
| `dead` | Dead | 0.6 s (36 f) |  |
| `stunned` | Stunned | the hack's duration |  |

**Boxes the art must agree with.**

- `lunge`: the attack box is 90x90 px at (50, -48) from the feet; it reaches 95 px in front and the lunge carries 95 px, so the reach pose is a full extension that far.
- contact: the body box, armed while alive, disarmed while stunned.

Stats (from `stats.csv`, row `riot`): hp 35, hits for 10, DEF 3, threshold 12, tags mechanical immune_ranged_frontal.
