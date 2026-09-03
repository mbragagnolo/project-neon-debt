# tools/

Editor-side generators. Not shipped with the game and not on any runtime path.

## Why generate rooms instead of hand-editing scenes?

The greybox rooms are *arithmetic* — a 240px gap is a gap a running jump clears,
a 360px gap is one it doesn't, and a 150px step is a step a 168px jump makes
comfortably. That reasoning lives in the generator as code and comments; the
`.tscn` it emits is canonical Godot output. Tuning a gap during M1 is then a
one-line diff plus a rerun, not a hand-edit of 400 lines of scene text, and M5
gets a pattern to lay out 25–35 rooms with.

Rooms are still perfectly editable in the Godot editor. If you move a platform
by hand, either fold the change back into the generator or stop running it for
that room — whichever, don't leave the two disagreeing.

## Running

```bash
cd game
godot --headless --path . tools/make_gym.tscn         # M1 movement gym
godot --headless --path . tools/make_combat_gym.tscn  # M2 hit-feel lab
godot --headless --path . tools/make_rpg_gym.tscn     # M3 gear-and-levels lab
```

Run generators **as a scene**, not with `-s`. Godot does not load autoloads for
`--script`, so `Events` and `GameState` are undefined there, `room.gd` fails to
compile, and the room's exported properties silently do not get saved.

## Configuring an instanced sub-scene from a generator

Set the properties on the **instance root**, never on a node reached inside it.
`PackedScene.pack()` records overrides on an instance root reliably and is
fragile about overrides reached into an instance's interior — so the training
dummy mirrors its stat block (`max_hp`, `defense`, `stagger_threshold`) from
its own exports onto its `Health` child at ready, rather than letting the
generator reach in and set `Health` directly.

A dummy whose DEF silently reverted to 0 would look exactly like a damage
pipeline bug, which is why `tests/test_combat_gym.gd` asserts each station kept
the stat block the generator gave it.
