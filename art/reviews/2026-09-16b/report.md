# Art review -- 2026-09-16b

94 asset(s) across 11 kind(s), against `bible/art.json`: 61 palette entries in 22 ramps, the figure 56 art px = 1.7 m.

## What changed

Against `2026-09-16`: 89 fixed, 3 new, 28 open (114 then).

**89 fixed**
- density: `fx/beam.png`
- density: `fx/bolt.png`
- density: `fx/drone_shot.png`
- density: `fx/nail.png`
- density: `fx/rivet.png`
- density: `fx/wave.png`
- density: `props/awning.png`
- flat: `props/awning.png`
- outline: `props/awning.png`
- contrast: `props/barrel.png`
- density: `props/barrel.png`
- outline: `props/barrel.png`
- ... 77 more

**3 new**
- flat: `props/cable.png`
- flat: `props/ram_up.png`
- flat: `props/sign_panel_warn.png`

**density moved**
- `fx/beam.png` density 3 -> 2
- `fx/bolt.png` density 3 -> 2
- `fx/drone_shot.png` density 3 -> 2
- `fx/nail.png` density 3 -> 2
- `fx/rivet.png` density 3 -> 2
- `fx/wave.png` density 3 -> 2
- `props/awning.png` density 3 -> 2
- `props/barrel.png` density 3 -> 2
- `props/body.png` density 3 -> 2
- `props/breach_door.png` density 3 -> 2
- `props/breach_terminal.png` density 3 -> 2
- `props/cable.png` density 3 -> 2

## Findings

28 on 23 of 94 asset(s), worst first.

| code | assets | where |
|---|---:|---|
| outline | 3 | back 1, prop 2 |
| palette | 1 | wall 1 |
| contrast | 10 | character 4, prop 6 |
| flat | 13 | character 1, emissive 3, prop 8, wall 1 |
| figure | 1 | character 1 |

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
| **`tiles/wall_residential.png`** | wall | play | 480x480 | 2 | 240x240 | 13 | 56% | void | 1 | 0% | - |
| `tiles/back_collections.png` | back | back | 120x120 | 2 | 60x60 | 3 | 0% | bg | 2 | 0% | - |
| `tiles/back_gut.png` | back | back | 120x120 | 2 | 60x60 | 3 | 0% | bg | 2 | 0% | - |
| `tiles/back_mezz.png` | back | back | 120x120 | 2 | 60x60 | 3 | 0% | bg | 3 | 0% | - |
| `tiles/back_residential.png` | back | back | 120x120 | 2 | 60x60 | 3 | 0% | bg | 3 | 0% | - |
| `tiles/back_roof.png` | back | back | 120x120 | 2 | 60x60 | 2 | 0% | void | 1 | 0% | - |
| `tiles/back_shaft.png` | back | back | 120x120 | 2 | 60x60 | 3 | 0% | bg | 3 | 0% | - |
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
| `tiles/wall_collections.png` | wall | play | 180x180 | 2 | 90x90 | 5 | 0% | bg | 3 | 0% | - |
| `tiles/wall_gut.png` | wall | play | 180x180 | 2 | 90x90 | 4 | 0% | rust | 3 | 0% | - |
| `tiles/wall_mezz.png` | wall | play | 180x180 | 2 | 90x90 | 4 | 0% | steel | 4 | 0% | - |
| `tiles/wall_roof.png` | wall | play | 180x180 | 2 | 90x90 | 6 | 0% | concrete | 3 | 0% | - |
| `tiles/wall_shaft.png` | wall | play | 180x180 | 2 | 90x90 | 4 | 0% | steel | 3 | 0% | - |

## The judgement

- **Density.** One pixel size across all 94 assets. This is what the review
  was for: 55 assets were off their plane this morning and none is now, and
  the two generations of environment art that the first board separated on
  sight are one generation. `make_tiles.py`'s `T` is a real constant instead
  of a comment over forty typed 60s, and `make_props.py` no longer decides
  its own scale.
- **Palette.** One asset off it, and it is the same one as this morning:
  `tiles/wall_residential.png`, 56% off, worst 3.9 dE. It came from a
  diffusion still through `swatch.py` and never went through
  `snap_to_palette`. Everything else in the game is exactly on the palette.
- **Shading.** The edge is fixed and is now drawn rather than typed: 22
  near-black silhouette rings this morning, 3 tonight, and all three are on
  the hi-bit props that this pass did not touch. Volume is not fixed: 13
  materials are still flatter than the bar's three steps, and the worst of
  them by a factor of eighteen is `wall_residential` at one step over 35,925
  art px -- the largest single surface in the game, in five rooms.
- **Scale.** Unchanged and still one finding in 94: the drone draws 24 art
  px, 0.73 m, against a cast brief of 30.
- **Readability.** Unchanged at ten assets under 1.10:1 flat, four of them
  characters. Nothing in this pass moved it, which is right -- it is a
  lighting conversation with the level-artist, not an authoring one.
- **Consistency.** The board no longer splits. Every play-plane asset shows
  one grain swatch, the props sit at the character's pixel, and the old
  ASCII generation and the hi-bit generation differ now only in how much
  shading they carry -- which is a question about craft and no longer a
  question about which game this is.

## The one change

**Re-snap `tiles/wall_residential.png` through the bake** -- environment-artist.

It is the only palette failure in 94 assets and the worst flat material in
the game, and it is one asset and one command: it already has its set json
and its chosen seed (`game/tools/art/sets/residential.json`, dream seed 3),
so this is `swatch.py residential bake --seed 3` with the snap actually
applied, not a redraw. It clears two of the twenty-eight findings, and it
clears them on 240x240 art pixels of wall standing behind the player in
five rooms -- more surface than every prop in the game put together.

What stays broken after it, on purpose: the twelve other flat materials
(`door_frame` at one step over 1,968 art px is the next worst, then
`implant_crate`, `poster_a` and `poster_b`); the three near-black rings on
`back_unit_14c`, `unit_14c_boxes` and `unit_14c_table`, which are the hi-bit
props and want the same edge pass `make_props.py` now has; the ten flat
contrasts, which are the level-artist's lights; and the drone's six missing
art pixels. `ram_up` cannot be fixed at all without a third violet in the
palette, and adding one re-snaps every sprite, so it stays as it is and this
line is the reason.

