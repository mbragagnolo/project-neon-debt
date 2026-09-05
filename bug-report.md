# Bug: M3 prompts advertise [E] and [I]; the bound keys are F and Tab

> Tracking: #4

## Summary

Every prompt M3 puts on screen tells the player to press **E** to take a pickup
and **I** to open the loadout. Neither key is bound to anything that acts. The
keys that actually work are **F** and **Tab**. Nothing under the prompts is
broken — the strings are lying about which key does the thing.

The same defect exists on a controller for a different reason: `toggle_inventory`
is bound to the GUIDE button (Xbox Home / PS button), which the OS intercepts, so
the loadout screen has no reachable pad button either.

## Repro steps

1. `godot --path game` — the main scene is `rooms/rpg_gym.tscn`.
2. Walk onto any pickup in the armoury (left end of the gym). The prompt reads
   `<item name>` / `[E] take`.
3. Press **E**.
4. Press **I**.
5. Press **F**, then **Tab**.

## Expected vs. actual

- **Expected:** step 3 grants the item and closes the chest; step 4 opens the
  LOADOUT screen.
- **Actual:** steps 3 and 4 do nothing at all — no error, no log line, no visible
  response. Step 5 does both: `F` takes the item, `Tab` opens the loadout.

Confirmed against the running engine rather than read off the config file — a
headless `InputMap.action_get_events()` probe on Godot 4.7.2 prints:

```
interact          -> key F,      Joypad Button 1 (B / Circle)
toggle_inventory  -> key Tab,    Joypad Button 5 (GUIDE — Xbox Home / PS button)
hack_next         -> key E,      Joypad Button 8 (R3)
pause             -> key Escape, Joypad Button 6 (Start)
toggle_map        -> key M,      Joypad Button 4 (Back / Select)
```

## Root cause

**Confirmed.** Four hardcoded prompt strings, all written during M3, name keys
that the M0 input map never bound to those actions.

`game/project.godot`'s `[input]` block has not changed since `f43f7f5` ("M0:
Godot project skeleton"), where `interact` was bound to **F** and
`toggle_inventory` to **Tab**. M3 then authored its player-facing text against a
different, unwritten assumption (E/I) and nothing cross-checked the two.

Pressing **E** does fire an action — `hack_next` — but no code reads it: hacks
are M4, and `grep` finds `hack_next` only in `project.godot` and
`tests/test_input_map.gd`. So E is an action that exists and does nothing, which
is why it fails silently rather than erroring. **I** is not bound to any action.

`tests/test_input_map.gd` asserts only that the action *names* exist; it never
asserts which key each is bound to, and no test asserts any prompt string. That
is why CI is green on a bug the player hits in the first ten seconds.

The controller half has a separate cause with the same effect: joypad button 5 is
`JOY_BUTTON_GUIDE`, which Windows claims for the Game Bar, so `toggle_inventory`
is unreachable on a pad regardless of the label.

## Affected files

- `game/src/world/pickup.gd:59` — `_prompt.text = "%s\n[E] take"`; the action
  polled on line 70 is `interact`, which is F.
- `game/src/ui/menus/equip_screen.gd:180` — hint reads
  `[E] equip / take off   [I] close`; the handlers on lines 68 and 88 use
  `toggle_inventory` (Tab) and `interact` (F).
- `game/rooms/rpg_gym.tscn:151` — label node text `"[E] TAKE     [I] LOADOUT"`.
- `game/tools/make_rpg_gym.gd:82` — the generator that emits that scene. Must be
  fixed too or the next regeneration reintroduces the bug.
- `docs/ui/screens.md:57` — the LOCKED layout block shows the loadout header as
  `[I] / [Esc]`. The doc is the reason M3 was written against E/I; leaving it
  uncorrected preserves the drift for M5 and M7 to inherit.
- `game/project.godot` — `toggle_inventory`'s joypad binding only (button 5 →
  GUIDE). **The keyboard bindings are not to be changed** — see scope below.

## Regression info

Not a regression. The bindings are original to M0 (`f43f7f5`); the mismatched
prompts arrived with M3 (`236be97` "Pickups, the equip screen, and a HUD that
shows the sheet" and `c42bf20` "The RPG gym"). This has never worked.

## Scope — what must NOT change

The tempting fix is to rebind `interact` to E and `toggle_inventory` to I so the
existing labels become true. **That was considered and rejected.** E is
`hack_next`, and it pairs with Q (`hack_prev`) for M4's hack cycling; taking E
for `interact` costs a natural adjacent pair to fix a text string. The keyboard
input map stays exactly as it is.

Do not "fix" this by adding an extra E binding alongside F — two keys for one
action to paper over a wrong label is the same drift with more surface.

## Proposed fix approach

**Derive the key name from the binding instead of hardcoding it.** A small helper
— given an action name, return the display string for its first
`InputEventKey` via `OS.get_keycode_string()` — used by all four prompt sites.
Then the prompt cannot disagree with the input map again, and a future rebind
updates every label for free.

Hardcoding `[F]` and `[TAB]` would fix today's symptom and leave the exact same
class of bug armed for the next rebind. Both are defensible; the derived version
is the one worth the extra twenty lines, because the failure mode here was
precisely two sources of truth for one fact.

The regression test then asserts the *invariant* — "the pickup prompt names the
key currently bound to `interact`" — rather than the literal `F`, so it keeps
protecting the invariant across rebinds. Nothing pins these strings today, so no
existing test needs updating.

Also in scope: correct `docs/ui/screens.md:57` to `[TAB] / [Esc] ✕`, and move
`toggle_inventory` off joypad GUIDE. One defensible pad arrangement: give
`toggle_inventory` button 4 (BACK/Select) and let `toggle_map` — which no code
reads until M5 — take a new home when M5 places it. Any reachable, unclaimed
button is fine; the requirement is only that the loadout opens on a pad.

## Verification

- Standing on a pickup, the prompt reads `[F] take`, and pressing F takes it.
- `Tab` opens the loadout; its hint line names F and TAB, not E and I.
- `[F] TAKE     [TAB] LOADOUT` on the gym wall, and re-running
  `tools/make_rpg_gym.tscn` regenerates that same text.
- On a controller, some pressable button opens the loadout.
- `docs/ui/screens.md` no longer says `[I]`.
- Must not break: `tests/test_input_map.gd` (all action names still present),
  `tests/test_pickup.gd`, `tests/test_equip_screen.gd`, `tests/test_rpg_gym.gd`.
- E must remain bound to `hack_next` for M4.
