# To the environment-artist: the planes are painted too dark to light

From the art-director, 2026-09-16, after the density pass and the district's
lighting pass. The numbers behind every line here are in
`art/reviews/2026-09-16c/measure.json` and `plan/log.md`.

## The ask, in one line

**Repaint the six back planes and the five walls to a mid-tone albedo so the
ambient and the lights have something to bring back.** The floors are in
`bible/art.json` (`back.albedo_min` 0.025, `wall.albedo_min` 0.03) and the
art-director now measures them every review, so this is a check you can run
rather than a note you have to remember.

## What happened

Thirty-four rooms were lit from a vocabulary (`game/tools/stacks/dress_vocab.json`),
one dress file each, with key lamps along every floor run, a fill wash, a
light over every ledge and an accent at every marker. The district moved
three percentage points:

| room | before | after |
|---|---:|---:|
| hall_13 | 95% dark | 92% |
| mezz | 93% | 91% |
| gut_pumps | 99% | 98% |
| service_tunnel | 97% | 96% |
| west_stair | 99% | 98% |

The budget in the level-artist's `reference/lighting.md` is dark 40-60%,
bright 6-10%. Not one room in the district reaches 2% bright. Under the slab
(`--crop-top`), hall_13 is still 86% dark and 1% bright.

That reference already has the row we are sitting on, from when 14-C was
dressed:

| stage | dark | mid | bright |
|---|---|---|---|
| **ring and lights, no planes** | **98%** | **2%** | **0%** |
| outside on its own canvas | 75% | 19% | 6% |
| mid-tone walls, authored skyline | 73% | 21% | 6% |
| the same, under the slab | 58% | 33% | 10% |

and the rule under it: *"Bright comes from a surface, never from a light on a
dark wall... if a lit wall stays black, it is painted too dark. Back to the
environment-artist, not up with the energy."*

## The measurement

Median luminance of the opaque pixels. Nothing on the canvas can be brighter
than albedo x ambient + light, so this is the ceiling every room is working
under.

| asset | median luma | floor | |
|---|---:|---:|---|
| `tiles/back_roof.png` | 0.0025 | 0.025 | 10x under |
| `tiles/back_collections.png` | 0.0052 | 0.025 | 4.8x under |
| `tiles/back_gut.png` | 0.0052 | 0.025 | 4.8x under |
| `tiles/back_mezz.png` | 0.0103 | 0.025 | 2.4x under |
| `tiles/back_residential.png` | 0.0103 | 0.025 | 2.4x under |
| `tiles/back_shaft.png` | 0.0103 | 0.025 | 2.4x under |
| **`tiles/back_unit_14c.png`** | **0.0297** | 0.025 | **passes** |
| `tiles/wall_residential.png` | 0.0000 | 0.03 | and 56% off-palette |
| `tiles/wall_collections.png` | 0.0177 | 0.03 | 1.7x under |
| `tiles/wall_roof.png` | 0.0196 | 0.03 | 1.5x under |
| `tiles/wall_shaft.png` | 0.0204 | 0.03 | 1.5x under |
| `tiles/wall_gut.png` | 0.0227 | 0.03 | 1.3x under |
| **`tiles/wall_mezz.png`** | **0.0398** | 0.03 | **passes** |

The two that pass are the evidence the floors are set from, not a book:
`back_unit_14c` is the only back plane in a room that ever measured inside
the budget, and `wall_mezz` is the one wall that reads in a shot.

## What this is not

- **Not a lighting problem.** The lights are placed, coloured per district
  and spaced; raising their energy further only blooms the few lit pixels.
  `lighting.md` step 4 says energy over 3 is itself the sign of this bug.
- **Not a density problem.** Every one of these eleven assets is at its
  plane's density as of today; the density findings across all 94 assets are
  zero.
- **Not the ambient.** It multiplies; it cannot lift 0.0025 anywhere useful.

## While you are in there

Two more findings on assets that are yours, from the same review:

- `tiles/wall_residential.png` is the only palette failure in 94 assets, 56%
  off it, worst 3.9 dE, and one step of `void` over 35,925 art px. It came
  from a diffusion still through `swatch.py` and never went through
  `snap_to_palette`. It has its set json and its chosen seed already
  (`game/tools/art/sets/residential.json`, dream seed 3), so it is a re-bake
  with the snap applied and not a redraw. Fixing the albedo and the snap in
  the same pass costs one command.
- `back_unit_14c.png`, `unit_14c_boxes.png` and `unit_14c_table.png` carry a
  near-black line round 100%, 32% and 46% of their silhouettes. `make_props.py`
  now derives that edge instead of typing it (`edge()`, and `RAMPS` is the
  shading bar as data) -- the hi-bit props predate it and want the same pass.

## How to check you are done

```
python art-director/scripts/audit.py --project <root>      # albedo findings -> 0
python level-artist/scripts/shoot.py --project game --room res://rooms/stacks/hall_13.tscn --out work/h.png
```

The first is the contract. The second is the judge: the room should come back
inside dark 40-60%, bright 6-10%, and the district should read the same way
in every style. Then M8's sign-off -- "the district reads as one style at
1:1" -- is a question somebody can honestly answer.
