# vfx-artist spike on Neon Debt (2026-09-08)

The kiln stub `skills/vfx-artist/SKILL.md` claims effects can be authored
as data from a few shapes and one ramp, baked through the character bake,
and judged on the frame they fire on over the character. This spike tests
that claim with three effects. Nothing in `game/` was edited; everything
here is `prototype/vfx_artist/`.

## The question

Can a hit spark, a landing puff and a death burst, authored as data
(shared shapes, one ramp per family, frame timing) and baked through
`rig.py`'s own functions, read as one hand with the baked roster at 1:1
and at the game's scale, on the frame hitstop freezes, and does that beat
or feed what `juice.gd` draws today with the dot/puff/spark textures?

Two corrections to the stub's question, from the code, before any code
was written:

1. **Reactive effects have no anticipation.** `damage_dealt`,
   `player_action("land")` and `enemy_died` fire on the impact. Hitstop
   (`hitstop.gd`) then sets `Engine.time_scale` to 0 for 2 frames (light)
   or 4 (heavy), and nothing advances: not PixelAnim, not CPUParticles2D,
   not tweens. So the effect's *first* frame is the one held on screen for
   33 to 66 ms, longer than any other frame is ever shown. Anticipation is
   the actor's windup. The rule to test became: impact first and biggest,
   then a decay longer than the attack.
2. **"The same bake as the characters" only means something above art
   resolution.** Drawing at art px and snapping is palette discipline. The
   bake is the k-centroid vote, the edge shade with the lit rim, the
   palette snap. So the same effect data was rendered two ways: direct at
   1x, and smooth shapes at 8x reduced by `rig.k_centroid`,
   `rig.shade_edges`, `rig.snap_to_palette`.

## What was tried

- `shapes.py`: five shapes as fields over a grid, in art px from the
  effect's anchor: `disc` (radial tone), `ring` (with `ry` for an ellipse),
  `streak` (a tapered ray), `chip` (a square of debris), `puff` (a cluster
  of discs shaded by the upper-left light). Tones are float positions on a
  named ramp; `floor` clips a frame at the ground.
- `author.py`: the three effects written as data (`effects/*.json`): the
  spark 32x32 art px, 6 frames at 30 fps; the dust 48x20, 6 at 20 fps; the
  burst 64x64, 8 at 24 fps. Two families share the shapes: `hot` (white,
  warm, amber, sodium, rust2, rust1) and `dust` (steel4..steel1). The
  burst uses both.
- `bake.py`: three authoring paths per effect. `direct` (1x, tones rounded,
  no edge rule: what an ASCII grid gives); `bake` (8x through the
  character bake as is: k=2 with the accent vote, edge 0.62 / lit 1.3 from
  the upper left, snap); `hot` (the same, but the edge rule per family:
  the hot family gets no edge step, dust gets the character rule; families
  baked as layers, dust under hot). Measures per frame: colours, opaque
  px, off-palette px, and the share of silhouette pixels darker / lighter
  than their neighbours (the edge rule as a number). `--emit` writes the
  2x sheets with a clip table in `rig.py`'s shape plus the anchor.
- `strip.py`: one strip per effect, rows = paths, columns = frames at
  t = k / fps, with Dani's and the Scav's clips advanced to t as
  PixelAnim would (hitstop holds both, so relative time is preserved);
  cells at 4x on the roster's grey, the size the roster was judged at. A
  lineup of the impact frames beside the figures on the game's dark ground
  at 1x and 3x.
- `shot.gd`: an outside SceneTree script (`godot --path game --windowed
  -s`), the combat gym, a Scav frozen inside the wrench's box, one swing,
  a capture of the first drawn frame after the hit and one ~70 ms after
  hitstop lets go; `mode=before` adds the game's own `Juice` node,
  `mode=after` a Sprite2D with the baked sheet at the target's centre.

## Results

### The strips (`out/strip_*.png`, `out/lineup_1x.png`, `out/lineup_3x.png`)

First authoring: the spark's corona swallowed its rays and read as a sun;
the dust rose as two cartoon clouds; the burst's ring was the hack tell's
circle (`hack_fx.gd` draws an expanding circle for every cast), and a
default-ramp bug painted the whole burst in the dust ramp. Second
authoring: a star with a small core and nine uneven rays biased away from
the attacker; dust that hugs the floor, splits and thins to specks; a
flash, then a flattened shockwave ellipse, chips out and down, smoke up.

| effect, f0 | path | colours | rim dark | rim light | px per frame |
|---|---|---|---|---|---|
| spark.hit | direct | 4 | 0.40 | 0.35 | 123 137 85 35 15 4 |
| spark.hit | bake | 5 | 0.53 | 0.26 | 117 126 79 28 8 3 |
| spark.hit | hot | 4 | 0.37 | 0.39 | 117 126 79 28 8 3 |
| dust.land | direct | 3 | 0.28 | 0.43 | 116 170 171 135 67 28 |
| dust.land | bake = hot | 4 | 0.59 | 0.59 | 114 169 169 129 62 28 |
| burst.die | direct | 3 (f2: 6) | 0.46 | 0.26 | 420 296 383 477 397 344 222 98 |
| burst.die | bake | 5 (f2: 9) | 0.78 | 0.14 | 433 283 370 471 390 340 217 97 |
| burst.die | hot | 4 (f2: 8) | 0.70 | 0.08 | 433 283 369 468 390 339 217 97 |

Off-palette pixels: 0 on every path, every frame (the snap guarantees it).

- **The bake path is visibly the roster's hand on the dust**: the puffs
  get a lit top-left and a darker step on the lower right, the same rule
  that shades Dani's jacket; the direct path is two flat tones. The
  numbers agree: rim dark 0.28 to 0.59, rim light 0.43 to 0.59, one more
  colour per frame.
- **The character edge rule is wrong for an emitter.** On the spark and
  the burst the 0.62 shade puts a rust rim around the corona and every
  ray; on the dark ground it reads as a dirty fringe. `hot` (no edge step
  on the hot family, the rule on the smoke) is the clean one at 3x: the
  temperature ramp drawn into the shape is the spark's own edge. The
  families need different edge rules, and a mixed effect is baked as
  layers.
- **The k-centroid does the right thing on thin tips.** Ray tips thinner
  than half a block vanish, chips of 1.2 px vanish in the last frames:
  the decay thins on its own, and the px-per-frame column shows the curve
  the rule asks for (impact first and biggest, except the burst, whose
  smoke peaks at f3: acceptable, the flash is f0).
- **The direct path's white core bloats.** A 2.6 px radius rounded at 1x
  is a 5 px white blob; the bake's vote keeps it at 3. This is the
  "baby's first sprite" look the M7 sprites had, for the same reason.
- The dust and the spark sit within the figure: the spark ~30 art px
  across against the wrench's 36 px box, the dust 44 px wide under 56 px
  of Dani. The burst's flash is 22 px, its wave 64 px, over a 50 px Scav.

### The timing, from the engine

- The wrench's box arms on the first tick of the swing and stays armed
  80 ms; the attack clip runs 3 frames at 18 fps (55 ms each). A Scav
  already in the box is hit **2 physics frames after the press, on
  attack[0], the windup**; the strike pose arrives 22 ms after the hit.
  The engine shot confirms it: both captures of the first frame after the
  hit show Dani with the wrench behind her head. A game-feel note for the
  actor's clip (arm the box a frame later, or put the strike first), not
  a vfx one; the effect is judged over the frame the engine shows.
- Hitstop holds the first frame 33 ms (light) on top of the effect's own
  33 ms: the spark's f0 is on screen 66 to 100 ms, its decay 167 ms. Today
  the same held frame is all of `juice.gd`'s particles piled at the
  origin: a soft yellow slab (the 12x4 spark texture, scaled 1.6 to 2.6
  on top of 3x, with a white fade).

### The engine shot (`out/shot_compare.png`, from `out/shot_*_{hold,decay}.png`)

Same camera, same frame, same hit. Measured on the spark's region of the
1080p capture, warm pixels only:

| | distinct warm colours | edges on the 3 px art lattice |
|---|---|---|
| today, first frame after the hit | 342 | 68 % |
| baked f0, first frame after the hit | 99 | 85 % |
| Dani's silhouette, same shot (control) | | 99.9 % |

The engine lights every pixel (the player's PointLight2D, the Scav's hurt
flash), so a lit frame cannot be checked for palette exactness; the
lattice test is the honest one. Dani's edges fall on one residue class of
three, the baked spark's mostly do (the rest are the flashing Scav's own
edges inside the region), today's particles do not: soft alpha, a
non-integer scale, sub-pixel motion. At 2x blow-up the difference is
plain: crisp 3 px pixels beside Dani's, against a blurred bar.

What else is on the impact frame, and not this spike's: the swing tell
(`swing_tell.gd`, a vector crescent) and the damage number (a vector
font). Both read as a different hand next to the baked spark.

## Answer

Yes. An effect authored as data from five shapes and one ramp per family
bakes through `rig.py`'s functions into a sheet with a clip table, and on
the strips the baked dust carries the roster's edge rule while the spark
and burst keep their own temperature edge; on the game's dark ground at
3x the three read with Dani and the Scav as one hand, and in the engine
the baked frame lands on the art lattice where today's burst does not.

**It feeds `juice.gd`, it does not replace it.** The wiring is right:
one node on the signal bus, a one-shot per event, freed when done. What
changes is what the one-shot is: for hit, land and die, a `PixelAnim`
(the existing Sprite2D with a clip table) playing one baked sheet from its
anchor, freed on `is_done()`, instead of a CPUParticles2D burst. Particles
stay for what they are good at: the ambient rain, steam and dust that
`make_stacks._particles` places from the dress file, and possibly a few
trailing chips. The hack tell's ring and the swing tell's crescent are the
next two effects (a `ring` family and a `slash`), and the damage number is
the ui-artist's pixel font.

## What went wrong, for the reference notes

- A shape with no `ramp` key took the first ramp listed; the burst listed
  `dust` first and came out blue-grey. An effect names its default ramp.
- A corona bigger than its rays is a sun, not a hit. Small core, long
  uneven rays, a bias away from the attacker.
- A union of discs is a cartoon cloud unless it is wider than tall, sits
  on the floor and breaks up; the floor clip is what makes dust dust.
- A circle is already the hack tell. The death wave is an ellipse.
- The character's edge rule on an emitter is a dirty rim. Per family.
- An outside `-s` script cannot name a `class_name` whose script touches
  an autoload (`Juice` reads `Events`): the autoloads are not up when the
  script compiles, the compile fails, and the run hangs. `load(...).new()`
  at run time instead; `root.get_node("Events")` for the bus.
- The viewport readback stalls the engine for a frame or more: one
  capture per run, and the 33 ms hold is caught only if the effect sprite
  already exists (loading the sheet on the hit costs the hold).
- A lit engine frame cannot be palette-checked; check the lattice.

## Recommendation: the manifest entry

`depends_on`: `character-designer` (the bake functions and the actors'
sheets; `studio-core` is the future home of the bake, not a dependency
yet) and `game-feel` (hitstop frames, the actors' clip timing).

`input`: add the actors' sheets and clip tables (the frames the effects
fire over), the hitstop table, and the trigger position per event (the
target's centre, the feet).

`output`: the clip json carries an `anchor` (art px, where the effect's
trigger point is in its frame); a strip per effect over the actor's
frame at the effect's time; a lineup of impact frames beside the figures
at 1x and at the game's scale; an engine shot of one effect on its frame.

`files`:
- `scripts/shapes.py`: the shape vocabulary as fields (disc, ring, streak,
  chip, puff), tones on a named ramp, the floor clip.
- `scripts/fx.py`: effect json to frames through the character bake, the
  edge rule per family, layers composited; the sheet at the project's
  scale with the clip table and anchor; `--tag` for A/B paths.
- `scripts/strip.py`: the strip over the actor's frame at the effect's
  time, the lineup, the measurements (colours, rim shares, px per frame).
- `scripts/shoot_fx.gd`: the outside engine probe: one trigger, the first
  frame after it, before and after, with the lattice check.
- `scripts/preset.py`: particle presets by name for the ambient (rain,
  steam, dust) the dress file references; untested in the spike, kept.
- `templates/effect.json`: shapes, ramps, default ramp, frames, fps,
  anchor, floor, trigger.
- `templates/preset.json`.
- `reference/timing.md`: the first frame is the impact and the held one;
  fps per family; the decay longer than the attack; the engine's clip lag.
- `reference/families.md`: hot and dust; the edge rule per family; ramps
  from the palette; shared shapes; what a circle already means.
- `reference/engine.md`: the outside probe, the autoload lesson, the
  readback stall, the lattice check.

`watch`, replacing the first line:
- The first frame is the impact and the biggest: hitstop holds it and it
  is the frame the eye lands on. The decay is longer than the attack.
  Anticipation is the actor's windup, not the effect's.
- An emitter has no lit side: the hot family takes no edge step; dust and
  smoke take the character's edge rule. A mixed effect is baked as layers.
- Judge on the frame the engine shows at the trigger, not the pose the
  animation intends.
- Every effect uses the palette's ramps and nothing new (kept).
- Presets are data the level-artist can reference by name (kept, scoped
  to the ambient).

`why`: extend with the spike's evidence: the same bake gives dust the
roster's edge, the emitter families keep their own, and a baked frame is
the only thing that lands on the art lattice under hitstop.

## Open

- Marcos has not judged the effects themselves; the burst's flash still
  reads as a sun for its 33 ms, and the dust's steel4 highlight may be too
  bright on the game's dark ground.
- The game-feel finding (the hit on the windup frame) is real and outside
  this spike.
- Sound: `sfx_requested` and the event table are the sound-designer's;
  the same `events.json` should key both.
