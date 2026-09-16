# Art pipeline v2 — generate, cut, rig, bake

**Status: proven on Dani, 2026-09-06; detail pass the same day** (shaded
still, prop wrench, line layer, lit edge, accent vote, palette ramps, A/B
tooling; see "The detail pass" below). The hi-bit target
([`refs/README.md`](refs/README.md)) and the rig-once-bake-to-sheets
decision, as tools. Everything lives in `game/tools/art/`; the runtime is
untouched: `PixelAnim` still reads one row of uniform frames and a clip
table.

## Why this shape

Diffusion models are a stills machine. fakemon-forge's history shows what
one extra *breathing* frame costs when you ask a model for it (img2img off a
procedural squash, a structural gate, 1 keeper in 25). A run cycle is six
frames with large pose changes, so frames are never generated. Instead one
still is generated, cut into parts, and every frame is the same parts posed:
consistent by construction, and a re-pose is arithmetic, not a re-roll.

## The four steps

```
cast/<name>.json            the character: prompt, props, target settings, rig geometry
cast/<name>_poses.py        the clips, as rotations per part

gen_still.py <name>         still candidates -> work/<name>/contact.png
gen_still.py <name> --run shaded      a second sweep, kept beside the first
gen_still.py <name> --prop wrench     a prop's own still (props.wrench in the json)
rig.py <name> grid          50 px grid over the stills, to read joints off
rig.py <name> joints        draw the joints on the chosen still, to check them
rig.py <name> cut           stills -> source/<name>/parts/*.png
rig.py <name> bake          parts + poses -> assets/sprites/<sheet>.png

rig.py <name> bake --tag t --work-only [--set target.k=3 ...]   an experiment
rig.py <name> ab base t ... [--strip run]    A/B strip + run GIF of tagged bakes
```

Run from `game/`. `work/` is gitignored (candidates, debug overlays);
`source/<name>/` is committed (the chosen still and its parts, the
provenance of everything on the sheet).

### 1. Generate (`gen_still.py`)

- Model: NoobAI-XL 1.1 from the local Hugging Face cache, fp16, model CPU
  offload, VAE tiling, Euler-a, 28 steps, CFG 5.5. Peak 5.2 GiB on the
  Quadro RTX 4000; ~25 s per 832×1216 image after the first.
- Prompts are in the model's tag vocabulary and run through **compel** so the
  whole look paragraph reaches both text encoders. Without it CLIP truncates
  at 77 tokens silently, and on the first run every clothing tag fell off
  the end — the batch came back nude. The negative now carries hard `nsfw`
  terms as well.
- The pose asked for is a **T-pose / outstretched arms, from the side**:
  limbs separated from the torso cut cleanly. A neutral arms-at-sides pose
  does not.
- The contact sheet shows each candidate next to itself at the target height
  (56 art px, 2×). Pick at that size; the 1216 px original flatters
  everything.
- **Ask for shading.** The first Dani prompt said `flat color, flat
  shading`, and at 56 px every material became one fill: the k-centroid
  can only keep tonal steps the still has. The shaded prompt (`cel shading,
  anime coloring, soft shading, detailed clothes, clothes wrinkles,
  highlights, rim lighting`, the accents weighted `(cyan trim, cyan
  piping)1.25`) gives folds and a highlight side that survive the vote.
  What not to add: `dramatic lighting, backlighting, official art` cost the
  framing (frontal and three-quarter views, orange rim light, a lit gradient
  ground that the key cannot flood). Weight the pose and the flat ground
  instead, say `dark navy`, and put warm light, lens effects and `facing
  viewer, from front` in the negative. Even then two of ten seeds held the
  profile T-pose; sweeps are cheap, so run ten.
- compel weights (`(tag)1.25`) hit a device error under CPU offload: the
  weighted path subtracts an empty-prompt embedding that each provider
  builds on its *own* device, read off the encoder while it sat on the CPU.
  `gen_still.py` pins the providers to CUDA after building Compel.
- **Props are their own stills.** No profile T-pose seed drew the wrench
  (an outstretched hand does not hold one), so a weapon is generated alone
  (`props.wrench` in the json: prompt, negative, its art height) and cut as
  a part from its own joints (`rig.prop_joints.wrench`, image at
  `source/<name>/wrench.png`), then hung from a character joint
  (`"attach": "hand_near"`). This is also the swappable-weapon path the look
  sheet asked for: the blade and the maul are prop stills.
- A still may face the wrong way (`still.flipped: true` records that the
  chosen image was mirrored to face right before the joints were read).
- Provenance: `work/<name>/<run>/stills.json` (model, prompt, seeds, library
  versions); the chosen seed and run go into `cast/<name>.json`, with the
  earlier prompts kept under `_prompt_*` keys and a note on why they lost.

### 2. Cut (`rig.py cut`)

- The flat background is keyed by flood fill from the border, so
  background-coloured pixels inside the figure survive.
- Every foreground pixel goes to the nearest bone (a `weight` per part
  biases the tie-break: the torso pulls harder than a sleeve). Each part is
  then padded and its two joints rounded with discs, so a rotated limb shows
  no gap. No inpainting under joints; at 56 px the discs cover it.
- **Far limbs are copies of the near limbs**, darkened and hung from a
  shifted pivot (`copy_of`, `offset`, `tint`). A three-quarter still draws
  the far leg shorter and higher, which a side-scroller cannot use; the
  still's own far limbs are cut into `discard` parts so their pixels do not
  bleed into the torso.
- A part can carry a `scale`. A prop still is drawn at its own size (the
  wrench fills its 1216 px canvas), so its part is scaled to the character:
  0.35 makes the wrench 16 art px, hip to knee when it hangs.
- A still draws what it likes: Dani's has a hood the look sheet never asked
  for. A shape like that gets its own part on the right parent (`hood`,
  parented to the torso, drawn behind the head) rather than being left to
  the nearest bone, which was the head.

### 3. Pose (`cast/<name>_poses.py`)

Degrees per part, clockwise on screen, relative to the still. Facing right:
a hanging bone swings forward on a negative angle; the torso leans forward
on a positive one. `offset_art` shifts the whole figure in art pixels for a
bob or a tuck. Cycles are written as arithmetic (the run is a cosine over
six frames), single poses as literals.

A part's `rest` angle (in the json) is added to every pose, so the clips
can keep assuming a hanging arm when the still drew it extended: Dani's
near arm carries `rest: 90`. The weapon, a prop with `rest: 90` on top of
the hanging arm, continues the forearm at angle 0 with its head outward
(hanging: head down, as the look sheet wants; the strike: straight out); a
positive angle dips the head below the forearm, the loose grip of the run.

### 4. Bake (`rig.py bake`)

Forward kinematics at still resolution, then per frame:

1. **Ground contact.** Parts flagged `ground` (the feet) are found after
   posing and the whole figure is shifted so the lowest one sits on the
   floor line (clips can opt out with `grounded: false` for jump, fall,
   wall). A swung leg rises off the ground, so without this every walking
   frame floats; with it the body rises at the passing frames and drops on
   contact, which is the walk bob, for free.
2. **k-centroid downscale** to the art frame (Dani: 48×64 art px, figure 56
   tall). Each art pixel's block of still pixels is clustered into
   `target.k` colours (2) and the bigger cluster wins. A box filter averages
   the still's dark lineart into every fill and reads as blur; this keeps
   fills flat and edges hard. `target.downscale: "box"` is kept for
   comparison. With `target.accent` ({share, chroma, luma}) a losing cluster
   wins its block when it is an accent colour (saturated, or bright) covering
   at least `share` of it, so a visor highlight or a shin strut is not voted
   away by the fill around it.
3. **Line layer** (`target.lines`: {radius, delta, coverage, factor}). The
   still's dark lineart is found as pixels darker than their neighbourhood
   mean by `delta` (a local test, so it finds a line on navy as well as on
   grey and leaves the flat black hair alone), downscaled by *coverage* per
   block, and where a line covers at least `coverage` of a block but lost
   the vote the art pixel is darkened by `factor`: the seams between jacket,
   trousers and boots come back as one-pixel steps. A 4 px line across a
   19 px block covers ~0.2, which is why 0.3 found nothing and 0.15 found
   speckle.
4. **Edge shade** (`target.edge`, a number or {shade, lit, light}).
   Silhouette pixels are darkened by `shade` (0.62) so the palette snap lands
   them one step darker than their fill: the hi-bit outline rule from the
   look sheet, no black lines. Directional: pixels whose outward normal faces
   the light (upper left, the look sheet's rule) are multiplied by `lit`
   instead; 1.3 puts a `navy_ll` rim on the back and the hood, 1.0 just
   leaves the step out where the light hits.
5. **Palette snap** to the character's own subset (`target.palette`, names
   from `pixel.py`) with binary alpha. `pixel.py` now carries a fourth and
   fifth step for the materials that had two or three (`navy_ll`, `skin_l`,
   `skin_dd`, `hair_l`, `cyan_l`, `magenta_l`; the neutral ramp black /
   concrete0-3 / grey was already six), so a shaded still has somewhere to
   land.

Every knob is a `target` key in the character's json: a character's look is
data. For sweeps, `bake --tag <t> --work-only --set target.k=3` bakes one
variant into `work/<name>/bakes/<t>.png` (with its clip table, settings and
colour counts) without touching the asset or the json, and `ab <tags>`
lays the tagged bakes out as rows of idle[0], run[1], run[3], attack[1] at
4× on a grey ground (`work/<name>/ab.png`) with the run cycles side by side
as a GIF; `--strip run` adds every frame of a clip as a filmstrip. Judge at
that size, never at still size.

Frames go on one row through `pixel.sheet`, saved at 2× through
`pixel.save`, and the clip table is printed in the exact shape the scene's
`PixelAnim` wants. The player's collider (48×88) did not move; the sprite is
placed so its bottom edge is the origin.

## What the Dani test showed

- One still, twelve parts (eight cut, four copied), eight clips, eighteen
  frames, all from a short pose file. Cut takes ~10 s, bake ~5 s.
- First bake (box filter, no feet, no grounding) was blurry and floated.
  Both were pipeline settings, not generation: k-centroid plus the edge
  shade fixed the blur, foot parts plus ground contact fixed the float, and
  the run cycle was rewritten with a near-straight contact leg, a folded
  swing leg and level soles.
- Reads as hi-bit at 56 px: rim-lit jacket, visor, mechanical shins, boots,
  far limbs as depth.

## The detail pass

The first bake read as flat silhouettes, one colour per material: the
jacket one navy, the trousers one grey. Five levers were tried one at a
time on the flat still, each as a tagged bake against `base`, then the
still was regenerated. Colours are distinct opaque colours on the whole
sheet / in idle[0]; the strips are in `work/dani/ab_*.png`.

| bake | colours | what it bought |
|---|---|---|
| base (flat still, k=2, edge 0.62) | 24 / 19 | the starting point |
| line layer, coverage 0.2 | 22 / 20 | hem, pocket flap, knee and boot-top seams back as one-pixel steps; 0.3 missed every line, 0.15 speckled the jacket |
| directional edge, lit 1.3 | 24 / 21 | a lighter rim on the back and the hair top; lit 1.0 (step absent) barely visible |
| k = 3 | 21 / 18 | fewer colours, softer marks; dropped |
| accent vote, share 0.25 | 24 / 19 | nothing to keep on a flat still (no piping, no highlights drawn) |
| palette ramps | 27 / 21 | marginal on a flat still: no tones to land on the new steps |
| all four on the flat still | 28 / 23 | seams, a rim, boot definition; fills still single-tone |
| **shaded still**, same settings as base | 31 / 26 | the jump: four navy steps on the jacket (highlight top, folds), a hood, black shins with white struts, a visor with a chin under it |
| shaded still + lines 0.22 / lit 1.3 / accent (final) | 33 / 29 | the zipper seam and hem, a `navy_ll` rim on hood and shoulders, the shin struts and wrench highlights kept |

So the order of payoff was as suspected: the still first, by a wide margin;
lines and the lit edge each a small real gain; accents only once there is
something to keep; ramps only once there are tones to land; k=3 a loss.

The shaded still cost two sweeps (`work/dani/shaded/`, `shaded2/`) and a
prop still for the wrench; the pick is `shaded2` seed 6 mirrored. Its
joints were re-read, the arm rest set, the hood made a part, the weapon
angles in the pose file re-set for the new grip convention. The clip table
did not change, so `player.tscn` is untouched.

- Still open: the still drew a hood and chunky sneakers where the look sheet
  says no hood and heavy work boots; both read fine at 56 px and are a
  re-roll away if they matter. The cyan piping and the shin seam did not
  survive even with the accent vote: the still drew white struts and no
  piping despite the weight, so that accent is a prompt problem, not a bake
  one. The attack arc is now a full over-the-shoulder swing; the face is a
  visor and a chin at this size, which the look sheet accepts.

## Doing the next character

1. Write the look in `docs/art/cast.md` (done for the roster).
2. `cast/<name>.json` with prompt (copy Dani's shading tags and negative)
   and target (copy Dani's `target` block, change the palette and sizes);
   `gen_still.py --run <tag>`; pick on the contact sheet. A weapon or a
   shield that the pose cannot hold is a `props.<name>` still.
3. `rig.py grid`, read joints off `work/<name>/grid.png` (and
   `grid_<prop>.png`); fill `rig.joints`, `rig.prop_joints`, `rig.parts`
   (`rest` for a limb the still drew away from its posed rest, `attach` for
   props); `rig.py joints` to check.
4. `rig.py cut`; look at `work/<name>/parts_debug.png`; adjust weights or
   give a stray shape its own part.
5. `cast/<name>_poses.py` with the clips the enemy states call
   (`enemy_base.gd`: `idle run windup lunge recover stagger stunned dead`,
   plus `hover aim` for the drone and `slam_windup beam phase` for the
   Landlord).
6. `rig.py bake --tag first --work-only`, `rig.py ab first --strip run`,
   judge at 4×; then `rig.py bake` and paste the printed clip table into
   the scene.

## The roster (2026-09-06, third session)

Six characters through the same four steps, one session, Dani untouched.
Sweeps of ten seeds for a character, four to eight for a prop or an NPC;
everything is in `cast/<name>.json` + `cast/<name>_poses.py`, stills and
parts in `source/<name>/`, strips and gym shots in `work/<name>/`
(`ab.png`, `poses.png`, `ab_<cycle>.gif`, `ingame.png`).

| character | still | sheet (screen px) | colours | what it took |
|---|---|---|---|---|
| Scav | `shaded` seed 8, as drawn | 16 × 120×112 | 27 | one sweep; pipe prop seed 2 |
| Elite Scav | the Scav's still, re-dressed | 16 × 120×112 | 22 | recolour rules; cutter prop seed 2 |
| Watcher drone | `saucer` seed 1, cropped | 12 × 80×64 | 19 | two sweeps (the first drew jets) |
| Riot unit | `heavy` seed 10, mirrored | 17 × 96×136 | 20 | two sweeps (the first drew androids); shield seed 1 on its own sheet |
| The Landlord | `shaded` seed 8, as drawn | 39 × 144×176 | 24 | one sweep; baton prop seed 4; phase two as a part swap |
| Stitch | `shaded` seed 8, as drawn | 6 × 112×120 | 23 | one sweep, seated |
| Marisol | `shaded` seed 6, as drawn | 6 × 80×120 | 20 | one sweep, arms folded |

### What the tools grew

- **`recolor` rules** on a part or the whole rig (`rig.recolor`), applied
  at cut so the parts on disk are the provenance: a selector (hue range,
  saturation and value floors and caps, an optional `box` in still pixels)
  and an action (`hue_to` / `hue_shift`, `sat_to` / `sat_mul` / `sat_add`,
  `val_to` / `val_mul` / `val_add`). This is the re-dress (the Elite from
  the Scav), the accent paint (the Scav's amber iris, the Riot's lamp, the
  Landlord's readout), the shadow (the Scav's face), and the ramp lift (a
  near-black still onto the steel hue, twice). A rig-level rule hits the
  props too; a part opts out with `"recolor": []`.
- **`thicken`** (a dilation radius) for a shape drawn thinner than an art
  pixel; **non-uniform `scale`** (`[sx, sy]`) for a frontal shield seen
  edge-on and a tall rotor squashed to a ring; **`attach`** on a non-prop
  part to hang it from a joint other than its cut pivot.
- **`cut_as`**: a part that takes another part's pixels with its own
  recolour, so a limb exists twice (the Landlord's sleeved and chrome arms,
  the baton dim and lit). **`overlay`**: a part cut by its bone whose
  pixels also stay with the part beneath (Marisol's pointing forearm).
- **Per-pose `tint`** ({part: factor or [r, g, b]}) and **`hide`** ([parts]):
  a lens that brightens, a lamp that blinks, a readout that goes hot, a
  weapon swapped for its lit twin, a phase-two arm set.
- **Keying aids** in the `still` block: `key_seeds` (extra flood-fill starts
  for background pockets a floor shadow closes off) and `clear_boxes`.
- `rig.py ab` picks its four cells from what the sheet has (idle / run or
  hover / windup / lunge or aim), `--picks` overrides, and the GIF loops the
  run, the hover, or the first looping clip. `tools/shot_gym.tscn` takes
  `room=`, `out=`, `player=x,y`, `spawn=scene:x,y` after `--`.
- Palette: `olive_d`, `olive_ll`, `rust3`, `amber_l`, `red_l` (never renamed).
- Engine: `landlord.gd` plays the `p2_` twin of a clip once the phase is
  two; `npc.gd` carries the NPC clip tables (`SHEETS`) and plays `talk`
  while the dialogue box is open, falling back to the two-frame idle when
  the sheet on disk is too small for the table.

### Lessons

- **Prompts that missed twice.** "drone, flying drone, robot, sci-fi,
  concept art" drew fighter jets on every seed; "flying saucer, rotor on
  top, red lens underneath" with the aircraft words in the negative drew the
  disc. "humanoid robot, android" drew slender figures; "heavy robot, power
  armor, walking tank" with slender and feminine in the negative drew the
  wall. Asking for an amber shoulder lamp turned the visor amber: a small
  accent the still will not place is cheaper to paint with a box rule.
- **Two things a still hides.** A wide stance with a floor shadow closes
  off the background between the legs, and the shin swallows it: seed the
  key. A still can draw the second arm and the far leg where you want
  nothing: discard bones. Both showed only in `parts_debug.png`.
- **Signs.** A bone pointing down-forward is at a negative screen angle, so
  a stride still gets positive `rest` on the thigh and the rests along a
  chain sum to zero for the pose file's foot levelling to hold.
- **Sheets need `godot --headless --import`** before a command-line run
  sees them. And run GUT alone: the windowed screenshot run writes the
  same user settings file and `test_settings_survive_a_reload` reads it.
- Order of payoff held: the still first (a re-prompt beats any bake knob),
  then the rig's cut, then colour. No character needed more than two
  sweeps; the pipe, the cutter and the shield were picked by thickness at
  the target size rather than by looks at 1216 px.
