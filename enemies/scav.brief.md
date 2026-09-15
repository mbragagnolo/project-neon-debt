# Scav: character brief

From `enemies/scav.json`; the numbers are the machine's, the look is the design's. Rendered by enemy-designer/scripts/brief.py; edit the json, not this file.

**Role.** Spacing. Bait the lunge, step in, punish the recovery. The first fight of the game. Archetype: rusher; the encounter's role: pressure.

**Look.** A person who lives in the Stacks' write-off floors. Hunched, hooded, the face lost in the hood except one amber eye: a cheap ocular implant that never stopped glowing. Layers of olive and rust: a hooded canvas coat over a stained work shirt, trousers tied at the ankle, boots wrapped in tape. A length of steel pipe in both hands, held low. Wiry rather than big. The overcommit pose is a full-body reach with the pipe, feet leaving the ground.

**Silhouette.** The hood and the hunch, pipe angled down. Shorter than the player. The body box is 44x80 px and does not move for art; feet on its bottom edge.

**Colour.** Accent `amber`; palette `olive`, `olive_l`, `rust1`, `rust2`, `amber`, `grey_d`, `skin2_d`. One accent, two at most.

**The tell as a pose.** The state tint blends over the sprite in the engine, so the pose has to agree with it, never carry it alone:

- `windup` (Windup) holds 0.48 s (29 frames) for the `lunge` attack: plants, the loudest tint on screen; aims once on entry
- `recover` (Recover) holds 0.75 s: drained tint; the punish window

**Rig parts.** hooded head, torso, near upper arm, near forearm, near hand, far arm, near thigh, near shin, far leg, pipe.

**Clips.** The state names are the clip names; a missing clip falls back to `idle` in the engine.

| clip | state | held for | |
|---|---|---|---|
| `idle` | Patrol | until it changes its mind | a beat of patrol_range px each side of home, patrol_pause s at each end; turns at walls |
| `run` | Patrol | until it changes its mind | a beat of patrol_range px each side of home, patrol_pause s at each end; turns at walls |
| `run` | Chase | until it changes its mind | closes at chase_speed; leashes home past give_up_range |
| `windup` | Windup | 0.48 s (29 f) | plants, the loudest tint on screen; aims once on entry |
| `lunge` | Lunge | 0.2 s (12 f) |  |
| `recover` | Recover | 0.75 s (45 f) | drained tint; the punish window |
| `stagger` | Stagger | 0.3 s (18 f) |  |
| `dead` | Dead | 0.45 s (27 f) |  |

**Boxes the art must agree with.**

- `lunge`: the attack box is 76x76 px at (42, -40) from the feet; it reaches 80 px in front and the lunge carries 132 px, so the reach pose is a full extension that far.
- contact: the body box, armed while alive.

Stats (from `stats.csv`, row `scav`): hp 16, hits for 6, DEF 0, threshold 1, tags none.
