# Bugfix Verification: projectile crash on two overlapping hurtboxes

Fix commit: `ca8986c` — the `_active`/`attack` guard moved inside the sweep
loop in `game/src/combat/hitbox.gd`. Watch the Godot output panel throughout:
**any red `SCRIPT ERROR` line fails the run**, whatever the game looks like.

## Original repro (now fixed)
- [ ] Get two Scavs standing on the same spot (bait them both toward you and
      let them stack), then shoot into the pile → one takes damage, the shot
      disappears, **no `Invalid access to property or key 'source'` in the
      output**.
- [ ] Do it a few more times from both sides → still silent, and it is never
      the case that both Scavs take damage from one shot.

## Adjacent behavior
The guard is in the shared `Hitbox` sweep, so every box in the game runs
through it — not just projectiles.
- [ ] Shoot a single lone Scav → damage lands, shot vanishes on contact, as
      before.
- [ ] Shoot at a wall with nothing in the way → the shot stops at the wall
      and does not fly through.
- [ ] Fire into empty air → the shot expires at the end of its range with no
      error.
- [ ] Wrench a single Scav → one hit per swing, ammo refills on the hit.
- [ ] Let a Scav touch you and stay in contact → contact damage keeps ticking
      through the i-frame rhythm rather than stopping after the first tick.
      (Contact boxes clear their target set every frame; this is the one path
      that most depends on the sweep continuing to run.)
- [ ] Let a Scav land its lunge on you → the attack connects normally.

## Fix boundary cases
- [ ] **The one that must NOT have regressed:** wrench a swing into two
      overlapping Scavs → **both** take damage from the single swing. A melee
      box stays armed for the whole sweep, so the new guard must not stop it
      early. If only one of them is hit, the fix over-reached.
- [ ] Shoot two Scavs that are close but *not* overlapping → the shot hits
      only the first one and expires there.
- [ ] Kill a Scav with a shot while a second Scav overlaps the corpse mid
      death animation → no error as the hurtbox goes away underneath the
      sweep.
