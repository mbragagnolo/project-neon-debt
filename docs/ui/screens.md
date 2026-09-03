# Screens

**Status: the inventory-equip screen is LOCKED for M3.** The map screen and
quest log are M5, settings is M7; all three slot into the same pause shell
this file specifies, and each gets its section when its milestone opens.

## What the equip screen is for — LOCKED

M3's exit test is *"equipping better gear visibly changes combat math; HUD
shows it."* The screen is the instrument that makes that claim checkable. It
is not a container UI — the slice has ten items and no bag pressure — so
every design call below resolves toward **showing the consequence of a
choice** rather than toward managing inventory.

The corollary, stated up front because it constrains everything: **the
numbers on this screen must be the numbers the pipeline uses.** Displaying a
weapon's authored `power` where the fight uses `power × stat_multiplier`
would make the screen agree with the item file and disagree with the game,
and the exit test could pass on a lie.

## Rules — LOCKED

1. **It pauses.** `get_tree().paused = true`; the screen itself runs
   `PROCESS_MODE_ALWAYS`. Nothing is fought behind an open menu, and no
   comparison is made against a health bar that is still moving.
2. **`toggle_inventory` opens and closes it; `pause` also closes it.** Both
   actions are already mapped. One way in, two ways out — a menu you can only
   leave through the button that opened it is the classic controller trap.
3. **Slot-first navigation.** The left column is the six slots (melee,
   ranged, head, body, legs, hands, in that order); the right column lists
   only what fits the selected slot. With ten items a flat list would also
   work, and is rejected anyway: slot-first answers "what can go here"
   without reading item types, and it is the shape that survives V2's larger
   pool without a redesign.
4. **Every number shown is an *effective* number** — post stat multiplier,
   equipment folded in. Same source as the pipeline (the effective-stats
   layer), never the raw resource field. This is rule 0 above, restated where
   an implementer will hit it.
5. **The screen never edits the stat sheet.** V1 auto-allocates on level-up
   (stats-and-curves.md); there is no spend button, no respec, no confirm
   dialog. V2's manual allocation lands *here*, which is why the sheet gets
   its own panel now rather than being crammed into the HUD.
6. **Weapon slots are never empty; clothing slots always can be.** The player
   owns a starter melee and a starter ranged from minute zero and can only
   ever swap them, so an empty weapon slot is a state with no legitimate way
   in and one obvious way to soft-brick a fight. Clothing unequips freely —
   there is nothing to protect and a DEF-0 run is a legitimate thing to try.
7. **Controller and keyboard from day one** (DESIGN.md §3.7). No affordance
   that requires a mouse; the pad is not a port.
8. **Greybox.** Boxes, labels, one accent colour. M7's polish pass restyles
   this screen; it must not have to restructure it.

## Layout — LOCKED (arrangement, not styling)

```
┌──────────────────────────────────────────────────────────────────────┐
│  LOADOUT                                             [I] / [Esc] ✕   │
├─────────────────────────┬────────────────────────────────────────────┤
│  MELEE    Pipe wrench   │  FITS THIS SLOT                            │
│  RANGED   Zipgun        │   ▸ Pipe wrench            (equipped)      │
│  HEAD     —             │     Powered utility blade                  │
│  BODY     Padded jacket │     Hydraulic breaker maul                 │
│  LEGS     Work boots    │                                            │
│  HANDS    —             │                                            │
├─────────────────────────┼────────────────────────────────────────────┤
│  LVL 3      XP 190/285  │  HYDRAULIC BREAKER MAUL                    │
│  HP    52 / 52          │  Servo-assisted demolition tool for rebar   │
│  RAM   16 / 16          │  and concrete.                             │
│  STR 11   DEX 11        │                                            │
│  INT 11   DEF 3         │  DMG/HIT      13  →  30      ▲ +17         │
│                         │  DPS        20.8  →  24.0    ▲ +3.2        │
│  CREDITS  245           │  ATK SPEED   1.6  →   0.8    ▼ −0.8        │
└─────────────────────────┴────────────────────────────────────────────┘
```

Three panels, fixed: **slots** (top-left), **the sheet** (bottom-left),
**the item under the cursor** (right). The sheet stays on screen while
browsing on purpose — a delta is unreadable without the total it applies to.

## The delta readout — LOCKED

Highlighting an item shows what equipping it would do, against what is
equipped now, on **only the axes that item touches**. Unchanged axes are not
listed: a wall of `→ 0` teaches nothing and buries the one line that moved.

| Axis | Shown for | Source |
|---|---|---|
| DMG/hit | weapons | `power × stat_multiplier(STR or DEX)`, the pipeline's step 4 |
| DPS | weapons | DMG/hit × `attack_speed` — the second half of the flat-DEF balance lever, and invisible without it |
| ATK speed | weapons | `attack_speed` |
| Energy/shot | ranged | `energy_per_shot` |
| DEF | clothing | summed across equipped clothing |
| Max HP | jacket | `max_hp_bonus` |
| Dash cooldown | boots | effective cooldown, *after* `dash_cooldown_mult` |
| Energy/melee hit | hardhat | `ammo_on_hit` + `melee_energy_bonus` |
| RAM regen | gloves | `ram_regen_mult` — displays in M3, does nothing until M4 |

DMG/hit and DPS are both shown, always, because the trio is built on the
speed axis: the maul is +17 per hit and only +3.2 DPS, and a screen showing
just one of those numbers argues for the wrong weapon. Damage *through* DEF
is deliberately not shown — it needs a target to be true, and the gym's
DEF-5 station is where that comparison belongs.

## HUD additions this milestone

The real HUD is M7's. M3 grows the gym readout (`src/ui/debug_combat_hud.gd`)
by exactly what the exit test needs to be observable without opening a menu,
each line hanging off a signal that already exists on the bus:

| Line | Signal |
|---|---|
| `LVL n` | `Events.level_gained` |
| `XP n / n` | `Events.xp_gained` |
| `CR n` | `Events.credits_changed` |
| DEF, folded into the existing HP line | `Events.stats_changed` |

`LAST HIT` is already there from M2 and is the line the exit test actually
reads: swap the wrench for the maul, hit the same dummy, watch the number
change. No new signal is invented for M3 — every one above was declared on
the bus in M0.

## Exports

- **M5:** the map screen and quest log become tabs in this pause shell —
  rule 1 (pauses) and rule 7 (pad-first) are shell properties, not screen
  properties, and should be implemented as such.
- **M7:** restyle only. If the polish pass needs to move a panel, this spec
  was wrong and should be amended, not silently diverged from.
- **V2:** manual stat allocation and respec land in the sheet panel; rule 5
  is where they attach.
