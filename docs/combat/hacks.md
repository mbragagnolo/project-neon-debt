# Hacks

**Status: locked, implemented in M4.** Numbers `TUNE`. Elaborates DESIGN.md
§3.2 against the locked RAM model (stats-and-curves.md). The implementation
notes at the bottom record what M4 decided where this file left room.

The fiction rule every hack must pass: **the player is hacking a specific
system**. Overload hacks the enemy's, Breach hacks the door's or the
machine's, Firewall hacks your own — your body is corporate hardware you are
still paying off. (Static Wall from the original design failed exactly this
test — a force wall in empty air hacks nothing — and was cut for Firewall.)

The trio is one answer each: **Overload = damage, Firewall = defense,
Breach = control.**

## Rules — LOCKED

1. **RAM is the limiter; a 1-second global cooldown is the rate cap.** No
   per-hack cooldowns. The shared 1s cooldown stops panic-dumping the pool in
   one burst and gives the cast room to read; it must never grow into
   rotation-juggling. Pool sizing rule: a full early pool ≈ 3 casts.
2. **Breach doors are interactions, costing 0 RAM.** The door checks that you
   *own* the program, never the meter — a player arriving empty is never
   softlocked. Combat casts of Breach cost normally.
3. **Casting is auto-target, not aimed.** Overload strikes the nearest valid
   enemy in radius, Breach pulses around the player, Firewall targets self.
   No aiming UI on top of the quickslot (cycle Q/E, cast L — already mapped).
4. **Hacks bypass positional immunities, never DEF.** Not projectiles —
   `immune_ranged_frontal` means nothing to them — but "DEF always applies,
   floor 1" stays a universal rule with zero exceptions. The Riot unit:
   hard to shoot, expensive to tank, soft to hack.
5. **INT scales hack damage** through the locked stat multiplier; base power
   plays the weapon_power role. Nothing else about a hack scales.

## The three — LOCKED

| Hack | RAM | Effect | Notes |
|---|---|---|---|
| **Firewall** | 4 | Self-buff, ~2s: incoming damage halved (`TUNE`; implemented as +DEF or a multiplier — same pipeline, no new rules) | Cast into a telegraphed hit. Cheapest to build: a timed self-buff |
| **Overload** | 3 | 15 burst (INT-scaled) to nearest enemy in radius | 15 ≥ the Riot unit's stagger threshold 12 — Overload *interrupts* it; a free synergy from two locked systems |
| **Breach** | 2 | Pulse: stuns `mechanical` enemies in radius ~1.5s; opens hack-doors as a free interaction | Cheapest cast — a setup verb should never feel precious. Does nothing to humans: tags mean something |

## Acquisition — LOCKED

1. **Firewall — from the start.** The narrative rhyme writes itself: the
   defensive program is factory-installed, because the corp protects its
   collateral — your body. Every cast is using the leash.
2. **Overload — found in the world, mid-early.** The first *offensive*
   program: the moment the player starts repurposing corporate property as a
   weapon. (Hacks are programs, not items — outside the ten-item budget.)
3. **Breach — the set-piece gate beat**, before the district midpoint
   (constraint already exported to level-design). The maul waits behind its
   door (items.md placement).

## Exports

- The Firewall-first arc (corp-installed defense → stolen offense) is a
  narrative beat `narrative/hook.md` should own and voice.
- ~~M4 needs: quickslot UI, the 1s global cooldown, auto-target acquisition,
  the self-buff timer, and the `mechanical` stun hook~~ — **shipped**, see
  below.

## M4 implementation notes

Decisions M4 made inside the rules above, recorded so a retune knows what is
data and what is shape:

- **A hack is a `Hack` resource with one of three shapes** — `GUARD` (self,
  Firewall), `BURST` (nearest enemy, Overload), `PULSE` (every machine in
  reach, Breach). Cost, power, reach and duration are fields on the `.tres`;
  the shared cooldown and the regen rate live on `hack_config.tres`.
- **Firewall is a multiplier, not +DEF.** `Health.guard_mult` is applied at
  step 6 *after* DEF and *before* the floor: `max(1, (raw − DEF) × guard)`.
  "Halved" therefore means halved against what would actually have landed,
  against a boss as much as a Scav, and the floor still holds. Recasting
  refreshes the window rather than stacking.
- **Overload refuses to cast with nothing in reach**, at no cost. A fizzle
  that spent 3 RAM would teach the player to stop casting. Firewall and
  Breach always cast — Firewall always has a target (you), and Breach's
  pulse is the point even when it finds nothing.
- **Casting has no player state** (same reasoning as ranged): auto-targeted
  and instant, it costs a cooldown and never commitment. Firewall is a
  reaction you can make mid-jump, not a plan.
- **Ownership is a `GameState` flag** on each hack (`hack.overload`,
  `hack.breach`). Firewall has no flag: factory-installed, always owned.
  Programs are handed out by the same `Pickup` node chests use, with
  `kind = HACK`.
- **The quickslot is the Cyberdeck's** (`ability.cyberdeck`). Without the
  deck the kit is single-slot and cycling is refused with a reason the HUD
  shows. The district must place the deck before Overload (DESIGN.md §2);
  the gyms grant it on load.
- **A stunned enemy stays stunned when hit.** Breach → walk in → swing is the
  loop, so a stagger-worthy hit does not exit the `Stunned` state; knockback
  still applies. Stunned enemies disarm both the attack box and contact
  damage, and gravity still applies — a stunned drone falls.
- **Breach doors open two ways.** The terminal interaction is free and checks
  ownership only (rule 2). A Breach cast in reach also opens the door, at the
  cast's normal cost, because pulsing next to a door should do the obvious
  thing.
- **RAM regen** is `0.4/s` before the gloves (`TUNE`): a full 12-point pool
  from empty in 30 seconds, one Firewall in 10. Fractional points accumulate
  so the rate is honoured exactly. Level-up raises the ceiling and refills
  nothing; the save terminal (M5) restores the pool.
