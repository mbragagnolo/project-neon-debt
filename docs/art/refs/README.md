# Art references — hi-bit target (decided 2026-09-06)

The art pass after M7 targets **hi-bit pixel art**: sprites drawn at 2×
(one art pixel = 2 screen pixels at 1080p), characters 64–96 art px tall,
dozens of colours per sprite, and real `PointLight2D`s, particles and fog
composited over the pixel layer. The two games below are the target corner
of that style. Neither is a look to copy; each shot is here because it pins
one specific thing we need to match.

Screenshots are the studios' Steam store images, © Sad Cat Studios and
© Odd Tales. Internal reference only — never shipped, never in `game/`, and
**gitignored** (only this README is tracked). To restore them on another
machine, pull the shots from each game's Steam store page; the table below
describes each one well enough to find it.

## Scale anchor

`replaced_crop_player_2x.png` — the REPLACED player cropped at native screen
pixels and shown at 2× zoom. Dani today is 22×32 art px at 3× (96 screen px).
The target is a character that reads like this crop: about twice Dani's
art-pixel height, with cloth folds, a lit edge on the coat, and a face.

## REPLACED (Sad Cat Studios)

| File | Pins |
|---|---|
| `replaced_01_arena.jpg` | **Character-to-room scale** and **lamp bloom.** Four sodium floodlights over a dark set; the player is ~150 screen px in a ~1080 px room. This is the Landlord arena's lighting brief: a few hot sources, everything else falls to near-black. HUD is pixel, flat, single accent colour. |
| `replaced_02_ledge.jpg` | **How little light a room needs.** One character on a ledge, the wall behind lit only by spill; silhouette does all the reading. Reference for the shaft and gut rooms, and for the rule that a room is allowed to be mostly dark. |
| `replaced_03_crowd.jpg` | **Enemy silhouettes and a boss-scale machine.** A pack of same-height enemies staying distinguishable by shape; a machine two to three characters tall dominating the frame. Reference for Scav / Riot silhouettes and for the Landlord's presence. |
| `replaced_04_skyline.jpg` | **Roof room and skyline.** Warm sky gradient, a city as layered flat silhouettes, one large foreground prop for depth. Replaces the current `skyline_far` / `skyline_near` approach. |

## The Last Night (Odd Tales)

| File | Pins |
|---|---|
| `lastnight_01_street.jpg` | **Sign density and neon as scene colour.** Shopfront, awnings, stacked signs, crowd NPCs in the same pixel scale as the player. Reference for the hub and the residential style: cyan / magenta / amber signs are *the* light sources, not decoration. |
| `lastnight_02_balcony.jpg` | **Layered depth without a tilemap look.** Balcony, plants, a second building plane, distant towers. Reference for the mezz style and for how a backdrop tile can hide its repeat. |
| `lastnight_03_alley.jpg` | **A single cold source.** One cyan cone over wet ground, crates, grime, everything else warm-dark. Reference for the gut: steam, puddles, one light that says "here". |
| `lastnight_04_interior.jpg` | **Interior room.** Big window as the light source, screens as accent lights, rubble and clutter at pixel scale. Reference for collections and for the save / program terminals' surroundings. |

## What both share, and what we adopt

- Pixel sprites and pixel tiles, **but** lighting, fog, bloom and depth of
  field are real-time and not pixel-snapped. Our `PointLight2D`s and
  particles already work this way; the sprites underneath need to catch up.
- Palette discipline: one warm (sodium / amber) and one cold (cyan / blue)
  per scene, a third colour only as a signal. This matches the M7 palette
  rules in `../direction.md`; the palette stays, the pixel count goes up.
- Characters are dark-clothed with one lit edge and one accent, so they
  separate from a dark room by rim light rather than by outline colour.
- Nothing is outlined in black at 2×. Outlines are a darker shade of the
  local colour, or absent where light hits.
