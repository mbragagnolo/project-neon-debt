# Watcher drone: character brief

From `enemies/drone.json`; the numbers are the machine's, the look is the design's. Rendered by enemy-designer/scripts/brief.py; edit the json, not this file.

**Role.** Vertical threat, and the ranged verb. It hovers above melee reach and lobs slow, dodgeable shots; the answer is to aim up. Mechanical: Breach drops it out of the air. Archetype: sentry; the encounter's role: puzzle.

**Look.** A flattened steel disc the width of a dinner plate with a single red lens on its underside rim, a rotor ring on top that reads as a blur in flight, and a short gun barrel under the lens. A cyan status ring around the body: VESTA infrastructure, working as intended. Dents and a scorched patch on the shell. When it aims, the lens brightens and the body tilts toward the target. Stunned, the rotor stops and it drops nose-first.

**Silhouette.** A disc with a rotor above and a lens below. Nothing else in the roster is horizontal. The body box is 52x36 px and does not move for art; feet on its bottom edge.

**Colour.** Accent `red`; palette `steel1`, `steel2`, `steel3`, `red`, `cyan`, `grey_d`. One accent, two at most.

**The tell as a pose.** The state tint blends over the sprite in the engine, so the pose has to agree with it, never carry it alone:

- `aim` (Aim) holds 0.45 s (27 frames) for the `shot` attack: still and lit; faces the player through the tell; the shot goes where the player is when the tell ends

**Rig parts.** body, rotor ring, lens, barrel.

**Clips.** The state names are the clip names; a missing clip falls back to `idle` in the engine.

| clip | state | held for | |
|---|---|---|---|
| `hover` | Hover | until it changes its mind | drifts drift_radius px around home |
| `hover` | Track | until it changes its mind | holds hover_height above and hover_standoff beside the player, on the side it is already on |
| `aim` | Aim | 0.45 s (27 f) | still and lit; faces the player through the tell; the shot goes where the player is when the tell ends |
| `stagger` | Stagger | 0.25 s (15 f) |  |
| `dead` | Dead | 0.6 s (36 f) | falls |
| `stunned` | Stunned | the hack's duration |  |

**Boxes the art must agree with.**

- `shot`: a 16x16 px projectile at 340 px/s; it leaves from the body's centre.
- contact: the body box, armed while alive, disarmed while stunned.

Stats (from `stats.csv`, row `drone`): hp 10, hits for 5, DEF 0, threshold 1, tags mechanical.
