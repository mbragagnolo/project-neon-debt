# The light spike: bloom and one shaft on 14-C (2026-09-08)

Marcos asked whether the vfx-artist owns light effects and chose yes,
with this spike before the build. Question: do bloom (HDR 2D plus a
WorldEnvironment glow) and one authored shaft move 14-C toward the
references' "volumetric light as an effect" (bloom on the big source,
halos, a shaft) without breaking the level-artist's light budget, and can
both be set as data from outside the project? Nothing in `game/` was
edited: `light_shot.gd` is an outside SceneTree script that instances the
real world scene, waits out the start travel, places Dani on the ledge,
adds the effect and captures once; `light.py` drives the variants,
measures each shot with the level-artist's `ref_stats` (the budget) and a
luma band just outside the glass (the halo), and lays the crops out
(`out/compare.png`, `out/edge.png`).

## Results

Whole frame, the level-artist's numbers (`ref_stats`, letterbox 0.13),
plus the mean luma of a 40 px band outside the glass's left edge and of a
patch of far wall as the control. `today` reproduces the pilot's final
shot (67 / 30 / 3).

| shot | dark | mid | bright | cold | outside the glass | far wall |
|---|---|---|---|---|---|---|
| today | 66% | 31% | 3% | 82% | 34.9 | 22.7 |
| hdr_only (HDR 2D on, glow off) | 73% | 24% | 3% | 79% | 32.6 | 19.1 |
| glow_soft (HDR, thr 0.7, softlight) | 73% | 24% | 3% | 79% | 32.4 | 19.1 |
| glow_add_hdr (HDR, thr 0.45, additive) | 67% | 30% | 3% | 78% | 35.4 | 21.1 |
| glow_add_ldr (no HDR, thr 0.45, additive) | 67% | 30% | 3% | 79% | 35.4 | 20.7 |
| glow_screen_ldr (thr 0.4, screen) | 71% | 26% | 3% | 79% | 33.5 | 19.8 |
| glow_low_ldr (thr 0.25, intensity 1.4) | 46% | 51% | 3% | 78% | 41.8 | 25.7 |
| glow_hot_hdr (HDR, thr 0.9, room lights x2.5) | 59% | 38% | 4% | 80% | 54.7 | 24.5 |
| shaft_ldr (hard bands, alpha 0.28) | 63% | 31% | 6% | 90% | 79.6 | 20.7 |
| shaft_faint_ldr (hard, 0.16) | 63% | 33% | 4% | 88% | 58.3 | 20.7 |
| shaft_soft (sine slices, 0.22) | 65% | 31% | 4% | 86% | 46.8 | 20.7 |
| shaft_soft_faint (sine slices, 0.14) | 66% | 31% | 3% | 84% | 42.6 | 20.7 |

1. **HDR 2D alone changes every room.** With `use_hdr_2d` on, the canvas
   is composed in linear space; the ambient multiply and the additive
   lights land differently and the room darkens by seven points (dark 66
   to 73 %, the far wall 22.7 to 19.1). Switching it on is a project
   decision that re-tunes every ambient and light the level-artist has
   set, not a knob on an effect.
2. **Bloom has nothing to catch in this room.** Bright pixels are 3 % and
   the glass is a mid-tone plane (about 0.6). A threshold that spares the
   walls (0.45) raises the band outside the glass by half a luma step,
   invisible; a threshold that shows (0.25) blooms the wall texture too
   and the room stops being dark (46 %), mush. Bloom needs hot pixels: a
   near-white core on the source with a light on it (the emissive
   convention the sprite skills already follow for signs and lamps), or
   HDR with the lights overexposing what they hit. `glow_hot_hdr` shows
   the second: the floor pool under the window and the pane edges bloom
   (the band 34.9 to 54.7) at the cost of the budget (dark 59 %), because
   the boost was a blunt x2.5 on every light.
3. **The shaft is the cheap win.** An additive fan of polygons from the
   glass to the floor, leaning down and left, each band cut into slices
   whose alpha follows a sine across the band (soft edges) and whose
   vertex colours fade to nothing at the floor, placed in the room so the
   ambient darkens it like the rest. At alpha 0.14 to 0.22 it reads as
   the window's light in dusty air (the dress file's motes already sit
   in it), lifts the band outside the glass to 42 to 47, and the budget
   holds (65 to 66 % dark, bright 3 to 4 %). The hard-edged first version
   at 0.28 read as an overlay and broke the budget (bright 6 %, cold
   90 %). Recommended alpha about 0.18.
4. **The order of work for the light family** is therefore: the emissive
   convention first (hot cores on the glass, lamps and signs, each with
   its light), then bloom as project data (HDR 2D on, every room
   re-tuned once, a high threshold so only hot pixels bloom), then shafts
   and halos as authored additive geometry with presets, all placed by
   name from the dress file and judged with the budget rows plus the band
   outside the source.

## What went wrong, for the reference notes

- `godot` on the PATH is a `.cmd` wrapper on Windows: resolve it with
  `shutil.which` over `.exe`, `.cmd`, the bare name (the level-artist's
  `shoot.py` already does).
- Sine-soft slices are side by side, not stacked: their alpha is the
  band's alpha times the sine, not divided by the slice count (the first
  soft shaft was invisible and measured as today).
- A variable named like a parameter (`out`) shadowed the output path; the
  board is `board`.
- A WorldEnvironment with `BG_CANVAS` and glow off still darkens the far
  wall by two luma in LDR; the control row is the shot with nothing added.

## Recommendation

The light family stays in the vfx-artist's contract as refined, with
three changes for the build:

- `reference/light.md` is written from this table: HDR 2D is a project
  decision; bloom needs hot pixels; the shaft recipe and its numbers.
- `scripts/light.py` becomes the shaft and halo authoring (a fan of
  soft slices as data: source rect, lean, spread, alpha, colour, bands)
  plus the bloom setup as data, and the measurement (the budget rows and
  the band outside the source); the emissive convention is a rule in
  `families.md`, not a script.
- The `watch` line "a light effect is judged on the room shot against
  the light budget" gains "and by the band outside its source".
