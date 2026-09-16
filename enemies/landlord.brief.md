# The Landlord: character brief

From `enemies/landlord.json`; the numbers are the machine's, the look is the design's. Rendered by enemy-designer/scripts/brief.py; edit the json, not this file.

**Role.** The wall worth climbing. DEF blunts light hits, only heavy hits and Overload interrupt him, the slam punishes standing on the floor, the beam punishes standing still, and the drones he calls are what Breach is for. Every verb has a job. Archetype: boss; the encounter's role: gate.

**Look.** Tall, still, expensive. A long black coat with chrome piping at the collar and cuffs, worn open over a fitted dark shirt. Both forearms and hands are polished chrome, the only bright metal on anyone in the slice, and the collections deck sits on his chest like a breastplate: a dark slab with a magenta readout that is dim until he uses it. Pale, clean-shaven, hair slicked back; no visor, no implants showing on the face. The baton is a telescoping shock stick that lights magenta along its length in the windup. Phase two: the deck's readout stays hot, and the coat is off the shoulders and hanging from the belt so the chrome arms read at full length.

**Silhouette.** The tallest thing in the game. The coat's line, the baton's length, the deck's square. The body box is 72x124 px and does not move for art; feet on its bottom edge.

**Colour.** Accent `magenta`; palette `black`, `black_l`, `chrome`, `chrome_d`, `magenta`, `skin`, `skin_d`. One accent, two at most.

**The tell as a pose.** The state tint blends over the sprite in the engine, so the pose has to agree with it, never carry it alone:

- `windup` (Windup) holds 0.5 s (30 frames) for the `baton` attack: plants, the baton lights
- `slam_windup` (SlamWindup) holds 0.7 s (42 frames) for the `slam` attack: crouches, lit, still
- `beam` (BeamWindup) holds 0.8 s (48 frames) for the `beam` attack: a line from the deck to the player, brightening; the shot goes where the line last pointed
- `recover` (Recover) holds 0.6 s: shared by the three attacks; then attack_cooldown

**Rig parts.** head, torso with the deck, coat tails, near upper arm, near forearm (chrome), near hand, far arm, near thigh, near shin, far leg, baton.

**Clips.** The state names are the clip names; a missing clip falls back to `idle` in the engine.

| clip | state | held for | |
|---|---|---|---|
| `idle` | Approach | until it changes its mind | closes at chase_speed (x phase2_speed_mult in phase two); picks an attack by distance when attack_cooldown is over; no leash |
| `run` | Approach | until it changes its mind | closes at chase_speed (x phase2_speed_mult in phase two); picks an attack by distance when attack_cooldown is over; no leash |
| `windup` | Windup | 0.5 s (30 f) | plants, the baton lights |
| `lunge` | Lunge | 0.3 s (18 f) |  |
| `recover` | Recover | 0.6 s (36 f) | shared by the three attacks; then attack_cooldown |
| `slam_windup` | SlamWindup | 0.7 s (42 f) | crouches, lit, still |
| `beam` | BeamWindup | 0.8 s (48 f) | a line from the deck to the player, brightening; the shot goes where the line last pointed |
| `phase` | PhaseShift | 1.4 s (84 f) | invulnerable; the drones arrive halfway through |
| `stagger` | Stagger | 0.45 s (27 f) |  |
| `dead` | Dead | 2.2 s (132 f) |  |

Phase two: the whole clip set again under the prefix `p2_`; the engine plays the prefixed twin when the sheet has one.

**Boxes the art must agree with.**

- `baton`: the attack box is 120x110 px at (66, -56) from the feet; it reaches 126 px in front and the lunge carries 162 px, so the reach pose is a full extension that far.
- `slam`: a 44x30 px projectile at 420 px/s; it leaves from the body's centre.
- `beam`: a 30x10 px projectile at 950 px/s; it leaves from the body's centre.
- contact: the body box, armed while alive.

Stats (from `stats.csv`, row `landlord`): hp 270, hits for 14, DEF 5, threshold 16, tags none.
