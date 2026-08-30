# Items

**Status: in progress** — melee locked; ranged, clothing, modifiers, placement
and names still open. All numbers `TUNE`; all names `TODO` pending
`narrative/hook.md`.

Budget (DESIGN.md §2): 3 melee + 3 ranged + 4 clothing (one per slot). The
player starts with one melee and one ranged weapon, so ~8 items are found.

## Doctrine — LOCKED

**Tools, not weapons.** In The Stacks you cannot afford weapons; everything is
scavenged from the towers — maintenance closets, demolition sites, a dead
utility worker's kit. Zero art budget required to read the theme, and it sets
the contrast for later: the first *actual* weapon the player sees is chromed
corpo hardware in someone else's hands (the Landlord's).

- **No katanas.** The monokatana is the genre's most worn prop, and it carries
  the wrong class fantasy — it belongs to corpo street-samurai, not debtors.
  If V2 ever wants one, it is loot from a corpo district, never The Stacks.
- **Augs are progression, gear is loadout.** Augments are the ability gates
  and the thing you are in debt for; weapons stay external, scavenged, dumb
  metal. No wrist-blades or aug-weapons in V1 — the aug/gear line stays crisp.
- **No implied mechanics.** No crowbar (twenty years of games say crowbars pry
  doors open; our doors open with Breach). Base weapon identities stay
  un-electrified — stun belongs to modifiers and Breach synergies.

## Structure — LOCKED

Weapon trios are **sidegrades on the speed axis, upgrades in total budget**:
the starter sits in the middle; the two found weapons trade speed against
per-hit damage *and* carry better totals than the starter, so finding one is
still a felt upgrade. All three stay live: the flat-DEF heavy-hit bias
(stats-and-curves.md) makes armor favor heavy hits and swarms favor fast ones.

## Melee — LOCKED (identities), numbers TUNE

| Slot in trio | Identity | dmg | atk speed | Notes |
|---|---|---|---|---|
| Balanced (starter) | **Pipe wrench** — steam-fitter's tool from the towers | 8 | 1.0/s | Chunky, instant-read silhouette |
| Fast-light (found) | **Powered utility blade** — linesman's vibro-cutter for cable and drywall | 5 | 1.8/s | Best raw DPS; flat DEF eats it against armor |
| Slow-heavy (found) | **Hydraulic breaker maul** — servo-assisted demolition tool for rebar and concrete | 18 | 0.5/s | Punches through Riot-unit-grade armor |

## Ranged — LOCKED (identities), numbers TUNE

All three draw from the single shared energy/ammo pool (stats-and-curves.md),
which gives ranged a second sidegrade axis: damage-per-second vs
damage-per-energy.

| Slot in trio | Identity | dmg | rate | energy/shot | Notes |
|---|---|---|---|---|---|
| Balanced (starter) | **Zipgun** — home-made pipe pistol | 6 | 1.5/s | 1 | Dependable, not exciting; the drone gets taught with it |
| Fast-light (found) | **Modified nailgun** — construction tool, safety filed off | 3 | 4/s | 1 | Best DPS, worst damage-per-energy — sprays the pool away, and flat DEF eats each nail. Equal-cost on purpose: hungry, so its users close in to melee *more*, keeping the regen rhythm central |
| Slow-heavy (found) | **Rivet gun** — industrial hull-riveter throwing hot slugs | 15 | 0.6/s | 3 | Big hits that shrug off DEF; projectile is visibly slower with a slight arc — a skill-shot, not a hitscan hose |

V1 simplicities (deliberate): single projectiles, no spread, no pierce, no
damage falloff; straight lines except the rivet's arc. Feel constraint for
M2: every ranged weapon must aim upward comfortably — the Watcher drone is a
vertical threat.

## Clothing — LOCKED (identities), numbers TUNE

**Structural fact: clothing in V1 is progression, not choice.** Four pieces,
four slots — exactly one item per slot in the slice. Each piece is a
memorable acquisition moment, never a build option. Do not design competing
pieces for a slot inside the ten-item budget.

**Clothing is pure DEF.** No stat points, and no modifiers (deferred, below).
This is "DEF is gear-only" (stats-and-curves.md) taken to its conclusion:
clothing *is* the armor system, nothing else.

| Slot | Identity | DEF |
|---|---|---|
| Body | Utility worker's padded jacket | 2 |
| Legs | Steel-toe work boots | 1 |
| Hands | Insulated linesman's gloves | 1 |
| Head | Scavved hardhat, cracked HUD visor | 1 |

Full-set DEF totals 5 (`TUNE`): against the locked anchors a light hit drops
from ~6 to ~1–2, a heavy one from ~12 to ~7 — felt, never trivializing.
The quest-reward piece's uniqueness is flavor and a higher DEF value, not a
mechanic.

## Modifiers — DEFERRED past V1

No modifier system in the slice. A modifier is an engine hook, not content —
every effect is code M2–M4 would have to implement and test, and the slice's
ten items do not need it to differentiate.

Consequences applied to earlier locks:

- **RAM regen rate is a flat `TUNE` constant in V1.** The "increasable
  through gear" lever (stats-and-curves.md RAM section) is deferred together
  with the modifier system that would have carried it.
- The melee→energy interlock is untouched: it is a core system constant, not
  a modifier.

Parked candidates for when modifiers return (V1.1/V2) — the former slot
personalities, one engine hook each:

| Candidate | Natural slot | Engine hook |
|---|---|---|
| `max_hp_bonus` | Body | Stats reads equipment into max HP |
| `dash_cooldown_mult` | Legs | Controller reads effective cooldown via stats layer |
| `ram_regen_mult` | Hands | Regen consults equipment |
| `melee_energy_bonus` | Head | Interlock constant becomes equipment-adjustable |

Rule when the system lands: the pool contains exactly the modifiers shipped
items use — no speculative entries.

## Open sections (in discussion order)

1. Placement (start kit / chest / hidden room / quest reward / vendor) — the
   district's reward pacing in disguise
4. Names (blocked on narrative/hook.md)
