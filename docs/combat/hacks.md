# Hacks

**Status: locked.** Numbers `TUNE`. Elaborates DESIGN.md §3.2 against the
locked RAM model (stats-and-curves.md).

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
- M4 needs: quickslot UI, the 1s global cooldown, auto-target acquisition,
  the self-buff timer, and the `mechanical` stun hook (M2's pipeline
  already carries stagger and tags).
