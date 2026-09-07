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
