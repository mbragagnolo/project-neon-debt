# Art review -- 2026-09-16

94 asset(s) across 11 kind(s), against `bible/art.json`: 61 palette entries in 22 ramps, the figure 56 art px = 1.7 m.

## What changed

First review: nothing to compare against.

## Findings

114 on 66 of 94 asset(s), worst first.

| code | assets | where |
|---|---:|---|
| density | 55 | back 6, effect 6, emissive 11, outside 2, platform 4, prop 21, wall 5 |
| outline | 22 | back 1, emissive 5, prop 16 |
| palette | 1 | wall 1 |
| contrast | 14 | character 4, prop 10 |
| flat | 21 | character 1, emissive 4, platform 3, prop 12, wall 1 |
| figure | 1 | character 1 |

16 asset(s) carry three codes or more, which is usually one cause and not three: `props/awning.png`, `props/barrel.png`, `props/breach_door.png`, `props/chest.png`, `props/crates.png`, `props/gadget_crate.png`, `props/grate.png`, `props/implant_crate.png`, `props/lift_deck.png`, `props/pipe_h.png`, `props/poster_a.png`, `props/poster_b.png`, `props/program_terminal.png`, `props/save_terminal.png`, `props/tease_crate.png`, `props/window.png`.

### density -- 55

- **6 back(s)**: 3 texture px per art px on the back plane, which is 2
  - `tiles/back_collections.png`, `tiles/back_gut.png`, `tiles/back_mezz.png`, `tiles/back_residential.png`, `tiles/back_roof.png`, `tiles/back_shaft.png`
- **6 effect(s)**: 3 texture px per art px on the play plane, which is 2
  - `fx/beam.png`, `fx/bolt.png`, `fx/drone_shot.png`, `fx/nail.png`, `fx/rivet.png`, `fx/wave.png`
- **11 emissive(s)**: 3 texture px per art px on the play plane, which is 2
  - `props/breach_terminal.png`, `props/chip.png`, `props/lamp.png`, `props/monitor.png`, `props/neon_tube_c.png`, `props/neon_tube_m.png`, `props/program_terminal.png`, `props/save_terminal.png`, `props/sign_panel.png`, `props/sign_panel_warn.png`, `props/window.png`
- **2 outside(s)**: 3 texture px per art px on the outside plane, which is 4
  - `tiles/skyline_far.png`, `tiles/skyline_near.png`
- **4 platform(s)**: 3 texture px per art px on the play plane, which is 2
  - `tiles/hazard_0.png`, `tiles/hazard_1.png`, `tiles/hazard_2.png`, `tiles/platform.png`
- **21 prop(s)**: 3 texture px per art px on the play plane, which is 2
  - `props/awning.png`, `props/barrel.png`, `props/body.png`, `props/breach_door.png`, `props/cable.png`, `props/chest.png`, `props/crates.png`, `props/door_frame.png`, `props/fan.png`, `props/gadget_crate.png`, `props/grate.png`, `props/hp_up.png`, `props/implant_crate.png`, `props/lift_deck.png`, `props/pipe_h.png`, `props/pipe_v.png`, `props/poster_a.png`, `props/poster_b.png`, `props/ram_up.png`, `props/tease_crate.png`, `props/vent.png`
- **5 wall(s)**: 3 texture px per art px on the play plane, which is 2
  - `tiles/wall_collections.png`, `tiles/wall_gut.png`, `tiles/wall_mezz.png`, `tiles/wall_roof.png`, `tiles/wall_shaft.png`

### outline -- 22

- `tiles/back_unit_14c.png` (back): 100% of the silhouette's edge is a near-black line (black); an edge is the darker step of the local colour
- **5 emissive(s)**: 100% of the silhouette's edge is a near-black line (outline); an edge is the darker step of the local colour
  - `props/lamp.png`, `props/monitor.png`, `props/program_terminal.png`, `props/save_terminal.png`, `props/window.png`
- **13 prop(s)**: 100% of the silhouette's edge is a near-black line (outline); an edge is the darker step of the local colour
  - `props/awning.png`, `props/barrel.png`, `props/body.png`, `props/crates.png`, `props/gadget_crate.png`, `props/hp_up.png`, `props/implant_crate.png`, `props/lift_deck.png`, `props/pipe_h.png`, `props/poster_a.png`, `props/poster_b.png`, `props/ram_up.png`, `props/tease_crate.png`
- `props/unit_14c_boxes.png` (prop): 32% of the silhouette's edge is a near-black line (void); an edge is the darker step of the local colour
- `props/unit_14c_table.png` (prop): 46% of the silhouette's edge is a near-black line (void); an edge is the darker step of the local colour
- `props/chest.png` (prop): 97% of the silhouette's edge is a near-black line (outline); an edge is the darker step of the local colour

### palette -- 1

- `tiles/wall_residential.png` (wall): 56.2% of the pixels are off the palette, worst 3.9 dE from void

### contrast -- 14

- `sprites/drone.png` (character): 1.00:1 against tiles/wall_mezz.png, flat, before the room's light
- `sprites/landlord.png` (character): 1.00:1 against tiles/wall_roof.png, flat, before the room's light
- **2 character(s)**: 1.08:1 against tiles/wall_mezz.png, flat, before the room's light
  - `sprites/elite_scav.png`, `sprites/player.png`
- `props/unit_14c_table.png` (prop): 1.00:1 against tiles/wall_gut.png, flat, before the room's light
- **5 prop(s)**: 1.00:1 against tiles/wall_mezz.png, flat, before the room's light
  - `props/breach_door.png`, `props/gadget_crate.png`, `props/lift_deck.png`, `props/pipe_h.png`, `props/pipe_v.png`
- `props/unit_14c_piano.png` (prop): 1.05:1 against tiles/wall_residential.png, flat, before the room's light
- `props/barrel.png` (prop): 1.08:1 against tiles/wall_mezz.png, flat, before the room's light
- **2 prop(s)**: 1.08:1 against tiles/wall_residential.png, flat, before the room's light
  - `props/cable.png`, `props/grate.png`

### flat -- 21

- `sprites/riot_shield.png` (character): grey is 2 step(s) over 279 art px; a material is 3 to 8
- `props/unit_14c_lamp.png` (emissive): black is 2 step(s) over 268 art px; a material is 3 to 5
- `props/program_terminal.png` (emissive): steel is 2 step(s) over 303 art px; a material is 3 to 5
- `props/save_terminal.png` (emissive): steel is 2 step(s) over 504 art px; a material is 3 to 5
- `props/window.png` (emissive): warm is 1 step(s) over 177 art px; a material is 3 to 5
- **3 platform(s)**: bg is 1 step(s) over 220 art px; a material is 3 to 5
  - `tiles/hazard_0.png`, `tiles/hazard_1.png`, `tiles/hazard_2.png`
- `props/tease_crate.png` (prop): amber is 2 step(s) over 152 art px; a material is 3 to 5
- `props/fan.png` (prop): bg is 1 step(s) over 186 art px; a material is 3 to 5
- `props/door_frame.png` (prop): bg is 1 step(s) over 880 art px; a material is 3 to 5
- `props/poster_b.png` (prop): cyan is 2 step(s) over 174 art px; a material is 3 to 5
- `props/poster_a.png` (prop): magenta is 2 step(s) over 174 art px; a material is 3 to 5
- `props/awning.png` (prop): magenta is 2 step(s) over 290 art px; a material is 3 to 5
- `props/chest.png` (prop): olive is 2 step(s) over 227 art px; a material is 3 to 5
- `props/grate.png` (prop): outline is 1 step(s) over 240 art px; a material is 3 to 5
- `props/crates.png` (prop): rust is 2 step(s) over 160 art px; a material is 3 to 5
- `props/breach_door.png` (prop): steel is 2 step(s) over 925 art px; a material is 3 to 5
- `props/unit_14c_piano.png` (prop): void is 1 step(s) over 707 art px; a material is 3 to 5
- `props/implant_crate.png` (prop): white is 1 step(s) over 202 art px; a material is 3 to 5
- `tiles/wall_residential.png` (wall): void is 1 step(s) over 35925 art px; a material is 3 to 5

### figure -- 1

- `sprites/drone.png` (character): 24 art px is 0.73 m against the figure; the kind is 0.8-3.0 m

## The set

| asset | kind | plane | size | density | art | colours | off | dominant | steps | ring dark | contrast |
|---|---|---|---:|---:|---|---:|---:|---|---:|---:|---:|
| **`tiles/back_collections.png`** | back | back | 120x120 | 3 | 40x40 | 3 | 0% | bg | 2 | 0% | - |
| **`tiles/back_gut.png`** | back | back | 120x120 | 3 | 40x40 | 3 | 0% | bg | 2 | 0% | - |
| **`tiles/back_mezz.png`** | back | back | 120x120 | 3 | 40x40 | 3 | 0% | bg | 3 | 0% | - |
| **`tiles/back_residential.png`** | back | back | 120x120 | 3 | 40x40 | 3 | 0% | bg | 3 | 0% | - |
| **`tiles/back_roof.png`** | back | back | 120x120 | 3 | 40x40 | 2 | 0% | void | 1 | 0% | - |
| **`tiles/back_shaft.png`** | back | back | 120x120 | 3 | 40x40 | 3 | 0% | bg | 3 | 0% | - |
| **`tiles/back_unit_14c.png`** | back | back | 1800x600 | 2 | 900x300 | 18 | 0% | bg | 4 | 100% | - |
| **`sprites/drone.png`** | character | play | 960x64 | 2 | 480x32 | 19 | 0% | steel | 5 | 22% | 1.0 |
| **`sprites/elite_scav.png`** | character | play | 1920x112 | 2 | 960x56 | 22 | 0% | concrete | 4 | 48% | 1.08 |
| **`sprites/landlord.png`** | character | play | 5616x176 | 2 | 2808x88 | 24 | 0% | concrete | 4 | 56% | 1.0 |
| **`sprites/player.png`** | character | play | 1728x128 | 2 | 864x64 | 33 | 0% | navy | 4 | 49% | 1.08 |
| **`sprites/riot_shield.png`** | character | play | 28x136 | 2 | 14x68 | 12 | 0% | grey | 2 | 32% | 4.62 |
| **`fx/beam.png`** | effect | play | 36x9 | 3 | 12x3 | 2 | 0% | cyan | 1 | 0% | - |
| **`fx/bolt.png`** | effect | play | 18x6 | 3 | 6x2 | 4 | 0% | amber | 2 | 0% | - |
| **`fx/drone_shot.png`** | effect | play | 18x18 | 3 | 6x6 | 4 | 0% | outline | 1 | 100% | - |
| **`fx/nail.png`** | effect | play | 12x6 | 3 | 4x2 | 3 | 0% | grey | 2 | 0% | - |
| **`fx/rivet.png`** | effect | play | 24x9 | 3 | 8x3 | 4 | 0% | sodium | 1 | 44% | - |
| **`fx/wave.png`** | effect | play | 42x30 | 3 | 14x10 | 4 | 0% | amber | 2 | 100% | - |
| **`props/breach_terminal.png`** | emissive | play | 36x48 | 3 | 12x16 | 5 | 0% | outline | 1 | 100% | 1.08 |
| **`props/chip.png`** | emissive | play | 36x42 | 3 | 12x14 | 3 | 0% | outline | 1 | 100% | 1.08 |
| **`props/lamp.png`** | emissive | play | 24x30 | 3 | 8x10 | 4 | 0% | outline | 1 | 100% | 1.41 |
| **`props/monitor.png`** | emissive | play | 48x36 | 3 | 16x12 | 5 | 0% | green | 2 | 100% | 1.41 |
| **`props/neon_tube_c.png`** | emissive | play | 123x9 | 3 | 41x3 | 2 | 0% | outline | 1 | 100% | 1.08 |
| **`props/neon_tube_m.png`** | emissive | play | 123x9 | 3 | 41x3 | 2 | 0% | outline | 1 | 100% | 1.08 |
| **`props/program_terminal.png`** | emissive | play | 60x108 | 3 | 20x36 | 7 | 0% | steel | 2 | 100% | 1.0 |
| **`props/save_terminal.png`** | emissive | play | 72x132 | 3 | 24x44 | 8 | 0% | steel | 2 | 100% | 1.0 |
| **`props/sign_panel.png`** | emissive | play | 36x36 | 3 | 12x12 | 3 | 0% | bg | 1 | 0% | 1.12 |
| **`props/sign_panel_warn.png`** | emissive | play | 36x36 | 3 | 12x12 | 3 | 0% | bg | 1 | 0% | 1.12 |
| **`props/unit_14c_lamp.png`** | emissive | play | 48x426 | 2 | 24x213 | 5 | 0% | black | 2 | 3% | 1.1 |
| **`props/window.png`** | emissive | play | 72x48 | 3 | 24x16 | 4 | 0% | warm | 1 | 100% | 2.65 |
| **`tiles/skyline_far.png`** | outside | outside | 960x540 | 3 | 320x180 | 3 | 0% | bg | 1 | 100% | - |
| **`tiles/skyline_near.png`** | outside | outside | 960x540 | 3 | 320x180 | 3 | 0% | bg | 1 | 100% | - |
| **`tiles/hazard_0.png`** | platform | play | 60x60 | 3 | 20x20 | 4 | 0% | bg | 1 | 0% | - |
| **`tiles/hazard_1.png`** | platform | play | 60x60 | 3 | 20x20 | 4 | 0% | bg | 1 | 0% | - |
| **`tiles/hazard_2.png`** | platform | play | 60x60 | 3 | 20x20 | 4 | 0% | bg | 1 | 0% | - |
| **`tiles/platform.png`** | platform | play | 60x15 | 3 | 20x5 | 4 | 0% | steel | 4 | 0% | - |
| **`props/awning.png`** | prop | play | 180x24 | 3 | 60x8 | 3 | 0% | magenta | 2 | 100% | 1.31 |
| **`props/barrel.png`** | prop | play | 36x48 | 3 | 12x16 | 3 | 0% | concrete | 1 | 100% | 1.08 |
| **`props/body.png`** | prop | play | 96x36 | 3 | 32x12 | 6 | 0% | outline | 1 | 100% | 1.33 |
| **`props/breach_door.png`** | prop | play | 60x174 | 3 | 20x58 | 5 | 0% | steel | 2 | 0% | 1.0 |
| **`props/cable.png`** | prop | play | 120x18 | 3 | 40x6 | 1 | 0% | outline | 1 | 100% | 1.08 |
| **`props/chest.png`** | prop | play | 72x54 | 3 | 24x18 | 4 | 0% | olive | 2 | 97% | 1.48 |
| **`props/crates.png`** | prop | play | 72x60 | 3 | 24x20 | 3 | 0% | rust | 2 | 100% | 1.33 |
| **`props/door_frame.png`** | prop | play | 60x180 | 3 | 20x60 | 5 | 0% | bg | 1 | 0% | 1.1 |
| **`props/fan.png`** | prop | play | 60x60 | 3 | 20x20 | 3 | 0% | bg | 1 | 100% | 1.1 |
| **`props/gadget_crate.png`** | prop | play | 72x54 | 3 | 24x18 | 5 | 0% | steel | 3 | 100% | 1.0 |
| **`props/grate.png`** | prop | play | 60x60 | 3 | 20x20 | 2 | 0% | outline | 1 | 0% | 1.08 |
| **`props/hp_up.png`** | prop | play | 36x42 | 3 | 12x14 | 3 | 0% | red | 1 | 100% | 3.63 |
| **`props/implant_crate.png`** | prop | play | 72x54 | 3 | 24x18 | 4 | 0% | white | 1 | 100% | 10.24 |
| **`props/lift_deck.png`** | prop | play | 60x24 | 3 | 20x8 | 5 | 0% | steel | 2 | 100% | 1.0 |
| **`props/pipe_h.png`** | prop | play | 120x18 | 3 | 40x6 | 4 | 0% | steel | 3 | 100% | 1.0 |
| **`props/pipe_v.png`** | prop | play | 18x120 | 3 | 6x40 | 4 | 0% | steel | 3 | 0% | 1.0 |
| **`props/poster_a.png`** | prop | play | 48x60 | 3 | 16x20 | 4 | 0% | magenta | 2 | 100% | 1.31 |
| **`props/poster_b.png`** | prop | play | 48x60 | 3 | 16x20 | 4 | 0% | cyan | 2 | 100% | 2.27 |
| **`props/ram_up.png`** | prop | play | 36x42 | 3 | 12x14 | 4 | 0% | violet | 2 | 100% | 1.25 |
| **`props/tease_crate.png`** | prop | play | 48x48 | 3 | 16x16 | 4 | 0% | amber | 2 | 100% | 2.3 |
| **`props/unit_14c_boxes.png`** | prop | play | 96x100 | 2 | 48x50 | 19 | 0% | rust | 4 | 32% | 4.72 |
| **`props/unit_14c_piano.png`** | prop | play | 128x104 | 2 | 64x52 | 24 | 0% | void | 1 | 84% | 1.05 |
| **`props/unit_14c_table.png`** | prop | play | 44x36 | 2 | 22x18 | 11 | 0% | rust | 4 | 46% | 1.0 |
| **`props/vent.png`** | prop | play | 60x36 | 3 | 20x12 | 3 | 0% | steel | 1 | 100% | 1.1 |
| **`tiles/wall_collections.png`** | wall | play | 180x180 | 3 | 60x60 | 5 | 0% | bg | 3 | 0% | - |
| **`tiles/wall_gut.png`** | wall | play | 180x180 | 3 | 60x60 | 4 | 0% | rust | 3 | 0% | - |
| **`tiles/wall_mezz.png`** | wall | play | 180x180 | 3 | 60x60 | 4 | 0% | steel | 4 | 0% | - |
| **`tiles/wall_residential.png`** | wall | play | 480x480 | 2 | 240x240 | 13 | 56% | void | 1 | 0% | - |
| **`tiles/wall_roof.png`** | wall | play | 180x180 | 3 | 60x60 | 6 | 0% | concrete | 3 | 0% | - |
| **`tiles/wall_shaft.png`** | wall | play | 180x180 | 3 | 60x60 | 4 | 0% | steel | 3 | 0% | - |
| `sprites/marisol.png` | character | play | 480x120 | 2 | 240x60 | 20 | 0% | hair | 3 | 37% | 1.25 |
| `sprites/riot.png` | character | play | 1632x136 | 2 | 816x68 | 20 | 0% | steel | 5 | 15% | 1.41 |
| `sprites/scav.png` | character | play | 1920x112 | 2 | 960x56 | 27 | 0% | olive | 4 | 21% | 1.87 |
| `sprites/stitch.png` | character | play | 672x120 | 2 | 336x60 | 23 | 0% | rust | 3 | 31% | 2.67 |
| `fx/burst_die.png` | effect | play | 1024x128 | 2 | 512x64 | 10 | 0% | steel | 4 | 0% | - |
| `fx/dust_land.png` | effect | play | 576x40 | 2 | 288x20 | 4 | 0% | steel | 4 | 0% | - |
| `fx/spark.png` | effect | play | 12x4 | 2 | 6x2 | 2 | 0% | amber | 1 | 0% | - |
| `fx/spark_hit.png` | effect | play | 384x64 | 2 | 192x32 | 6 | 0% | amber | 1 | 0% | - |
| `props/unit_14c_crt.png` | emissive | play | 24x60 | 2 | 12x30 | 17 | 0% | rust | 2 | 20% | 1.3 |
| `tiles/sky_gradient.png` | gradient | free | 3x540 | 3 | 1x180 | 77 | 93% | bg | 3 | 0% | - |
| `fx/dot.png` | mask | free | 8x8 | 1 | 8x8 | 1 | 100% | white | 1 | 0% | - |
| `fx/drop.png` | mask | free | 2x10 | 1 | 2x10 | 2 | 0% | steel | 2 | 0% | - |
| `fx/light_hard.png` | mask | free | 64x64 | 1 | 64x64 | 1 | 100% | white | 1 | 0% | - |
| `fx/light_soft.png` | mask | free | 128x128 | 1 | 128x128 | 1 | 100% | white | 1 | 0% | - |
| `fx/puff.png` | mask | free | 16x16 | 1 | 16x16 | 1 | 100% | white | 1 | 0% | - |
| `tiles/outside_unit_14c.png` | outside | outside | 512x512 | 4 | 128x128 | 7 | 0% | steel | 3 | 0% | - |
| `props/unit_14c_bedroll.png` | prop | play | 120x24 | 2 | 60x12 | 16 | 0% | olive | 4 | 17% | 2.44 |
| `props/unit_14c_box.png` | prop | play | 50x32 | 2 | 25x16 | 9 | 0% | rust | 3 | 9% | 4.72 |
| `props/unit_14c_crate.png` | prop | play | 40x40 | 2 | 20x20 | 10 | 0% | rust | 3 | 10% | 2.67 |
| `props/unit_14c_papers_a.png` | prop | play | 24x20 | 2 | 12x10 | 7 | 0% | concrete | 2 | 4% | 4.62 |
| `props/unit_14c_papers_b.png` | prop | play | 64x14 | 2 | 32x7 | 6 | 0% | white | 1 | 8% | 10.24 |
| `ui/cursor.png` | screen | screen | 24x24 | 3 | 8x8 | 2 | 0% | outline | 1 | 100% | - |
| `ui/hud_frame.png` | screen | screen | 24x24 | 3 | 8x8 | 3 | 0% | bg | 1 | 0% | - |
| `ui/lock.png` | screen | screen | 24x24 | 3 | 8x8 | 2 | 0% | outline | 1 | 69% | - |
| `ui/panel_frame.png` | screen | screen | 24x24 | 3 | 8x8 | 3 | 0% | bg | 1 | 0% | - |
| `ui/pip_off.png` | screen | screen | 18x18 | 3 | 6x6 | 2 | 0% | outline | 1 | 0% | - |
| `ui/pip_on.png` | screen | screen | 18x18 | 3 | 6x6 | 3 | 0% | outline | 1 | 0% | - |
| `ui/slot.png` | screen | screen | 72x72 | 3 | 24x24 | 3 | 0% | bg | 1 | 0% | - |

## The judgement

- **Density.** The set is two pixel sizes, not one. Fifty-five assets are off
  their plane's density: forty-seven of them on the play plane at 3 where the
  plane is 2, so every crate, pipe, hazard strip and wall tile has a pixel half
  again the size of the pixel of the woman standing on it. The two skylines are
  the same fault the other way, at 3 where the outside plane is 4. None of
  this is a new opinion: `docs/art/direction.md` rule 1 has said "planes are
  authored at 2 or 4 room px per art px, never 3" since the scale rework, and
  nothing had checked it since. And it is the one finding visible in the game
  without measuring anything: put the crop of Dani on a catwalk next to the
  hazard stripe under her feet and the two pixel grids do not line up.
- **Palette.** Clean, and that is the bake doing its job: one asset in
  ninety-four is off it. `tiles/wall_residential.png` is 56% off the palette,
  worst 3.9 dE, because it came from a diffusion still and never went through
  `snap_to_palette`. The other five assets that hold colours the palette does
  not are four alpha masks and the sky gradient, which is correct and is now
  written down in the contract rather than rediscovered every review.
- **Shading.** Twenty-one materials are flatter than the bar's three steps, and
  ten of them are one step over more than 150 art px -- a door frame at 880,
  a piano's body at 707. Twenty-two assets carry a near-black line round the
  silhouette where the bar asks for the darker step of the local colour, and on
  nineteen of those the line is 100% of the edge, which is a drawn outline and
  not a dark material meeting air.
- **Scale.** One finding in ninety-four: the drone's sheet draws 24 art px,
  0.73 m, against a cast brief of 30. Everything else measures back to the
  figure. The roster on the board stands on one ground line and reads right:
  88 art px for the Landlord against the player's 64 and the drone's 24, each
  across its tallest frame.
- **Readability.** Fourteen assets are under 1.10:1 flat against the plane
  behind them, four of them characters -- the drone and the Landlord at 1.00:1,
  the player and the elite scav at 1.08:1. That is what the level-artist's
  lights have to work with, not a failure on its own; the characters carry an
  outline for exactly this reason. The ten props are the ones to watch, because
  a pipe at 1.00:1 against the wall it is bolted to is a pipe nobody sees.
- **Consistency.** The board answers this before the table does. The props
  split into two blocks on sight: a coarse, black-outlined, flat generation and
  a finer, self-edged, shaded one. The line between them is the density, and it
  holds -- of the 53 environment and effect assets at 3, ten carry both an
  outline and a flat material; of the 16 at 2, none does. These are not
  fifty-five findings and twenty-two and twenty-one. They are one generation of
  art and one method.

## The one change

**Re-author the play plane at 2 texture px per art px** -- environment-artist.

The density is upstream of the rest. The assets drawn at 3 are the ones drawn
as ASCII grids in `make_props.py` and `make_tiles.py`, and that method is also
what gives them their black outline and their one- or two-step materials; the
`unit_14c_*` set, authored the environment-artist's way at 2, has neither
problem and none of it carries both codes. Redrawing at the play plane's
density is not a resample -- a grid does not scale by 1.5 -- so it is a real
pass, and it is the pass in which the outline and the shading get fixed for
free because they are properties of how the asset is drawn, not of its size.

Take them in the order the eye meets them: `tiles/platform.png` and
`tiles/hazard_0..2` first, which the player stands on in every frame, then
`tiles/wall_*`, then the props by how often a room places them.

What stays broken after it, on purpose: the six back planes and the two
skylines (a second pass, and the back plane is cheaper because
`back_unit_14c.png` already shows the target); the six effect sheets at 3,
which are the vfx-artist's; `tiles/wall_residential.png`, which needs a snap
and not a redraw; the drone's six missing art pixels; and the ten props under
1.10:1, which are a lighting conversation with the level-artist and may be
right as they are.

