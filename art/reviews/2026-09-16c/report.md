# Art review -- 2026-09-16c

94 asset(s) across 11 kind(s), against `bible/art.json`: 61 palette entries in 22 ramps, the figure 56 art px = 1.7 m.

## What changed

Against `2026-09-16b`: 0 fixed, 11 new, 39 open (28 then).

**11 new**
- albedo: `tiles/back_collections.png`
- albedo: `tiles/back_gut.png`
- albedo: `tiles/back_mezz.png`
- albedo: `tiles/back_residential.png`
- albedo: `tiles/back_roof.png`
- albedo: `tiles/back_shaft.png`
- albedo: `tiles/wall_collections.png`
- albedo: `tiles/wall_gut.png`
- albedo: `tiles/wall_residential.png`
- albedo: `tiles/wall_roof.png`
- albedo: `tiles/wall_shaft.png`

## Findings

39 on 33 of 94 asset(s), worst first.

| code | assets | where |
|---|---:|---|
| albedo | 11 | back 6, wall 5 |
| outline | 3 | back 1, prop 2 |
| palette | 1 | wall 1 |
| contrast | 10 | character 4, prop 6 |
| flat | 13 | character 1, emissive 3, prop 8, wall 1 |
| figure | 1 | character 1 |

1 asset(s) carry three codes or more, which is usually one cause and not three: `tiles/wall_residential.png`.

### albedo -- 11

- `tiles/back_roof.png` (back): median luma 0.0025 against a floor of 0.025: there is nothing here for a light to bring back
- **2 back(s)**: median luma 0.0052 against a floor of 0.025: there is nothing here for a light to bring back
  - `tiles/back_collections.png`, `tiles/back_gut.png`
- **3 back(s)**: median luma 0.0103 against a floor of 0.025: there is nothing here for a light to bring back
  - `tiles/back_mezz.png`, `tiles/back_residential.png`, `tiles/back_shaft.png`
- `tiles/wall_residential.png` (wall): median luma 0.0000 against a floor of 0.03: there is nothing here for a light to bring back
- `tiles/wall_collections.png` (wall): median luma 0.0177 against a floor of 0.03: there is nothing here for a light to bring back
- `tiles/wall_roof.png` (wall): median luma 0.0196 against a floor of 0.03: there is nothing here for a light to bring back
- `tiles/wall_shaft.png` (wall): median luma 0.0204 against a floor of 0.03: there is nothing here for a light to bring back
- `tiles/wall_gut.png` (wall): median luma 0.0227 against a floor of 0.03: there is nothing here for a light to bring back

### outline -- 3

- `tiles/back_unit_14c.png` (back): 100% of the silhouette's edge is a near-black line (black); an edge is the darker step of the local colour
- `props/unit_14c_boxes.png` (prop): 32% of the silhouette's edge is a near-black line (void); an edge is the darker step of the local colour
- `props/unit_14c_table.png` (prop): 46% of the silhouette's edge is a near-black line (void); an edge is the darker step of the local colour

### palette -- 1

- `tiles/wall_residential.png` (wall): 56.2% of the pixels are off the palette, worst 3.9 dE from void

### contrast -- 10

- `sprites/drone.png` (character): 1.00:1 against tiles/wall_mezz.png, flat, before the room's light
- `sprites/landlord.png` (character): 1.00:1 against tiles/wall_roof.png, flat, before the room's light
- **2 character(s)**: 1.08:1 against tiles/wall_mezz.png, flat, before the room's light
  - `sprites/elite_scav.png`, `sprites/player.png`
- `props/unit_14c_table.png` (prop): 1.00:1 against tiles/wall_gut.png, flat, before the room's light
- **3 prop(s)**: 1.00:1 against tiles/wall_mezz.png, flat, before the room's light
  - `props/breach_door.png`, `props/gadget_crate.png`, `props/lift_deck.png`
- `props/unit_14c_piano.png` (prop): 1.05:1 against tiles/wall_residential.png, flat, before the room's light
- `props/cable.png` (prop): 1.08:1 against tiles/wall_residential.png, flat, before the room's light

### flat -- 13

- `sprites/riot_shield.png` (character): grey is 2 step(s) over 279 art px; a material is 3 to 8
- `props/unit_14c_lamp.png` (emissive): black is 2 step(s) over 268 art px; a material is 3 to 5
- `props/sign_panel_warn.png` (emissive): red is 2 step(s) over 180 art px; a material is 3 to 5
- `props/window.png` (emissive): warm is 1 step(s) over 425 art px; a material is 3 to 5
- `props/door_frame.png` (prop): bg is 1 step(s) over 1968 art px; a material is 3 to 5
- `props/fan.png` (prop): bg is 1 step(s) over 438 art px; a material is 3 to 5
- `props/poster_b.png` (prop): cyan is 2 step(s) over 531 art px; a material is 3 to 5
- `props/poster_a.png` (prop): magenta is 2 step(s) over 531 art px; a material is 3 to 5
- `props/cable.png` (prop): outline is 1 step(s) over 102 art px; a material is 3 to 5
- `props/ram_up.png` (prop): violet is 2 step(s) over 140 art px; a material is 3 to 5
- `props/unit_14c_piano.png` (prop): void is 1 step(s) over 707 art px; a material is 3 to 5
- `props/implant_crate.png` (prop): white is 1 step(s) over 538 art px; a material is 3 to 5
- `tiles/wall_residential.png` (wall): void is 1 step(s) over 35925 art px; a material is 3 to 5

### figure -- 1

- `sprites/drone.png` (character): 24 art px is 0.73 m against the figure; the kind is 0.8-3.0 m

## The set

| asset | kind | plane | size | density | art | colours | off | dominant | steps | ring dark | contrast |
|---|---|---|---:|---:|---|---:|---:|---|---:|---:|---:|
| **`tiles/back_collections.png`** | back | back | 120x120 | 2 | 60x60 | 3 | 0% | bg | 2 | 0% | - |
| **`tiles/back_gut.png`** | back | back | 120x120 | 2 | 60x60 | 3 | 0% | bg | 2 | 0% | - |
| **`tiles/back_mezz.png`** | back | back | 120x120 | 2 | 60x60 | 3 | 0% | bg | 3 | 0% | - |
| **`tiles/back_residential.png`** | back | back | 120x120 | 2 | 60x60 | 3 | 0% | bg | 3 | 0% | - |
| **`tiles/back_roof.png`** | back | back | 120x120 | 2 | 60x60 | 2 | 0% | void | 1 | 0% | - |
| **`tiles/back_shaft.png`** | back | back | 120x120 | 2 | 60x60 | 3 | 0% | bg | 3 | 0% | - |
| **`tiles/back_unit_14c.png`** | back | back | 1800x600 | 2 | 900x300 | 18 | 0% | bg | 4 | 100% | - |
| **`sprites/drone.png`** | character | play | 960x64 | 2 | 480x32 | 19 | 0% | steel | 5 | 22% | 1.0 |
| **`sprites/elite_scav.png`** | character | play | 1920x112 | 2 | 960x56 | 22 | 0% | concrete | 4 | 48% | 1.08 |
| **`sprites/landlord.png`** | character | play | 5616x176 | 2 | 2808x88 | 24 | 0% | concrete | 4 | 56% | 1.0 |
| **`sprites/player.png`** | character | play | 1728x128 | 2 | 864x64 | 33 | 0% | navy | 4 | 49% | 1.08 |
| **`sprites/riot_shield.png`** | character | play | 28x136 | 2 | 14x68 | 12 | 0% | grey | 2 | 32% | 4.62 |
| **`props/sign_panel_warn.png`** | emissive | play | 36x36 | 2 | 18x18 | 3 | 0% | red | 2 | 0% | 1.3 |
| **`props/unit_14c_lamp.png`** | emissive | play | 48x426 | 2 | 24x213 | 5 | 0% | black | 2 | 3% | 1.1 |
| **`props/window.png`** | emissive | play | 72x48 | 2 | 36x24 | 5 | 0% | warm | 1 | 0% | 8.73 |
| **`props/breach_door.png`** | prop | play | 60x174 | 2 | 30x87 | 6 | 0% | steel | 3 | 0% | 1.0 |
| **`props/cable.png`** | prop | play | 120x18 | 2 | 60x9 | 1 | 0% | outline | 1 | 100% | 1.08 |
| **`props/door_frame.png`** | prop | play | 60x180 | 2 | 30x90 | 5 | 0% | bg | 1 | 0% | 1.1 |
| **`props/fan.png`** | prop | play | 60x60 | 2 | 30x30 | 4 | 0% | bg | 1 | 0% | 1.1 |
| **`props/gadget_crate.png`** | prop | play | 72x54 | 2 | 36x27 | 5 | 0% | steel | 4 | 0% | 1.0 |
| **`props/implant_crate.png`** | prop | play | 72x54 | 2 | 36x27 | 4 | 0% | white | 1 | 0% | 10.24 |
| **`props/lift_deck.png`** | prop | play | 60x24 | 2 | 30x12 | 9 | 0% | steel | 4 | 0% | 1.0 |
| **`props/poster_a.png`** | prop | play | 48x60 | 2 | 24x30 | 3 | 0% | magenta | 2 | 0% | 3.38 |
| **`props/poster_b.png`** | prop | play | 48x60 | 2 | 24x30 | 3 | 0% | cyan | 2 | 0% | 7.7 |
| **`props/ram_up.png`** | prop | play | 36x42 | 2 | 18x21 | 5 | 0% | violet | 2 | 0% | 3.33 |
| **`props/unit_14c_boxes.png`** | prop | play | 96x100 | 2 | 48x50 | 19 | 0% | rust | 4 | 32% | 4.72 |
| **`props/unit_14c_piano.png`** | prop | play | 128x104 | 2 | 64x52 | 24 | 0% | void | 1 | 84% | 1.05 |
| **`props/unit_14c_table.png`** | prop | play | 44x36 | 2 | 22x18 | 11 | 0% | rust | 4 | 46% | 1.0 |
| **`tiles/wall_collections.png`** | wall | play | 180x180 | 2 | 90x90 | 5 | 0% | bg | 3 | 0% | - |
| **`tiles/wall_gut.png`** | wall | play | 180x180 | 2 | 90x90 | 4 | 0% | rust | 3 | 0% | - |
| **`tiles/wall_residential.png`** | wall | play | 480x480 | 2 | 240x240 | 13 | 56% | void | 1 | 0% | - |
| **`tiles/wall_roof.png`** | wall | play | 180x180 | 2 | 90x90 | 6 | 0% | concrete | 3 | 0% | - |
| **`tiles/wall_shaft.png`** | wall | play | 180x180 | 2 | 90x90 | 4 | 0% | steel | 3 | 0% | - |
| `sprites/marisol.png` | character | play | 480x120 | 2 | 240x60 | 20 | 0% | hair | 3 | 37% | 1.25 |
| `sprites/riot.png` | character | play | 1632x136 | 2 | 816x68 | 20 | 0% | steel | 5 | 15% | 1.41 |
| `sprites/scav.png` | character | play | 1920x112 | 2 | 960x56 | 27 | 0% | olive | 4 | 21% | 1.87 |
| `sprites/stitch.png` | character | play | 672x120 | 2 | 336x60 | 23 | 0% | rust | 3 | 31% | 2.67 |
| `fx/beam.png` | effect | play | 36x8 | 2 | 18x4 | 2 | 0% | cyan | 1 | 0% | - |
| `fx/bolt.png` | effect | play | 18x6 | 2 | 9x3 | 4 | 0% | amber | 2 | 0% | - |
| `fx/burst_die.png` | effect | play | 1024x128 | 2 | 512x64 | 10 | 0% | steel | 4 | 0% | - |
| `fx/drone_shot.png` | effect | play | 18x18 | 2 | 9x9 | 4 | 0% | red | 2 | 100% | - |
| `fx/dust_land.png` | effect | play | 576x40 | 2 | 288x20 | 4 | 0% | steel | 4 | 0% | - |
| `fx/nail.png` | effect | play | 12x6 | 2 | 6x3 | 3 | 0% | grey | 2 | 0% | - |
| `fx/rivet.png` | effect | play | 24x8 | 2 | 12x4 | 4 | 0% | sodium | 1 | 50% | - |
| `fx/spark.png` | effect | play | 12x4 | 2 | 6x2 | 2 | 0% | amber | 1 | 0% | - |
| `fx/spark_hit.png` | effect | play | 384x64 | 2 | 192x32 | 6 | 0% | amber | 1 | 0% | - |
| `fx/wave.png` | effect | play | 42x30 | 2 | 21x15 | 4 | 0% | amber | 2 | 100% | - |
| `props/breach_terminal.png` | emissive | play | 36x48 | 2 | 18x24 | 7 | 0% | steel | 3 | 0% | 1.41 |
| `props/chip.png` | emissive | play | 36x42 | 2 | 18x21 | 6 | 0% | cyan | 3 | 0% | 7.7 |
| `props/lamp.png` | emissive | play | 24x30 | 2 | 12x15 | 5 | 0% | steel | 3 | 0% | 5.73 |
| `props/monitor.png` | emissive | play | 48x36 | 2 | 24x18 | 6 | 0% | steel | 3 | 0% | 2.65 |
| `props/neon_tube_c.png` | emissive | play | 120x8 | 2 | 60x4 | 3 | 0% | cyan | 3 | 0% | 7.7 |
| `props/neon_tube_m.png` | emissive | play | 120x8 | 2 | 60x4 | 3 | 0% | magenta | 3 | 0% | 3.38 |
| `props/program_terminal.png` | emissive | play | 60x108 | 2 | 30x54 | 9 | 0% | steel | 4 | 0% | 1.0 |
| `props/save_terminal.png` | emissive | play | 72x132 | 2 | 36x66 | 9 | 0% | steel | 3 | 0% | 1.0 |
| `props/sign_panel.png` | emissive | play | 36x36 | 2 | 18x18 | 4 | 0% | steel | 3 | 0% | 1.41 |
| `props/unit_14c_crt.png` | emissive | play | 24x60 | 2 | 12x30 | 17 | 0% | rust | 2 | 20% | 1.3 |
| `tiles/sky_gradient.png` | gradient | free | 3x540 | 3 | 1x180 | 77 | 93% | bg | 3 | 0% | - |
| `fx/dot.png` | mask | free | 8x8 | 1 | 8x8 | 1 | 100% | white | 1 | 0% | - |
| `fx/drop.png` | mask | free | 2x10 | 1 | 2x10 | 2 | 0% | steel | 2 | 0% | - |
| `fx/light_hard.png` | mask | free | 64x64 | 1 | 64x64 | 1 | 100% | white | 1 | 0% | - |
| `fx/light_soft.png` | mask | free | 128x128 | 1 | 128x128 | 1 | 100% | white | 1 | 0% | - |
| `fx/puff.png` | mask | free | 16x16 | 1 | 16x16 | 1 | 100% | white | 1 | 0% | - |
| `tiles/outside_unit_14c.png` | outside | outside | 512x512 | 4 | 128x128 | 7 | 0% | steel | 3 | 0% | - |
| `tiles/skyline_far.png` | outside | outside | 960x540 | 4 | 240x135 | 3 | 0% | bg | 1 | 99% | - |
| `tiles/skyline_near.png` | outside | outside | 960x540 | 4 | 240x135 | 3 | 0% | bg | 1 | 100% | - |
| `tiles/hazard_0.png` | platform | play | 60x60 | 2 | 30x30 | 6 | 0% | bg | 3 | 0% | - |
| `tiles/hazard_1.png` | platform | play | 60x60 | 2 | 30x30 | 6 | 0% | bg | 3 | 0% | - |
| `tiles/hazard_2.png` | platform | play | 60x60 | 2 | 30x30 | 6 | 0% | bg | 3 | 0% | - |
| `tiles/platform.png` | platform | play | 60x12 | 2 | 30x6 | 4 | 0% | steel | 4 | 0% | - |
| `props/awning.png` | prop | play | 180x24 | 2 | 90x12 | 3 | 0% | magenta | 3 | 0% | 3.38 |
| `props/barrel.png` | prop | play | 36x48 | 2 | 18x24 | 4 | 0% | steel | 3 | 0% | 1.41 |
| `props/body.png` | prop | play | 96x36 | 2 | 48x18 | 8 | 0% | rust | 3 | 6% | 1.33 |
| `props/chest.png` | prop | play | 72x54 | 2 | 36x27 | 5 | 0% | olive | 3 | 0% | 1.48 |
| `props/crates.png` | prop | play | 72x60 | 2 | 36x30 | 3 | 0% | rust | 3 | 0% | 1.33 |
| `props/grate.png` | prop | play | 60x60 | 2 | 30x30 | 4 | 0% | steel | 3 | 0% | 1.41 |
| `props/hp_up.png` | prop | play | 36x42 | 2 | 18x21 | 4 | 0% | red | 3 | 0% | 3.63 |
| `props/pipe_h.png` | prop | play | 120x18 | 2 | 60x9 | 5 | 0% | steel | 5 | 0% | 1.41 |
| `props/pipe_v.png` | prop | play | 18x120 | 2 | 9x60 | 4 | 0% | steel | 4 | 0% | 1.41 |
| `props/tease_crate.png` | prop | play | 48x48 | 2 | 24x24 | 4 | 0% | amber | 3 | 0% | 6.77 |
| `props/unit_14c_bedroll.png` | prop | play | 120x24 | 2 | 60x12 | 16 | 0% | olive | 4 | 17% | 2.44 |
| `props/unit_14c_box.png` | prop | play | 50x32 | 2 | 25x16 | 9 | 0% | rust | 3 | 9% | 4.72 |
| `props/unit_14c_crate.png` | prop | play | 40x40 | 2 | 20x20 | 10 | 0% | rust | 3 | 10% | 2.67 |
| `props/unit_14c_papers_a.png` | prop | play | 24x20 | 2 | 12x10 | 7 | 0% | concrete | 2 | 4% | 4.62 |
| `props/unit_14c_papers_b.png` | prop | play | 64x14 | 2 | 32x7 | 6 | 0% | white | 1 | 8% | 10.24 |
| `props/vent.png` | prop | play | 60x36 | 2 | 30x18 | 4 | 0% | steel | 3 | 0% | 1.41 |
| `ui/cursor.png` | screen | screen | 24x24 | 3 | 8x8 | 2 | 0% | outline | 1 | 100% | - |
| `ui/hud_frame.png` | screen | screen | 24x24 | 3 | 8x8 | 3 | 0% | bg | 1 | 0% | - |
| `ui/lock.png` | screen | screen | 24x24 | 3 | 8x8 | 2 | 0% | outline | 1 | 69% | - |
| `ui/panel_frame.png` | screen | screen | 24x24 | 3 | 8x8 | 3 | 0% | bg | 1 | 0% | - |
| `ui/pip_off.png` | screen | screen | 18x18 | 3 | 6x6 | 2 | 0% | outline | 1 | 0% | - |
| `ui/pip_on.png` | screen | screen | 18x18 | 3 | 6x6 | 3 | 0% | outline | 1 | 0% | - |
| `ui/slot.png` | screen | screen | 72x72 | 3 | 24x24 | 3 | 0% | bg | 1 | 0% | - |
| `tiles/wall_mezz.png` | wall | play | 180x180 | 2 | 90x90 | 4 | 0% | steel | 4 | 0% | - |

## The judgement

- **Albedo.** Eleven of the thirteen surfaces the district is made of are
  painted too dark to be lit: the six back planes at 0.0025 to 0.0103 median
  luminance against a floor of 0.025, and five of the six walls under 0.03.
  This is a new measurement, added today because the first version of this
  skill measured every asset's contrast *against* the plane behind it and
  never the plane's own albedo -- so the biggest art problem in the game was
  the one thing the review could not see.
- **Density.** Still zero, across all 94 assets. Nothing regressed.
- **Palette.** Still one: `tiles/wall_residential.png`, which is also the
  worst albedo (0.0000) and the worst flat material. One asset, three codes,
  one re-bake.
- **Shading.** Unchanged: 3 near-black rings, all on the hi-bit props, and 13
  flat materials.
- **Scale.** Unchanged, one finding.
- **Readability.** Unchanged at ten under 1.10:1 -- and now explained. An
  asset the same luminance as the wall behind it is what happens when the
  wall is painted at a fiftieth of what a wall should be.
- **Consistency.** The set reads as one style at 1:1 on the board. It does
  not read as one style *in the engine*, and the reason is not in the assets'
  relationship to each other but in their relationship to the light.

## The one change

**Repaint the six back planes and the five walls to a mid-tone albedo** --
environment-artist. The brief, with every number and the two assets that
already pass, is `art/briefs/2026-09-16-environment-artist.md`.

Thirty-four rooms were lit from a vocabulary today and the district moved
three percentage points, from 95% dark to 92% in the best case. The level-
artist's own calibration table has that row -- "ring and lights, no planes:
98% dark, 0% bright" -- and the rule under it: bright comes from a surface,
never from a light on a dark wall. There is no lighting pass that fixes this
and no energy that is high enough.

What stays broken after it, on purpose: everything in the previous review's
list, because none of it moved and none of it is upstream of this. The three
hi-bit rings want the edge pass `make_props.py` now has; the flat materials
want a step added each; the drone wants six art pixels. All of them are
cheaper after the planes are repainted, because a lit room is the only place
any of them can actually be judged.

