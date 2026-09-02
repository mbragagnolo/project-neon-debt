# Damage pipeline

**Status: locked** (order, rules, interlock shape). Numbers `TUNE` — they get
their first real tuning pass during M2 itself, against a fight rather than a
spreadsheet. Elaborates DESIGN.md §3.2 against the locked stat math
(stats-and-curves.md), the locked roster (characters/enemies.md) and the
locked weapon fields (rpg/items.md).

Two things every rule here answers to:

- **One pipeline, no exceptions.** Player, enemy, contact, melee, ranged and
  (in M4) hacks all run the same ordered steps. A verb that needs its own
  damage path is a verb that will drift out of balance silently.
- **Interlocks are tuning data, not logic** (combat/README.md, a V2
  requirement). The melee→ammo refill lives in a field on a weapon resource,
  never in an `if attacker is Player` branch. V2 turns these interlocks off;
  that must be a number change, not a refactor.

## The ordered pipeline — LOCKED

Every hit resolves in exactly this order. The order is the spec: it is what
makes "does DEF apply before or after the floor" answerable without reading
code.

| # | Step | Notes |
|---|---|---|
| 1 | Hitbox overlaps Hurtbox | Shared `Hitbox`/`Hurtbox` pair, all entities |
| 2 | Reject if this attack already hit this target | Per-swing target set, see *Multi-hit* |
| 3 | Reject if target is dead or in i-frames | |
| 4 | `raw = weapon_power × stat_multiplier(stat)` | Enemies skip this — flat `attack_power` |
| 5 | Reject on positional immunity tags | `immune_ranged_frontal` is checked **here**, before DEF |
| 6 | `damage = max(1, raw − DEF)` | Floor at 1, universal, zero exceptions |
| 7 | Apply damage, emit the hit signal | The signal is what HUD, SFX and juice hang off |
| 8 | `damage ≥ stagger_threshold` → stagger; else flinch | One field, one comparison |
| 9 | Hitstop, then knockback impulse | Skipped by contact damage, see below |
| 10 | Run the attacker's on-hit interlocks | Melee→ammo lives here, as weapon data |
| 11 | `hp ≤ 0` → death | |

**Immunity before DEF (step 5 before 6) is deliberate.** A shielded frontal
hit is *rejected*, not reduced to the floor of 1 — otherwise the Riot unit's
shield would still leak chip damage and the tag would read as a lie. The
floor at 1 is a promise about damage that lands, not a promise that every
button press lands.

## Hitstop — LOCKED

The freeze on connection. DESIGN.md §3.2 budgets ~2–3 frames; tiering it by
weight is what keeps the maul from feeling like the blade.

| Tier | Trigger | Frames @60Hz |
|---|---|---|
| Light | `damage` under `hitstop_heavy_threshold` (`TUNE` 12) | 2 `TUNE` |
| Heavy | `damage` at or above the threshold | 4 `TUNE` |
| None | Contact damage, and any hit dealing floor-1 damage | 0 |

1. **Global, not per-entity.** The whole combat picture holds for the beat.
   Per-entity freezing reads as lag or a dropped frame; a global hold reads
   as impact, which is the entire point. It is also the cheap version, and
   M2 has one person tuning it.
2. **Hitstop never stacks — overlapping hits take the maximum remaining,
   never the sum.** Without this rule the three-Scav exit test degrades into
   a slideshow exactly when the fight gets interesting, and it would look
   like a performance bug rather than a tuning mistake.
3. **Nothing gameplay-relevant ticks during hitstop** — not i-frames, not
   the jump buffer, not attack cooldowns. Hitstop that eats reaction windows
   is a stealth difficulty spike; the frozen frames must be free.
4. **Floor-1 hits get no hitstop.** When DEF has ground a hit down to the
   minimum, the freeze would be reporting an impact the health bar disagrees
   with. Silence is the honest feedback, and it teaches "wrong tool" faster
   than a number ever will.

## Knockback — LOCKED

1. **A velocity impulse, never a forced displacement.** It is handed to the
   same velocity the M1 controller already integrates, so friction, gravity
   and every movement state compose with it for free and nothing fights the
   character body for control.
2. **Horizontal, away from the attacker** — the sign of the x-delta between
   the two bodies. Not radial. Radial knockback launches bodies upward, and
   upward is where this game's platforming lives; a hit that pops you into a
   pit is the single least popular thing a 2D combat system can do.
3. **A flat per-weapon field, not derived from damage.** Deriving it couples
   two tuning axes and makes every fast weapon feel weightless — the utility
   blade needs to *stick* even at 5 damage, or its DPS never gets spent.
4. **Staggered targets take full knockback; flinching targets take a
   fraction** (`flinch_knockback_mult`, `TUNE` 0.25). This is what makes the
   stagger threshold visible without a UI: the Riot unit shrugging off a
   wrench *looks* like shrugging it off.
5. **Player knockback on hurt is its own, much smaller constant**
   (`player_hurt_knockback`, `TUNE`). Enemy-side knockback is juice; player-
   side knockback is loss of control, and the two want opposite budgets.

## I-frames — LOCKED

Load-bearing, not polish: contact damage (enemies.md) is only fair because
these exist.

1. **The player gets timed i-frames on hurt** (`player_iframe_time`, `TUNE`
   0.7s), starting when damage is applied at step 7. They block *all*
   incoming damage — contact, melee, ranged, alike. A source-filtered
   invulnerability is unreadable mid-fight.
2. **Enemies never get timed i-frames.** They get per-attack multi-hit
   rejection instead (step 2). A timer on the enemy side would silently cap
   the nailgun's fire rate and quietly delete the fast weapons' identity.
3. **Communicated or it does not exist.** A hurt player flashes for the
   duration. An invulnerability the player cannot see is indistinguishable
   from the hitbox missing.
4. **Dash i-frames stay off.** The flag exists (`dash_grants_iframes`,
   currently `false`) and the question is already recorded as an open
   playtest call in DESIGN.md §7. Turning it on makes dash the answer to
   everything and undercuts the Scav's whole lesson; that trade wants a real
   fight to judge, which is what M2 builds.

## Multi-hit — LOCKED

One swing hits a given target once. Enforced with a **per-attack-instance
target set** that clears when the attack ends — not a cooldown timer.

The distinction matters at both ends of the weapon trio. A timer long enough
to stop a wrench double-hitting is a timer that throttles the nailgun; a set
scoped to the swing is correct at 0.5/s and at 4/s with no per-weapon tuning
at all. Lingering hitboxes (M6's boss, any future sweep) get this behavior
for free.

## Attack speed — LOCKED

`attack_speed` (attacks/second, items.md) is authoritative. Cooldown is
`1 / attack_speed`, and **the animation is fitted to the cooldown, never the
reverse.**

This is the direct consequence of the flat-DEF heavy-hit bias
(stats-and-curves.md): DPS through armor is `(raw − DEF) × attacks_per_second`,
which is only a usable balance lever if speed is a number someone can type.
The moment attack rate becomes an emergent property of animation length, the
armor math stops being tunable by anyone but an animator.

Melee commitment stays inside DESIGN.md §3.2's ~0.2s anim-lock budget — long
enough for the Scav's bait-and-punish lesson to have stakes, short enough
that it never feels like input lag.

## The melee→ammo interlock — LOCKED

The mechanical spine of the intertwined kit (shoot → close → melee → back
out), and the interlock a 40-minute playtest can actually demonstrate.

- **`ammo_on_hit` is a field on the melee weapon resource**, not a pipeline
  constant. This is the V2 requirement from combat/README.md discharged: V2
  turns the interlock off by zeroing a field on three items.
- **Starting value `1` (`TUNE`)** — one wrench hit buys exactly one zipgun
  shot (items.md: zipgun 1 energy/shot). Legible without a tutorial, and
  mental math at this number scale.
- **It fires on damage dealt, at step 10 — never on the swing.** Refunding a
  whiff would remove the only pressure the loop has.
- **No overflow banking.** Refill clamps at max; hits above the cap are
  wasted. Meleeing at full ammo should feel like the wrong choice.
- Rate check against the roster: a Scav dies in 2–3 wrench hits, so one
  Scav funds 2–3 zipgun shots. Three Scavs (the exit test) fund most of a
  pool. If playtesters stop shooting because they are always full, this
  number is too high — the same failure mode the drop rate is warned about
  in stats-and-curves.md.

## Contact damage — LOCKED

Half `attack_power` (enemies.md), through the same eleven steps, with two
carve-outs:

- **No hitstop** (step 9). Contact is a continuous condition, not an event;
  freezing on it would stutter the entire time a player is pinned against a
  Scav.
- **Never staggers the player and never triggers the attacker's
  interlocks.** Brushing a body is not a hit anyone landed on purpose.

Contact respects i-frames like everything else, which is what turns it from
a damage-per-second trap into the spacing pressure it is meant to be.

## Ranged aiming — LOCKED

items.md sets the M2 feel constraint: *every ranged weapon must aim upward
comfortably*, because the Watcher drone is a vertical threat.

**Eight-way aim off the existing movement inputs.** Neutral fires along
facing; holding up fires straight up; up + forward fires the 45° diagonal;
down fires straight down while airborne and is ignored on the ground.

No new inputs (`move_up`/`move_down` are already mapped, and the aim never
fights the movement they also drive), no aiming UI, and it composes with the
locked auto-target casting model for hacks rather than competing with it.
Free/mouse aim is rejected for V1: it makes the pad a second-class citizen
and would quietly obsolete the drone's whole vertical-threat lesson.

## Death — LOCKED

- **Enemies:** step 11 → stagger-into-death, drops and XP resolve on the
  death event (not on the killing blow's step 7), then despawn after a short
  beat. Resolving rewards at step 7 would pay out a hit that a
  simultaneously-arriving second hit was also going to pay for.
- **Player:** respawn at the room's entry point for M2. Save-point respawn
  is M5's, once save points exist; the DESIGN.md §7 slice default (respawn,
  enemies respawn, keep everything) is the target behavior and nothing in
  M2 should assume otherwise.

## Exports

- **M2 ships every enemy at `def = 0`.** The locked tuning warning
  (stats-and-curves.md) sets enemy DEF *last*, after weapon numbers exist —
  and low-end DEF is swingy against light weapons. DEF becomes real in M3.
- **M3 needs:** `stat_multiplier` wired into step 4 from real stats, and the
  first DEF pass across the roster.
- **M4 needs:** hacks enter at step 4 with base power in the `weapon_power`
  role and INT as the stat, and **skip step 5** — the locked "hacks bypass
  positional immunities, never DEF" rule (hacks.md) is exactly the pipeline
  running with one step disabled. No new damage path.
- **M6 needs:** step 5's facing check, for the Riot unit's
  `immune_ranged_frontal`; and lingering-hitbox multi-hit, which the
  per-attack target set already covers.
- **Juice (M7)** hangs off step 7's hit signal — screen shake, SFX and
  damage numbers are subscribers, never pipeline steps.

## Open sections

1. All `TUNE` constants above — hitstop frames, the heavy threshold,
   knockback magnitudes, i-frame duration, `ammo_on_hit`. These are M2's
   own tuning pass; the exit test ("fighting 3 Scavs is legible and
   satisfying") is what closes them.
2. Whether floor-1 hits should also suppress knockback and hit SFX, not just
   hitstop. Deferred until there is an armored enemy to feel it against —
   the Riot unit is M6.
