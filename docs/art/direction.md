# Art direction — built (M7)

> **Superseded as a target, 2026-09-06.** The M7 pass below is what ships in
> the slice today. The next art pass moves to **hi-bit pixel art** (2×, 64–96
> art px characters, lights composited over pixels) after the REPLACED / The
> Last Night references in [`refs/README.md`](refs/README.md). Everything below
> stays accurate for the current build until that pass lands.

**Status: built.** Everything the slice draws comes from
`game/tools/art/*.py` and lands in `game/assets/`; the engine side is in
`src/art/`, `src/player/pixel_camera.gd`, `src/fx/juice.gd` and the room
generator (`tools/make_stacks.gd`). Re-run a script, re-import, and the
change is everywhere that sprite is used.

## The look, in one paragraph

Pixel art authored at **one art pixel = 3 screen pixels**, so the 60 px
greybox tile is a 20 px tile and the player is 22×32 art pixels. A dark
blue-black palette with a short list of neon accents (cyan, magenta, amber,
green, violet, sodium orange) that mean things: cyan is the player and
VESTA's infrastructure, magenta is money and the Landlord, amber is a
threat's eye and a warning lamp, green is a working machine. Real 2D lights
sit over the pixel layer — a lamp is a sprite *and* a `PointLight2D` — and
particles (rain, steam, dust) are rendered at the same scale so they read
as part of the picture, not on top of it.

The camera snaps to 3 px so the art never lands between pixels; the window
filter is nearest. Screen shake is a setting.

## Palette

`tools/art/pixel.py` owns it (`PALETTE`). Ground colours run void → bg0..3
→ steel0..4 / concrete0..3 / rust0..2; accents are `cyan`, `magenta`,
`amber`, `green`, `violet`, `red`, `sodium`, each with a `_d` (dark)
sibling. Every sheet is drawn with these names, never literal colours, so a
palette change is one edit.

## What each script makes

| Script | Output | Notes |
|---|---|---|
| `make_player.py` | `sprites/player.png` | idle, run, jump, fall, wall, dash, swing, hurt clips; `PixelAnim` reads the clip table |
| `make_cast.py` | `sprites/{scav,elite_scav,drone,riot,riot_shield,landlord,stitch,marisol}.png` | one sheet per actor, clips named after the enemy states (`windup`, `lunge`, `recover`, `stagger`, `stunned`, `dead`, …) |
| `make_tiles.py` | `tiles/wall_<style>.png` (3×3 nine-patch), `tiles/back_<style>.png`, `tiles/platform.png`, `tiles/hazard_*.png`, skylines | one wall and backdrop per room style: residential, mezz, shaft, gut, roof, collections |
| `make_props.py` | `props/*.png` | 32 dressing props: crates, vents, cables, posters, monitors, pipes, lamps, doors |
| `make_fx.py` | `fx/*.png`, `ui/*.png` | projectiles, light masks, spark/dot/puff/drop particles, HUD frames and pips |

Each script writes a `preview_*.png` next to itself for eyeballing.

## In the engine

- `PixelAnim` (`src/art/pixel_anim.gd`): a `Sprite2D` with a clip table
  `{name: [first, count, fps, loop]}`; `play(clip)` is what the player and
  enemy states call. Unknown clips fall back to `idle`, so a sheet can be
  short.
- `SwingTell` (`src/art/swing_tell.gd`): the melee arc, drawn to the size
  of the hitbox it sits in, so the picture is never bigger than the truth.
- `PixelCamera` (`src/player/pixel_camera.gd`): follows the player, snaps
  to 3 px, owns shake and the ending's pan.
- Rooms: `tools/make_stacks.gd` dresses each room from its `style`
  keyword — nine-patch walls, a tiled backdrop, a `CanvasModulate` ambient
  per style, lamps with lights, decor placed deterministically from the room
  id, rain on the roof, steam in the Gut, dust in the shafts.
- Juice (`src/fx/juice.gd`, in `world.tscn`): sparks and a number where
  damage lands, dust under a landing, ghosts behind a dash, a burst where
  an enemy was, camera shake. All of it hangs off the signal bus.
- HUD (`src/ui/hud/hud.gd`), theme (`assets/theme/neon.tres`: VT323 body,
  Orbitron display), title (`src/ui/title/title_screen.gd`).

## Rules

1. Draw at 1×, place at 3×. Nothing is scaled by a non-integer.
2. A colour is a palette name.
3. Lights and particles serve readability first: a hazard glows, a save
   point glows, an enemy's windup tint is still the loudest thing on screen.
4. Every sprite is regenerable from the repo. No hand-edited PNGs.
