# Bug: projectile crashes on the second of two overlapping hurtboxes

## Summary
A shot that overlaps two hurtboxes in the same physics frame throws
`Invalid access to property or key 'source' on a base object of type 'Nil'`.
The shot's first hit resolves normally and the shot expires, so combat still
works — but every such shot spits a script error, and the same stale-loop bug
will bite any hitbox that disarms itself mid-sweep (M6's lingering boss boxes
are the next candidate).

## Repro steps
1. Get two hurtboxes overlapping each other — two Scavs walking into the same
   spot is the in-game way; two `TestArena.dummy`s at the same position is the
   headless way.
2. Shoot them with the ranged weapon, so one `Projectile` overlaps both
   hurtboxes on the same physics frame.
3. Error appears in the output on the frame the shot lands.

Confirmed headlessly during diagnosis: a throwaway GUT test that placed two
dummies at one position and launched a stationary `Projectile` into them
reproduced the exact trace on the first run.

## Expected vs. actual
- Expected: the shot damages one of the two overlapping targets, expires, and
  says nothing.
- Actual: it damages the first target and expires, then errors:

```
SCRIPT ERROR: Invalid access to property or key 'source' on a base object of type 'Nil'.
   at: Projectile._try_hit (res://src/combat/hitbox.gd:77)
   GDScript backtrace (most recent call first):
       [0] _try_hit (res://src/combat/hitbox.gd:77)
       [1] _try_hit (res://src/combat/projectiles/projectile.gd:64)
       [2] _physics_process (res://src/combat/hitbox.gd:68)
       [3] _physics_process (res://src/combat/projectiles/projectile.gd:46)
```

## Root cause
Confirmed, not a theory.

`Hitbox._physics_process` (`game/src/combat/hitbox.gd:61-68`) checks
`attack == null` **once, before** the loop, then iterates the whole snapshot of
overlapping areas calling `_try_hit` on each one. That guard is correct for a
box that stays armed for the whole sweep, and wrong for one that can disarm
itself partway through it.

A `Projectile` is exactly that box. `Projectile._try_hit`
(`game/src/combat/projectiles/projectile.gd:63-68`) ends the shot on its first
resolved contact — `_expire()` → `deactivate()` → **`attack = null`**. The loop
does not re-check, carries on to the second hurtbox, and dereferences
`attack.source` at `hitbox.gd:77`.

Nothing Scav-specific about it: any two hurtboxes in one shot's overlap list on
one frame does it.

## Affected files
- `game/src/combat/hitbox.gd` — `_physics_process` loops over a stale snapshot
  with a pre-loop-only `attack == null` guard. **This is the bug.**
- `game/src/combat/projectiles/projectile.gd` — `_try_hit` deactivates
  mid-sweep. Correct as written ("no pierce in V1"); it is the trigger, not the
  fault.

## Regression info
Not a regression. Both files were introduced together in `1b69bed` ("M2: the
damage pipeline, the first two verbs, and a lab to feel them in") and the bug
has been latent since — it needed two overlapping hurtboxes to surface, which
only became easy once Scavs could crowd.

## Proposed fix approach
Re-check `_active` / `attack != null` **inside** the loop in
`Hitbox._physics_process` and bail out when the box disarmed itself, so the
sweep stops the moment the attack ends.

Explicitly **not** the fix: a null-check at `hitbox.gd:77`, or a guard inside
`Projectile._try_hit`. Both silence this trace while leaving the stale-loop
assumption live for every other `Hitbox` subclass. The "first resolved contact
ends the shot, no pierce" behaviour must survive unchanged.

Regression test: two hurtboxes overlapping one projectile in a single physics
frame — assert no error, exactly one of them damaged, and the shot expired.
