# The interface pass — 2026-09-16

The first ui-artist pass over the slice. What the interface was, what it is
now, and the three things left for a person to decide.

Re-run the numbers with:

```
python <kiln>/skills/ui-artist/scripts/lint.py --project .
python <kiln>/skills/ui-artist/scripts/mock.py --project . --all
```

## What changed

**70 colours typed across 13 files became 30 roles and one generated file.**
`game/src/ui/ui_palette.gd` is written from `ui/ui.json`; the 12 interface
scripts now read `UiPalette.DIM` and so on, with every call site untouched —
the diff is one line per constant. 13 of the 30 roles take a palette entry
from `game/tools/art/pixel.py`; 17 hold their own colour with the reason in
the table.

**theme.json is generated from the same roles.** Twelve colours in it now
come from `theme_roles`, so the theme and the code cannot hold two versions
of one colour. `assets/theme/neon.tres` was re-landed by the integrator.

**The interface sprites moved out of the effects script.** The seven grids
(`hud_frame`, `panel_frame`, `slot`, `pip_on`, `pip_off`, `cursor`, `lock`)
were living in `game/tools/art/make_fx.py` beside the hit sparks. They are
now `ui/sprites.py`, and `sprites.py --check` confirms all seven redraw
**byte-identical** to the files already in `assets/ui/` — the move changed no
art.

**473/473 tests green, zero parse errors**, before and after.

## What the pass found

Three defects, all invisible while any single screen read fine on its own:

1. **`COL_TEXT` was two colours.** `(199,219,242)` in the six menus,
   `(217,230,247)` in the four in-world overlays — 3.4 dE apart, and
   `theme.json`'s `Label/font_color` sided with the overlays while
   `Button/font_color` sided with the menus. Now one `TEXT`.
2. **`COL_WARN` was two colours**, and one of them was not a warning: the
   title screen's was `(255,115,115)`, the same red as `COL_BAD`, while the
   settings panel's was `(255,140,89)`, an orange. Now `BAD` and `WARN`.
3. **`COL_PANEL` was three colours** — the ending screen's matched the
   theme, the dialogue box's was 2.1 dE lighter, and three menus typed a
   third inline. Now one `PANEL`.

Also: five names for one accent (`COL_ACCENT`, `COL_ACTIVE`, `COL_NAME`,
`COL_CURRENT`, `COL_SPEAKER`), and seven colours on the title screen that
were never named at all — an outline, two skyline tints, rain, a ground and
a scrim. Those are scene art, not mistakes, and they are roles now.

## Left open, for the art-director

**1. Ten roles hold their own colour rather than a palette entry.** None can
move without changing how the game looks. The distances:

| role | dE from the nearest palette entry | |
|---|---|---|
| HACK | 30.2 | violet |
| WARN | 18.6 | sodium |
| BAD | 17.2 | red_l |
| GOOD | 14.2 | green |
| SAVE | 12.9 | cyan |
| ROOM_EDGE | 11.3 | steel3 |
| HP | 6.3 | red |
| DIM | 6.2 | chrome_d |
| TEXT | 6.2 | chrome |
| ACCENT | 4.2 | cyan_l |

They cannot simply be added to the palette: `rig.py`'s `snap_to_palette`
defaults to the whole of `PALETTE` and votes every baked sprite onto it, so
an interface colour added there would silently re-snap the art. The choice is
per role — snap it to the palette and accept the shift, or keep it and accept
that the interface has ten colours the sprites do not. `HP` at 6.3 dE is the
one worth arguing about first: it is the most looked-at thing on the screen.

**2. `panel_frame` is named by no script or scene.** Drawn in M7, never
wired. Both this skill's lint and the integrator's theme check report it
independently. Either place it or delete it.

**3. `SELECTED` and `HP_LOW` are both magenta, and the title's neon glow
now reads as `UiPalette.SELECTED`.** Three meanings on one colour is fine;
the name being wrong on the title screen is a small wart worth a `NEON` role
if anyone touches that screen again.

## The numbers

Every text role clears its floor over both rooms. Measured composited onto
the real shots — the roof (96% dark, the darkest room a player stands in) for
the HUD, dialogue and bark; `shot_b` (52% dark, 15% bright) for the menus —
in 4x4 tiles, worst tile reported:

- worst overall: `DIM` at 5.1:1 against a 4.5:1 floor
- `TEXT` 13.7:1 and `CREDITS` 11.0:1 against their 7:1 critical floor
- 0 roles under the floor on any of the ten screens

The mocks are in `ui/mocks/`. Bars (`HP`, `HP_LOW`, `RAM`, `XP`) are
`kind: bar` and are not held to a text floor — at 5.5:1 to 6.4:1 over the
panel they read at a glance, and holding a thumb-sized block to a
paragraph's contrast standard was the checker being wrong, not the HUD.
