# Environment pass — the 14-C pilot

**Status: prototype, started 2026-09-07.** The sibling of
[`pipeline.md`](pipeline.md): that one is the characters, this one is
everything they stand in front of. The pass is piloted on **Unit 14-C**,
the start room, and rolled out per style afterwards. Two skills get
extracted from what survives the pilot: an *environment designer* (assets:
wall, backdrop, foreground, prop) and a *set dresser* (the depth stack,
the lights, the budget, judged in the screenshot rig). Nothing is written
as a skill until the numbers below have been proven in a shot.

Order of payoff, agreed 2026-09-07: walls and floors (the largest area on
screen), then backdrop planes with depth, then props at 2× with signs as
lights, then fx and HUD rescaled.

## 1. Reference reading — Unit 14-C

**A reference is a quality bar, not a layout.** The screenshots in
`refs/` are kept for two things and nothing is copied from them:

1. **The quality of shading on pixel art.** How a material gets its
   volume in a few colour steps, where the lit edge sits, how texture is
   noise inside a ramp rather than drawn lines, how far planes drop
   pixels. This is what the sprite work answers to, and it is the only
   part the environment-designer skill is concerned with.
2. **Volumetric light as an effect.** Soft large sources with bloom,
   halos on small hot points, reflections on the floor, a haze plane
   between mid and far, light shafts. That is engine work (lights, fog,
   particles in `make_stacks`), out of the sprite skill's scope, and
   pointed out here because the sprites have to be made to *take* that
   light: no baked glow, no black outlines, form shading only, the
   emissive part of a lamp or a sign a separate piece with its own light.

The room itself is designed from its story and DESIGN.md; the reading
below says what the bar is and how far today's room is from it.
`tools/art/ref_stats.py` measures a screenshot (letterbox cropped):

| shot | dark | mid | bright | warm | cold | other |
|---|---|---|---|---|---|---|
| lastnight_04_interior | 35% | 57% | 8% | 47% | 3% | 51% |
| lastnight_01_street | 63% | 31% | 7% | 29% | 46% | 25% |
| lastnight_02_balcony | 35% | 59% | 6% | 79% | 3% | 18% |
| replaced_02_ledge | 50% | 40% | 10% | 5% | 0% | 94% |
| **14-C today** | **63%** | **37%** | **0%** | 22% | 67% | 12% |

Dark is luma under 30, bright is 110 and over; warm/cold/other split the
lit pixels. The last row is the finding: 14-C is already as dark as the
darkest reference, and has **no bright pixels at all**. The room does not
lack darkness, it lacks light sources. Every reference spends 6–10% of the
frame on lights and their direct spill, and that is what the eye reads.

### What 14-C is

Start room, residential, one cell (32×18 tiles of 60 px, so the whole
1920×1080 room fits the viewport). Dani wakes here; the repossession
notice; the "WATER / POWER / LEG UNIT: SUSPENDED" sign; the door east to
Floor 14. A stripped apartment: what is left after the collectors came.

Today the top seven tile rows are one textured slab, the room is eleven
rows of air over a 40 px backdrop grid, the props are crates, a monitor,
a lamp, posters, and the two red-framed notices. Ambient is 0.62 / 0.66 /
0.80. Camera: the whole cell. The references are shot about 2.5× closer
(their figure is 30–40% of the active frame, Dani is 10%), so their
density cannot be copied one to one. At our distance each element reads
at a third of the size: fewer, bigger shapes, and lights carry more of the
picture than detail does. A 1.3–1.5× interior camera zoom is a design
question for later, not for this pass.

### The primary reference: `lastnight_04_interior`

A correction first: the shot is not an interior. It is a street-side food
stall seen from the alley, the lit kitchen behind its window, the city
behind that. What the README pinned still holds for 14-C: one big lit
window as the soft source, small hot accent lights, a clutter band at
floor level, the figure as a silhouette in front of the light.

**What its shading asks of our sprites.** Every material is three to five
steps of one ramp: the crates are a tan ramp with a darker top face and a
lit front edge, the metal counter a cold grey ramp with one specular line,
the plants two greens and a highlight. Texture is noise inside the ramp
(the scuffs on the boxes, the grain on the wall), never drawn as lines.
Nothing has a black outline; edges are the darker step of the local colour
and vanish where the light hits. The figure is almost a flat silhouette
with one lit edge, and still reads. The far towers drop to a few pixels
and a blur, so distance is fewer pixels, not smaller detail.

**What its light asks of the engine.** The window is a soft rectangle
with a wide falloff, not a hard-edged box. Each small lantern carries a
halo a few times its own size. The ground repeats every light as a
smeared reflection. Smoke sits between the mid and far planes and takes
the light's colour. None of that is in the sprites; it is drawn over them.

How it builds depth (technique, not a floor plan):

| # | plane | content | how it reads |
|---|---|---|---|
| 0 | city | grey towers top right, rows of lit windows, one cyan panel | blurred, fewer pixels, no spill |
| 1 | stall back wall | plants, the lantern string, the awning frame | the surface the light falls on |
| 2 | the window | kitchen interior, warm; the counter; ivy either side; six small lanterns | the source plane |
| 3 | play plane | wet ground with reflections; a knee-high band of boxes, cans, bags; the figure at left | where the eye lands |
| 4 | near | bottom band of boxes and bags, larger, darker, out of focus; the letterbox | frames the picture |

Smoke drifts across planes 1 and 2 at the top right.

Light sources:

| source | colour | size | what it lights |
|---|---|---|---|
| the window | warm white to amber | big, soft | the counter, the ground below, the figure's edge |
| lantern string | orange and green, alternating | six small hot points | local halos only, a rhythm |
| neon tube, left | red-orange | one long thin line | a magenta-red wash on the wall and plants |
| far windows | yellow | rectangles | nothing; no spill |
| signs, right | red lantern, red and blue lettering | tiny | signal |
| the ground | all of the above, reflected | the second largest lit area | sells the wet floor |

Accent budget: warm dominates (window, lanterns, the red tube); cold is
almost absent (3%: the cyan panel far right and a blue tint on the
towers); green is the third colour and it is plants and lanterns, not a
signal. One warm scene with one cold pin far away.

Darkness rule: there is no black. The darkest areas are the ground between
reflections and the underside of the awning, and each carries a hint of
the nearest light's colour. Silhouettes read against lit surfaces, never
against black.

Scale: the figure is about 330 px of a 1080 frame; the ground boxes are a
quarter of the figure, the lanterns a tenth. The far plane is blurred so
its pixels do not read as pixels.

### What the secondary references add

- **`lastnight_01_street`**: the darkest of the four (63%) and the only
  cold-led one (cold 46%). Two sources, a sodium lamp top centre and the
  cyan shop, and the crowd as silhouettes between them. This is the
  rule for what 14-C's window looks out on: the outside is colder than
  the inside.
- **`lastnight_02_balcony`**: depth without tiles. Four planes (rail and
  foliage near, the shack mid, towers with lit windows far) and a warm
  haze plane *between* mid and far that does most of the work. One cable
  crossing the top of the frame is the whole foreground.
- **`replaced_02_ledge`**: near monochrome (other 94%), half dark. The wall
  behind the play plane is a few huge concrete panels, blurred, lit by
  spill only. This is the wall rule at 2×: a big soft texture behind the
  play plane, not a tile grid. Their HUD is flat orange pixel icons.

### The brief for 14-C

The room is ours; the references set the bar, not the floor plan. The
story decides the lighting: **POWER: SUSPENDED**. Nothing inside
works. The room is lit from outside, through the window, in the cold of
the street reference; the only warmth is the hall's lamp spilling through
the door, so the way out reads as warm; the notices glow red on their own.
The inverse of the primary reference's budget: a cold scene, one warm pin
at the exit, red as the signal. Magenta stays reserved for the Landlord.

Depth stack (a one-cell room barely scrolls, so the planes separate by
brightness and focus more than by parallax):

| plane | parallax | content |
|---|---|---|
| outside | 0.6 | the block opposite in rain, rows of lit windows, cold blue-cyan; seen through the window cut-out only |
| back wall | 0.9 | stained panels, a wiring run, blinds, a dark kitchen doorway, pale rectangles where the shelf and the screen were taken; slightly blurred, 1 art px = 3–4 screen px |
| play plane | 1.0 | the floor; a lit strip under the window with a faint flipped reflection of it; the clutter band: crates, a bedroll, a bag pile, the monitor; the two notices; the door and its lamp |
| near | 1.2 | a duct run along the ceiling lip with one hanging cable; the corner of a crate bottom left; both darker and out of focus |

Lights: the window (cold, large, soft, low energy, with rain streaks on
the glass); the door lamp (amber, spilling in through the frame); the two
notice screens (red, tiny, hot, local halo only); the ceiling lamp hangs
dark. Ambient drops from 0.62 to about 0.35 but the wall keeps a blue wash
from the window: no black. The slab above the ceiling gets one textured
ring of tiles and then falls to dark fill.

Motion: rain on the window, the notices' flicker, dust motes in the
window's light shaft, the cable's sway.

Target for the pilot shot, measured the same way: dark 40–50%, bright
6–10%, cold-led. The eye should go window, Dani, door.

### Assets the pilot needs

1. `wall_residential` at 2×: stained plaster and concrete panels, a
   wiring run; a nine-patch plus two fill variants. The fill is barely
   seen once the edge ring rule lands.
2. The back wall plane: 960×540 art px at 2× (one cell), with the window
   region left transparent for the outside plane behind it.
3. The outside plane: about 700×500 art px, the block opposite in rain.
4. Props at 2×: crates in two sizes, a bedroll, a bag pile, the monitor,
   the notice screen, the hanging lamp (dark), the door frame and its lamp.
5. Foreground: a tileable duct strip, three cable variants, one crate
   silhouette.
6. FX: the existing `drop` and `dot` particles serve the rain and the dust.

### Open questions the pilot must answer

- How a diffused swatch becomes a fill tile without a visible seam.
- How far a plane can be downscaled before it turns to mud (1.5× or 2×).
- Whether "fewer pixels" or a blur shader reads better as depth.
- The edge-ring-then-dark fill rule in `make_stacks._solid`.
- The camera snap from 3 px to 2 px, and how the old 3× fx coexist.

## 2. The wall swatch (`tools/art/swatch.py`, `sets/residential.json`)

The first environment asset, and the first test of the shading bar on a
surface instead of a figure. The tool generates a material still, cuts one
tile of it, makes that tile seamless at full resolution, downscales it
with the character pipeline (k-centroid, line layer, palette snap), derives
the eight edge tiles (a lit floor lip on top, a dark ceiling underside, a
lit and a shaded side) and pushes the centre tile down the dark ramp. The
engine's nine-patch is unchanged: the edge-ring-then-dark rule lives in
the art. Everything is data in the set json; `--set key=value` overrides a
target key for one run, `--variant` picks a prompt or model block.

### What the sweeps taught (2026-09-07)

- **An illustration model composes a subject.** NoobAI, asked for a
  stained concrete wall, drew smooth plaster with a hairline crack and a
  lit floor (`work/sets/residential/`). Asked harder, with the stain words
  first and weighted, it drew six centrepieces: a rust wound, a drip, a
  rusty pipe (`stained/`). The periphery of those stills is the right
  material; the picture is not. A texture needs a model that knows
  "seamless texture" as a genre; DreamShaper 8 (SD 1.5, cached) is the
  candidate. The SDXL base in the cache has only its configs.
- **Every still carries a lighting gradient**, a bright floor band and a
  dark top. A tile cut from it holds a piece of that gradient, and the
  wrap heal turns it into a repeating blob. `fill.flatten` high-passes the
  tile region (subtract its own blur, add the mean back) before the heal;
  stains and grain are smaller than the radius and survive.
- **A still's greys sit in a narrow band.** Snapped as-is they land on two
  palette steps and the k-centroid vote turns them to speckle. `levels`
  stretches the 2nd–98th luma percentiles onto the concrete ramp first,
  then tints cold. The wall palette is the concrete and dark steel steps
  only; the bright steel steps read as blue plaster and are out.
- **Eight still pixels per art pixel is the vote's floor.** At 1024 seen
  as 120 art px, anything under 8 px in the still is gone: hairline
  cracks vanish, and only the line layer brings a seam back. `swatch` is
  the knob (200 keeps 4 px features) and is the first A/B once a still
  has texture worth keeping.
- **DreamShaper 8 is the texture model, for concrete at least.** Eight
  seeds of "close-up texture of a weathered concrete wall" all came back
  as surfaces: mottling, stains, cracks, cold grey (`dream/`). At 200 art
  px the whole swatch reads as hi-bit concrete with the cracks kept by the
  line layer; 120 lost them. Marcos's note stands: if a later material
  (metal panels, tile, rust) does not hold, a texture-specialised model is
  the next candidate, not more prompting.
- **One tile repeats too fast; one block does not.** A single 30 art px
  fill tile repeats every 60 screen px and any feature bigger than grain
  (a pit, a crack) turns into wallpaper. The nine-patch is now cut from one
  seamless 90 art px block: corners one tile, edge strips three tiles, the
  centre the whole block darkened, a 300 px texture. The room generator's
  60 px margins read it unchanged, so the repeat dropped to 180 px with no
  engine edit. Seed 3 won over seed 1 because its block has no feature
  that would repeat.

### The result in 14-C

`tools/shot_gym.tscn` on `world.tscn`, before and after, measured with
`ref_stats.py`:

| shot | dark | mid | bright |
|---|---|---|---|
| 14-C, ASCII wall | 63% | 37% | 0% |
| 14-C, swatch wall | 87% | 12% | 0% |

The slab above the room, forty percent of the screen, now falls to a
dark fill behind one textured ring; the side columns and the floor lip
read as concrete rather than a grid. The room got darker because the
old tile was a mid-grey wallpaper and the new one obeys the ring rule; the
zero bright pixels are unchanged, and they are the next step (lights),
not the wall's job.

Against the shading bar: three to five steps of one cold ramp, texture as
mottling inside the ramp rather than drawn lines, no black outline, a lit
edge only on the floor lip. Fourteen colours in the whole sheet.

Known limitation: the generator carves solids into greedy rectangles, so a
side column runs from ceiling to floor and wears a lit floor lip on its
top, under the ceiling. Two pixels at game scale, visible up close. The
fix is in `make_stacks._solid`: for each side of a rectangle that touches
no air, drop that side's margin and shift the texture region past its
strip, from the spec's air-neighbour checks. Left for the engine step.

`make_tiles.py` now skips any wall style that has a set json, so a re-run
of the ASCII tiles cannot overwrite a swatch-made wall.

### Direction change (2026-09-07, Marcos, after seeing the swatch)

Two decisions that supersede the swatch approach for walls:

1. **The Metroid rule.** Past a certain depth a wall is simply black. The
   wall's art is its ring, one to two tiles around air; the interior is
   the void colour, not a darkened texture.
2. **Environment art is designed as pixel art, not downscaled.** The
   characters go hi-fi still → hi-bit sheet because a figure needs a
   still to be consistent across frames. A wall does not. Its ring should
   be authored at art pixels, in the palette, with the shading bar in
   mind (steps of one ramp, texture as noise inside the ramp, a lit edge
   on the light side, no black outline against the black interior needed
   because the interior is black). Diffusion stills stay useful as
   *material reference* for the author, not as the source of the pixels.

The swatch tool and this section stay as the recorded experiment; the
next session proposes the authoring method (a procedural pixel-art tile
author extending `make_tiles.py` at 2×, a hand-drawn set, or a mix),
shows a sample ring for 14-C per method at target size, and Marcos picks
before anything is rolled out.

## 3. The ring: three ways to author it (2026-09-07)

`tools/art/ring.py` makes the ring from the `ring` block of the set json,
three ways, and previews each one as Unit 14-C's corner drawn the way the
room generator draws it, at 1:1, with Dani's idle frame on the P ledge
(`work/rings/preview_residential_<method>.png`; `--all` stacks them in
`compare_residential.png` with two extra rows, see below). The nine-patch
is (C + L + C) square: corners C = `tiles` x 30 art px, edge strips L
long, the centre void. Judged at 1:1, never zoomed.

| method | what it is | strip | colours | what it needs |
|---|---|---|---|---|
| `proc` | rules only: one ramp (void, bg0, concrete0-3), value noise inside it with thresholds for the step under and over the base, a lit lip (concrete3 / concrete2, chipped by the noise, a crease under it), a dark underside edge, seams across the strips, streaks down the faces, scuffs on the lip, rust pits, then a grain-dithered fall to void over `fade` px | 6 tiles | 8 | the json only; a new style is a new block |
| `hand` | typed 30 x 30 tiles in `sets/residential_ring.py` (floor A/B, ceiling A/B with a wiring run, wall A/B with a bolt plate and a seam, two corners), joined into 3-tile strips, mirrored and flipped for the free variants | 3 tiles | 10 | an hour of typing per style; every change is retyping |
| `mix` | the `proc` surface with hand-drawn stamps placed by data: the conduit every 30 px along the ceiling with junction boxes, plates and cracks on the walls, cracks and rust bleeds on the floor face | 6 tiles | 11 | the json plus a stamp module per style; a stamp is typed once and placed anywhere |

What the previews showed at 1:1:

- **The material reads in all three.** Three to five steps of one cold
  ramp, texture as mottling inside the ramp, a lit lip on the floor, the
  dark step as the edge everywhere else, no black line: the bar from
  section 1 holds without a diffusion still in the loop.
- **The repeat is the hand set's problem.** Its designed features (the
  junction box, the bolt plate) come back every 180 px and the ceiling reads
  as wallpaper across a 32-tile room; the procedural strip repeats at 360
  px with nothing in it that the eye can lock onto, and the mix places its
  stamps at chosen positions on that strip. Longer hand strips cost linear
  typing; a longer procedural strip is one number.
- **Hand-drawn is cleaner and flatter.** Fewer single pixels, bigger
  deliberate shapes, but the face is plain grey between the features: the
  noise that the bar asks for is what a person cannot type. This is the
  argument for the mix: rules for the surface, a hand for the shapes.
- **The fade wants grain, not blobs.** The first dither (6 px noise cells)
  read as fog at the ring's inner edge; 3 px cells plus per-pixel grain read
  as a pixel-art dither. 20 px of face and 7 of fade fill a 30 px tile.
- **A linear feature on the underside strip belongs to every underside.**
  The nine-patch cannot tell a ceiling from a ledge, so the mix's conduit
  runs under the P ledge as well as along the ceiling. A wiring run is
  dressing (`_dress`, a ceiling prop strip) rather than ring art; the
  stamps that stay in the ring are the ones any solid can wear (stains,
  cracks, plates, rust).
- **Ring depth is a knob.** `--set ring.tiles=2` (with face 50, fade 11)
  gives a 120 px band under the slab; the 1-tile ring reads as a cornice
  over black, the 2-tile ring as a wall the room is cut out of. The
  `compare` page carries both for the pick. A thin column shows the outer
  part of its ring either way, so the fix below serves both.

### What the engine needs, for any of the three

`make_stacks._solid` gives every rectangle 60 px margins on all four sides
and reads the whole texture. The `compare` page's `mix_nofix` row draws the
new ring through that rule: the top slab wears the lit side strip down its
left edge though it faces no air there, the left column shows the lit
left strip instead of its right face and a floor lip at its top under the
ceiling, and the P ledge shows a lip and then its fade against the
backdrop where its underside should be. The preview's `render_room` is the
rule to port:

1. For each side of a rectangle, does any tile past it read as air in the
   spec (`RoomSpec.is_air`, with off-grid as solid)? That side's margin is
   the ring depth if so, else 0.
2. `region_rect` drops the strips of the sides that touch no air, so the
   centre tiling never reads them.
3. When both sides of an axis touch air and the two margins exceed the
   rectangle, split the rectangle between them (a 1-tile ledge shows the
   top half of its lip strip and the bottom half of its underside strip).
4. The ring depth comes from `assets/tiles/wall_<style>.json` (`margin`,
   written by `ring.py` beside the sheet), default 60.

Godot's nine-patch mapping makes this work: below the first margin a
pixel reads the texture from its start, past the last margin from its end,
and the middle repeats the centre. A rectangle thinner than its margins
shows the outer part of its ring, which is the part that matters.

Inner corners (where the ceiling's strip runs on over a column) stay as
they are: the underside's edge line crosses the column's top, two pixels
at game scale, which a per-cell tile choice would fix and the nine-patch
cannot. Not worth a tilemap for.

Pending: Marcos picks the method and the ring depth; then the residential
ring is built for real, 14-C regenerated, shot, measured and recorded here,
and the lights follow.

## 4. The concept step (2026-09-07, Marcos's proposal)

The ring samples did not read as a room, and could not: the ring is the
wall's edge, and a room reads from its biggest plane, its clutter and its
light, all still the M7 greybox in the samples. Marcos's proposal: generate
a concept still of the room from its brief, then have each element of it
translated into pixel art by the method that suits it, some through the
hi-bit downscale (a piano, boxes, a monitor), some authored directly (the
ring's materials, the back wall), some as lights. The concept is a layout
source made from *our* story, which the reference screenshots must never
be.

`tools/art/concept.py` with `sets/unit_14c.json` (kind `concept`): `gen`
sweeps seeds into `work/concepts/unit_14c/[<variant>/]`, `sheet` lays them
out at half size, two columns, because a concept is judged for what is
where and how the light falls. NoobAI, the illustration model, is the right
tool here for the reason it was the wrong one for a material: it composes.

### What the two sweeps taught

- **Asked for a flat side view, the model still draws a room in
  perspective.** The first prompt (`still`) carried "side view, straight-on,
  flat elevation, side-scrolling game background" at 1.25 and perspective
  terms in the negative; all ten seeds came back in one-point perspective
  with the ceiling's fluorescent panels lit, whatever "hanging lamp turned
  off" said. Content landed (papers and wood floors in all, a piano in
  half, rain windows, red notices, doors), so a perspective concept is
  still a source of content and light; it is not a layout.
- **Weight the view and the darkness, and negate the ceiling.** The `flat`
  variant puts "2d side-scroller stage, flat side view, orthographic, the
  back wall parallel to the picture plane, parallax background layer" at
  1.35, "dark room, lights off, power outage, unlit ceiling" at 1.25, and
  "perspective, vanishing point, receding floor, room corner, ceiling
  visible, ceiling lights, fluorescent lights, lit ceiling, bright" at 1.4
  in the negative. Two of eight seeds (5, 6) are flat elevations with the
  power off; three more (2, 3, 8) are flat stages with the wrong content;
  the rest went back to perspective. Eight seeds is enough when two hold.
- **The model dresses the ceiling with lights when told not to.** Seed 5
  hung a string of coloured lanterns, seed 6 a run of small red and blue
  bulbs along the ducts. A concept's light is read, not copied: the brief
  keeps the window cold, the door warm, the notices red.

### The read of `flat` seeds 5 and 6

- **Seed 6**: a flat dark wall; a large rain window centre-right with the
  city's lit towers behind it, the cold source, exactly the street reference
  inverted; a grand piano right against the window; a stack of boxes and a
  crate left with a cyan screen glowing among them; a CRT on a stool and two
  small tables under the window; a shelf of papers far left, a pinboard
  and a fridge far right; papers in drifts across the floor; ducts and
  rafters above. Missing: the door and its warm lamp (the right edge has a
  fridge instead), the red notices (a red sign top right at best).
- **Seed 5**: a flat blue wall with a wainscot-height dark band; a small
  window centre with a visible cold light shaft falling from it; blinds
  either side; a grand piano right, a broken keyboard left, a gramophone
  centre, boxes and a CRT far left; papers on the boards. Cleaner
  composition, the window's shaft is the picture; the lanterns are wrong.

The pick: seed 6 for the room (window, piano, clutter, the drifts of paper,
the duct ceiling), with seed 5's light shaft as the note for the window
light. The door, its lamp and the notices are placed by the brief, not
the concept, since the concept did not draw them and the spec fixes where
they are.

### The cut list, next

`elements` in the room set: name, box on the still, plane (outside, back
wall, play, near), method:

- `hibit`: the crop goes through the character downscale at 2x
  (k-centroid, line layer, palette snap) as a prop still: the piano, the
  boxes, the crate, the CRT, the stools, the shelf, the paper drifts.
- `pixel`: the crop is material reference for authored art: the ring's
  strips (boards on top, plaster on the sides, the duct band under the
  ceiling), the back wall plane with the window cut out, the outside
  plane.
- `light`: an emissive that becomes a PointLight2D and a small sprite: the
  window, the door lamp, the notices, the cyan screen in the boxes.

One artist per element from that list; the set dresser places them by
plane for 14-C in place of the random `_dress`. The ring's method choice
(section 3) stays as the mechanism; the concept decides its materials.

### The pick, and what followed it (2026-09-07, later)

Marcos picked `flat` seed 6. `concept.py cut` crops every element's box
into `source/unit_14c/` (the reference each artist reads) and draws the
boxes on the still (`work/concepts/unit_14c/cut_debug.png`). Eighteen
elements: two material references (ceiling, floor), three planes (outside,
wall, window), three wall-mounted pieces kept in the wall plane (shelf,
pinboard) or removed (the cabinet, where the door is), two lights (the
window, the cyan screen among the boxes), nine hi-bit props (piano, boxes,
crate, box, CRT, table, two paper drifts, and the bedroll from the brief).

- **Scale comes from the figure, never from the concept.** With no human
  in the still the model drew the piano at 28% of the frame and the boxes
  taller than a person. Every hi-bit element carries a `height_art` at 2x
  taken from Dani's 56 art px for 1.7 m: the piano 52 with its lid up, the
  box stack 50, the CRT on its stool 30, a crate 20, a paper drift 7 to 10.
  The concept says what and where; the figure says how big.
- **A composed scene cannot be keyed; a prop on grey can.** The hi-bit
  props are generated again, one still each on a flat ground with the
  characters' prop prompt shape, and the sheet shows the concept crop
  beside every candidate at target size (`concept.py props`,
  `props_contact.png`). The bake keys, crops to content, scales the
  content to `height_art` and runs the character downscale with Dani's
  settings and a materials-only palette.
- **The ring takes its materials from the concept.** `ring.py` now has
  per-side overrides (`materials` in the set json): the top strip is a
  band of near-black boards (rust0 with rust1 grain, a rust2 lit edge, bg0
  gaps at staggered board ends, a shadow line under the band) over a dark
  concrete face, the underside a beam line with slats, the sides plaster.
  A horizontal side owns its band into the corners so the boards reach the
  edge of a ledge. Thirteen colours. The conduit stamp is gone from the
  ring: it belonged to every underside, so it belongs to dressing.
- **The engine rule is ported.** `make_stacks._solid` now reads the ring
  depth from `wall_<style>.json`, checks each side of a rectangle for air,
  cuts the strips of the other sides out of `region_rect`, and splits a
  block thinner than two rings between them. All 34 rooms regenerate
  without an error; the shot of 14-C shows the slab black above a ceiling
  band, the left column wearing only its air face, the P ledge with boards
  on top and an underside. The residential sheet is now the ring
  (`assets/tiles/wall_residential.png`, 480 px, margin 60).
- **A room can be dressed from data.** `tools/stacks/<id>.dress.json`
  replaces the random `_dress` for a room that has one: planes (texture,
  position, z), props (texture, the point they stand on, z, flip), lights
  (colour, energy, scale) and the ambient. Positions for 14-C come from
  the concept boxes times 1920/1344, standing on the floor at 1020 or the
  ledge at 900; the window spans 800..1607 x 415..967, so the two notices
  hang on its glass, which the story can carry (the collectors post on the
  window). Textures that do not exist yet are skipped with a note, so the
  file was written before the assets.

Interim shot, ring and lights only, no planes or props, ambient 0.36 /
0.40 / 0.52:

| shot | dark | mid | bright |
|---|---|---|---|
| 14-C, swatch wall | 87% | 12% | 0% |
| 14-C, ring, lights, no planes | 98% | 2% | 0% |

Darker still, as it should be at this point: the window's glass (the
outside plane) is the room's bright area and it is not there yet. The
lights are placed; their energies get set once the planes are in.

### The first dressed shot (2026-09-07, evening)

`tools/shot_gym.tscn` on `world.tscn` at 1920x1080, measured whole and
with the black slab cropped off (y 378 down), since the Metroid rule makes
a third of this room's frame black by design and the references have no
such band:

| shot | dark | mid | bright | cold |
|---|---|---|---|---|
| 14-C, ASCII wall (start of the pass) | 63% | 37% | 0% | 67% |
| 14-C, ring, lights, no planes | 98% | 2% | 0% | 79% |
| 14-C, dressed, outside under the ambient | 96% | 4% | 0% | 84% |
| 14-C, dressed, outside unlit, generated sky | 75% | 19% | 6% | 97% |
| 14-C, dressed, authored skyline, mid-tone walls | **73%** | **21%** | **6%** | **85%** |
| the same, room only (under the slab) | 58% | 33% | 10% | 80% |

The eye goes window, notices, Dani, door, which is the brief's order with
the notices added, and they earn it: they hang on the glass. Cold-led with
one warm pin at the door. Bright is in the references' band; dark is over
the 40 to 50% target because one window lights the room and the slab is
black, and both are the design.

What it took, in order, each a lesson:

- **The outside plane must not be under the ambient.** A CanvasModulate
  darkens everything in its canvas, so the window's glass was as dark as
  the wall behind it however the light was set. The roof rooms already
  escape this: their sky is on a ParallaxBackground, its own canvas. The
  outside plane now lives on one (`unlit: true` in the dress json, motion
  0.6 for when a camera moves) and the tiled backdrop is skipped for a
  room with planes. That single move took bright from 0% to 6%.
- **A 2D light adds light x surface, so a dark surface cannot take
  light.** The first back wall was painted in the darkest ramp (bg0 to
  bg3) to match the concept's night and stayed black under a 1.4-energy
  window light. It is painted mid-tone now (steel1 base, luma 56, on a
  bg2..steel2 ramp) and the ambient at 0.36 / 0.40 / 0.52 does the
  darkening; the window and the door lamp bring it back where they
  reach. Paint the albedo, let the light make the picture.
- **Inpainting the props out of the concept did not work** with the base
  NoobAI weights in the inpaint pipeline: the first pass refilled the
  masks with shelves (the context is a cluttered room), the second, with
  furniture negated at 1.5, with flat black blobs. The back wall is
  authored instead (`concept.wall_plane`): the ring's plaster noise on a
  dark ramp, the concept's pilasters, the window frame with mullions and
  the glass cut out, pale rectangles where things were taken, a wiring
  run with clips along the top, and the shelf and pinboard pasted from
  their concept crops at 3 screen px per art px. Nineteen colours.
- **The outside is authored too.** Its own generated stills read as an
  overcast day (grey rain, no lit windows) and the palette snap turned
  the one blue glow teal; the concept's glass had the piano lid across it.
  `concept.skyline_block` draws the block opposite at 4 screen px per art
  px: a haze lighter at the bottom where the street glows, towers as flat
  silhouettes with real gaps so the haze shows between them, rows of small
  windows a quarter lit, cold with a few warm. The rain is the engine's:
  `drop` particles emitted along the top of the glass, dying at the sill,
  and dust motes in the window's light, both from the dress json
  (`particles`). Towers on black read as nothing; towers on haze read as
  a city.
- **The door's own lamp is the warm pin.** `_door` gives every side door
  a cyan lamp; a dress json's `door_lamp` recolours it (amber, 1.3) so the
  way out reads warm without a second light fighting the first.
- **A parse error in the generator hangs the headless run.** The script
  fails to load, `_ready` never runs, nothing calls quit. Run
  `make_stacks.tscn` alone with a timeout after any edit and read the
  first `SCRIPT ERROR` line; a `var` and a `func` cannot share a name.

Still open for 14-C: the top third of the frame is black by the Metroid
rule, which is where the interior camera zoom question (section 1) now
has a picture to be asked against; the sky band at the top of the glass
is a flat light grey and could keep more of the night; the notices' panels
are the old 3x HUD-style drawing and will be redone with the HUD; the
piano and the box stack are small next to Dani because they are true to
scale, and a room at this camera distance wants fewer, bigger shapes, as
section 1 said.

Assets written: `assets/props/unit_14c_*.png` (nine), `assets/tiles/
back_unit_14c.png`, `outside_unit_14c.png`, `wall_residential.png` with
its `.json`; sources in `tools/art/source/unit_14c/`; the data in
`sets/unit_14c.json`, `sets/residential.json` and
`tools/stacks/unit_14c.dress.json`. All 34 room scenes regenerated with
the ring rule.

## 5. The skills (2026-09-07, evening)

Extracted from this pilot into `~/.claude/skills`, three of them, split
by the judgement each one makes and named as studio roles, in the
character-designer's shape (a SKILL.md, `scripts/` for what is
deterministic, `templates/` for the data files, `reference/` for the
lessons):

| skill | judgement | scripts |
|---|---|---|
| `concept-artist` | composition: brief to concept still to cut list | `concept.py` gen / sheet / grid / cut, `scale.py` |
| `environment-artist` | the shading bar at 1:1: cut list to ring, props, planes | `ring.py`, `props.py`, `planes.py` |
| `level-artist` | the shot's numbers and the eye path: assets to the lit room | `dress_check.py`, `shoot.py`, `ref_stats.py` |

The seams are two data files: the room set with its cut list
(`sets/<room>.json`), and the dress file (`<room>.dress.json`). The three
share the character-designer's `gen_still.py`, `rig.py` and `pixelkit.py`
as their diffusion, downscale and palette engine. Every script was run
against `game/tools/art` as the studio and reproduces this room. The
project's own tools stay as the originals; the skills are the packaging.

**Pinned:** the apartment's scale next to Dani. Props sized from the
figure read small at a camera that shows the whole cell; the answer is a
camera or composition decision (the interior zoom of section 1), not
larger props. Recorded in the skills' reference files as an open
question.
