# Prototype findings: can level-designer's reach check run on Neon Debt's real rooms?

Spike for the `level-designer` stub in the kiln repo (`manifest.json`,
`skills/level-designer/SKILL.md`). Throwaway code in this folder; nothing
in `game/` was touched by the spikes themselves. (The catwalks fix that
came out of spike 1 was applied separately and committed as 47311a5.)

## Question

Whether a Python reach check, fed only `game/tools/stacks/*.room` and
`game/src/player/movement_config.tres`, can:

1. find every level gap and every ledge in the district, not just the
   declared gates;
2. classify each against the movement envelope with the kit the player owns
   on first reaching that room;
3. agree with `tests/test_stacks.gd` on the sixteen declared gates;
4. catch anything the hand-authored district and its tests miss.

Underneath it: whether the skill should own a room format of its own (the
stub says `rooms/<id>.json`) or adopt this project's.

## What was tried

- `roomspec.py`: a 120-line port of `RoomSpec.parse` (ASCII grid plus a
  header of doors, markers, gates, requires, oneway).
- `envelope.py`: a 70-line port of `MovementConfig` + `MovementEnvelope`
  that reads the `.tres` and reproduces the numbers in `stacks.md`.
- `reach.py`: the district walk with a growing kit (a port of
  `_reachable`, recording the kit at each room's first arrival); a level-gap
  census per row (lip, a run with nothing to stand on, lip, open above);
  ledges (a standable tile beside a solid column that tops out on another
  standable tile) with the facing wall measured for shaft detection;
  classification with the same 15% margin and 48px body; supports inside a
  gap (standable tiles no deeper than a jump below the lip split it into
  hops); every declared gate re-judged; a findings list; a district map.
- Three passes. The raw census listed 3150 "steps" and every ledge one tile
  too tall (feet on row y to feet on row t is y minus t, not plus one).
  After the fix, reading the catwalks grid by eye showed a pillar top one
  tile under the declared gate, which the census could not see; the third
  pass looks below a gap as well as across it.

## Result

| | |
|---|---|
| rooms parsed, reached from the flat | 34 of 34 |
| declared gates re-judged | 16, all agreeing with the GDScript tests: 2 Sidewinder gaps valid, 11 shafts climbable, 3 teases out of reach |
| level gaps of note | 5 (plus 6 plain jumps and the pillar-top rows you walk down from) |
| ledges that are not steps | 22 (plus 45 steps) |
| run time | under a second |

Run: `python prototype/level_designer/reach.py --map`. Report in
`report.md`, map in `district.png`.

**The catwalks Sidewinder gate was bypassable with the starting kit.**
`gate air_dash 5 17 14` was eight tiles lip to lip, but the shaft's right
wall (x10..13) topped out on row 18, one tile below the gate's right half. A
four-tile jump from the near lip landed on that pillar top and a one-tile
step reached the far lip. The GDScript test passed because it checked only
the gap row and the row above. Fixed in 47311a5: the far catwalk's left
end removed, the gate re-declared, the test now judges the widest hop.

**A hole is not a gap.** The seven-tile opening in gut_pumps' upper floor is
gate-class over live water and is reached with only the Hook. It is the
intended drop into the lower hall, so it is not a bug, but the census
cannot tell a drop from a block without knowing whether the far lip is
reachable another way. Spike 2 settles it.

**Three-tile walls have a 7% margin.** The district's rule "a 2-tile step,
a 3-tile wall" puts 180px walls against a 168px jump, and
`test_movement_envelope.gd` says real flights overshoot the analysis by a
few pixels. The gates demand 15%. Two are load-bearing: the ledge at x35 in
the boss arena and the one at x27 on roof_span.

**The room format is right for the skill.** ASCII grid plus header, parsed
in 120 lines, diffable, and the tests read it directly. The stub's
`rooms/<id>.json` should go; the skill adopts this grammar as its template.

**The envelope is project-specific maths and should arrive as data.** Every
number the check needs fits one file: flat jump, dash, jump plus air dash,
jump height, wall-jump reach, body width, margin. Here it came from a port
of the Godot formulas; in the skill it comes from game-feel's `reach.py`,
or from an engine adapter that dumps it.

**The district map from the specs is a keeper.** Forty lines of PIL draw
every room on the cell grid with doors, pickups, enemies and the findings
marked, and the whole district is readable at a glance.

## Recommendation (spike 1)

Folded into kiln's `manifest.json` on 2026-09-08 (see the stub's Changelog):
rooms in the ASCII grammar, `reach.json` as input, reach.py looks below a
gap, graph.py draws the map, and the in-room solver as the next spike.

---

# Prototype findings 2: can a solver decide passage, not just list gaps?

## Question

Whether a tile-level solver with the kit's moves, fed the same specs and
envelope, can:

1. rediscover the catwalks bypass unaided, from the pre-fix room;
2. tell gut_pumps' drop from a block;
3. prove every door and pickup reachable at door level, room by room, with
   the kit the player owns at that point, and so replace the room-level
   walk's assumption that any door of a room reaches any other;
4. find traps: places a player can get to and not get back from.

## What was tried

`solve.py`. A flood over standing tiles and wall-touch points. From a
standing tile: walk, walk off an edge (three steers), jump (three steers,
from the tile's centre and from its edge), ground dash (altitude held, no
jump at its end), and with the Sidewinder an air dash once per flight at
three moments. From a wall touched while falling, with the Mag-Hook: a wall
jump (kick for the lockout, then three steers), never off the same wall
twice in one flight. Every flight is integrated at the physics step
(1/60 s) with the real 48 by 88 body box against the grid: solids block and
the body keeps pressing so a wall touch registers the moment it starts to
fall; a ceiling zeroes the rise; one-way platforms catch a falling body
only; void ends the flight; hazard is passable. Doors are exits only when
entered the way they are used (rising into a ceiling door, falling into a
floor door). Markers are touched by overlap. Lifts become one-way decks at
rest and at the top, ridden either way.

Above the rooms, `District`: the progression walked as (room, door arrived
by) states, each passage decided by the solver with the kit owned at the
time, the kit growing from what is touched, the Sidewinder installed at the
Mezz. Then a trap check from every state at its kit, and from the floor a
drop lands on, since a player can wall-jump back up a shaft they just fell
into but nobody stays in the shaft. `--override <room>` substitutes a
repaired room so a fix is judged before it lands; `--fixture` runs the gate
checks on one file.

Where the solver contradicted the design doc, the real controller was
asked: `probe.gd` (in the scratchpad, run with
`godot --headless --path game -s <path>`, no production file needed) drops
the real player scene into the real room scene, holds a direction, taps
jump, and reports how far it got. Three probes, all agreeing with the
model to the pixel.

## Result

| | as shipped | with three one-line repairs (`fixtures/`) |
|---|---|---|
| rooms reached at door level from the flat | 8 of 34 | 34 of 34 |
| kit granted | Mag-Hook only | the full kit, in the locked order |
| room solves, time | 24, 2 s | 268, 77 s |

The pre-fix catwalks room: the far lip reachable without the Sidewinder,
found in 1.2 s with no hint about where to look. gut_pumps: every door
reaches every other with the Hook and the HP up is touched; the seven-tile
hole is a drop, as designed.

**The shipped district is impassable past the roof.** Three blocks on the
critical path, none visible to a room-level walk or a gap census, each
confirmed with the real player:

1. **mezz_east**, the hub's east door. The two-tile block at x10..11 stands
   under a three-tile ceiling, leaving one tile of air over it. An 88px
   body cannot fit through, and the ceiling caps the jump at 92px (probe:
   x never passes 9.6 from the west, 12.4 from the east; the jump tops out
   at row 15.47). Every route east of the Mezz, and the Mezz itself from
   the roof side, goes through here.
2. **west_stair**, the way down from the roof. The floor piece on row 35
   (solid, because the alcove door needs a floor) leaves one tile of air
   over the platform on row 37 below it, so nobody can walk off that
   platform's end (probe: x stops at 16.4 with the head under the piece).
   The zig-zag dead-ends there; the lower half of the room and the door to
   mezz_east are unreachable from above.
3. **roof_span**. The water tower's stem (x42..45) is solid from the deck to
   the tank, so the roof's two halves connect only over the tank top, which
   is the tease that is meant to be unreachable. The way from roof_access to
   west_stair does not exist.

**The Gut is a trap before Breach**, although
`test_the_gut_is_not_a_trap_before_breach` passes. The tunnel's way back up
to gut_stair is a three-wide shaft whose mouth is seven rows above the floor
with no ledge or wall near it; the test only asked the graph of doors.
Flagged from five states: after landing in service_tunnel, and arriving in
gut_pumps, gut_vent, gut_lift and gut_cistern with the Hook.

**Also noted.** The catwalks RAM up is behind the Sidewinder gate by
geometry with no `requires` line (it was reachable cold only through the
bypass). Every other pickup is reachable with the kit the walk grants.

**Repairs judged with `--override`** (drafts; the design call is not the
spike's): the mezz_east block one tile tall; west_stair's row 35 kept solid
beside the door and made one-way elsewhere (`##====…`); a two-row tunnel
under roof_span's stem (rows 15..16, x42..45). With those three, the walk
reaches every room and grants every ability in the design's order, and
only the Gut trap remains. A way up in service_tunnel is not drafted.

**What the model does not do.** Steer changes mid-flight, jump cuts, the
hazard's bounce, enemies and knockback, moving platforms beyond the two
decks, coyote time and buffering. Each makes the real player slightly more
capable than the model, so the model's "unreachable" is the claim to
verify, and the three probes did.

## Recommendation (spike 2)

For the skill (folded into kiln's manifest, second Changelog entry):
`solve.py` is real, not planned, and it is the district's judge; the census
lists, the solver decides. Two rules the district taught: headroom is a
verb (a body taller than a tile cannot pass a one-tile slot or jump under
a low ceiling), and every drop is tested from the floor it lands on. The
skill's workflow runs solve.py after every room and judges a repair with
`--override` before it lands. No further spike is needed; the next step is
building the skill from these scripts.

For Neon Debt, decisions to make, none taken here: apply the three repairs
(or better ones) and regenerate; give service_tunnel a way up, or decide
the Gut is meant to be one-way and change the test; declare the RAM up's
requirement; and run the solver as a check beside the GDScript tests, since
the room-level tests cannot see any of this.
