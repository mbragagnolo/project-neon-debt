# The Landlord

**Status: built (M6).** The chromed debt enforcer of the Stacks; the slice's
boss (DESIGN.md §3.5; docs/narrative/hook.md for what he holds).

## What he is for

"The boss is a wall worth climbing" — hard enough to demand engagement with
all three verbs, ~3–8 attempts for a decent player. The fight is designed so
that every verb has a job and no verb is the answer:

| Verb | Its job against him |
|---|---|
| Light melee (wrench, blade) | Chip. DEF 4 blunts it and it never interrupts him; the blade lands near the floor. |
| Heavy melee (maul) | The interrupt. 25 through his armour at level 5, over his threshold of 16 — a maul swing into a baton windup is the biggest single win in the fight. |
| Ranged (rivet gun) | The interrupt at range: 20 through the armour at level 5. Zipgun and nailgun chip. |
| Overload | The interrupt you do not have to be next to him for. 20 through the armour at level 5. Three RAM. |
| Breach | Phase two: he calls two Watcher drones. Breach drops them; nothing else stops two guns in the air while he swings. |
| Firewall | Halves a baton (14 → 7) or a slam (12 → 6) you could not avoid. |

## Stat block

| | |
|---|---|
| HP | 240 (phase two at 120) |
| attack_power | 14 (contact 7) |
| DEF | 4 — the top of the slice's range |
| stagger_threshold | 16 — the wrench (9 at level 5) never; the maul, the rivet gun and Overload always |
| Tags | none — he is a man in chrome. His support is `mechanical`. |
| Rewards | 200 XP, 100 credits |

## The attack matrix

| Attack | Tell | Punishes | Invites | Phase |
|---|---|---|---|---|
| **Baton** | Plants, lights up, 0.5s | Standing in reach | A maul or Overload into the windup; a dash through and a swing at his back during the 0.6s recovery | 1, 2 |
| **Shock slam** | Crouches, lights up, 0.7s | Standing on the floor: a wave each way along it | Jumping to a ledge or the dais; the recovery after | 1, 2 |
| **Repo beam** | A line from his deck to you, brightening for 0.8s | Standing still — the shot goes where the line last pointed | Moving; a dash; ranged fire back down the line during the recovery | 2 |
| **Phase shift** | Stops, roars, invulnerable 1.4s | — | Casting Breach as the drones arrive, or clearing a ledge before they do | at 50% |

Phase two: attack cooldown ×0.7, approach speed ×1.3, the beam, the drones.

## The arena — `collections`

2×1. A flat floor for the slam to own, two one-way ledges at row 12 and a
raised dais in the middle so the slam has an answer, and nothing to hide
behind. Every door seals while he lives (`Door.lock()`); the player got in,
they leave over him or through the terminal in reception.

## Death, and the slice's end

Rewards ride `enemy_died` like everyone else's. Then `boss_defeated`: the
world waits a beat, the protagonist's line, and travels to reception, where
the camera finds the tease on the hanging balcony and its lock turns green —
the collections override handshaking with the locked leg firmware. The
ending card: *unauthorized override accepted. To be continued.* The run
continues after it; the district is still there.

The encounter carries a persist flag, so a dead Landlord stays dead.

## Implementation notes

He is the one roster entry that is a subclass (`landlord.gd` extends
`Enemy`): phases, attack selection by distance, the arena lock, the slam and
the beam. The baton is the Scav's windup → lunge → recover with his numbers;
his stagger is everyone's stagger; his shots come from the base's
`fire_toward`. The generic Recover and Stagger states ask the enemy where to
go next (`after_recover_state`), which is how they serve both a Scav that
patrols and a boss that approaches.

## V2 candidate (parked)

The remote-disable attempt from hook.md: mid-fight he tries the override on
the player and an ability flickers off for a beat.
