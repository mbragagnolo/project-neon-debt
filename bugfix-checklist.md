# Bugfix Verification: prompts named keys that were never bound

> Tracking: #4 · Fix: `6da7dd4`

Run `godot --path game` (or press play — `rpg_gym.tscn` is the main scene).
Headless tests already prove the strings; what a human has to confirm is that
pressing the advertised key does the thing.

## Original repro (now fixed)

- [ ] Walk onto a chest in the armoury (**A**, left end of the gym) → the prompt
      reads `<item name>` / `[F] take`, not `[E] take`
- [ ] Press **F** while standing in it → the item is granted and the chest
      disappears. This is the step that did nothing for the whole of M3.
- [ ] Press **Tab** → the LOADOUT screen opens and the game pauses
- [ ] Read the footer → `[W/S] choose   [D] items   [A] slots   [F] equip / take
      off   [TAB] close`. No `[E]`, no `[I]`.
- [ ] Read the armoury wall → `[F] TAKE     [TAB] LOADOUT`
- [ ] Read the legend in the top-left corner → `LOADOUT  TAB     TAKE  F`.
      This is the label the diagnosis missed; it writes its keys without
      brackets, which is why a grep for `[I]` walked past it.
- [ ] Stand on a chest and press **E** → still nothing, and that is now
      correct: E is `hack_next`, reserved for M4, and nothing advertises it.

## Adjacent behavior

Everything below shares the code path the fix touched — `Pickup._ready`,
`EquipScreen._redraw`, and the gym scene's labels.

- [ ] In the loadout: **D** moves to the item column, **W/S** move the cursor,
      **F** equips the highlighted item, **A** goes back to the slot column
- [ ] With the cursor in the **slot** column on a clothing slot, press **F** →
      the piece comes off
- [ ] Same on **MELEE** or **RANGED** → refused; the weapon stays equipped
- [ ] **Esc** closes the loadout too (one way in, two ways out)
- [ ] Equip the breaker maul, hit `ArmourHeavy` on the wall (**B**), and watch
      `LAST HIT` on the HUD → M3's exit test still reads correctly
- [ ] Take an item, close and reopen the loadout → it is still owned; the chest
      does not come back

## Fix boundary cases

- [ ] **Controller:** press **Back/Select** → the loadout opens. It previously
      had no reachable pad button at all.
- [ ] **Controller:** press the **Guide/Home** button → Windows' Game Bar, as
      before, and nothing in the game. `toggle_map` parks there now and is
      unread until M5.
- [ ] **Controller:** **B/Circle** takes a pickup and equips in the menu
- [ ] **The point of the fix:** in Project Settings → Input Map, temporarily
      rebind `interact` from F to some other key. Run the game → the chest
      prompt and the menu footer both name the new key, with no code edited.
      **Revert the rebind afterwards.**
- [ ] **The generator:** run `tools/make_rpg_gym.tscn` in the editor, then
      `git diff game/rooms/rpg_gym.tscn` → the labels regenerate as F and TAB,
      and nothing else in the gym has moved
