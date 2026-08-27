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
godot --headless --path . tools/make_gym.tscn
```

Run generators **as a scene**, not with `-s`. Godot does not load autoloads for
`--script`, so `Events` and `GameState` are undefined there, `room.gd` fails to
compile, and the room's exported properties silently do not get saved.
