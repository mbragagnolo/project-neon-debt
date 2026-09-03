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
| Balanced (starter) | **Pipe wrench** — steam-fitter's tool from the towers | 8 | **1.6/s** | Chunky, instant-read silhouette. Speed playtested in M2 — see below |
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

### Melee speed, after the first M2 playtest

The wrench was authored at 1.0/s and felt dead in the hand: one swing per
second is 84% dead air, and no amount of visual feedback fixes a verb you can
only use once a second. **1.6/s is the playtested value** and is what the
`.tres` now carries.

Two consequences, neither resolved yet because neither weapon exists:

- **The trio's speed spread needs rescaling.** The axis was authored as
  ratios against a 1.0 balanced weapon — fast ×1.8, slow ×0.5. Against 1.6
  those become 2.9/s and 0.8/s if the spread is to be preserved; leaving the
  blade at 1.8 would make it a rounding error away from the starter and
  collapse the sidegrade into a straight upgrade. Set them when they are built
  and can be felt, not now.
- **Armour balance shifted with it.** DPS through DEF is
  `(raw − DEF) × attacks_per_second`, so the wrench got 60% better against
  the DEF-5 station too, not just faster. That is the intended second lever
  (stats-and-curves.md) working as designed, but it means enemy DEF — already
  scheduled to be set last — must be set against the *tuned* speeds.

The interlock economy is unchanged: `ammo_on_hit` is per landed hit, so a Scav
still funds the same 2–3 zipgun shots it always did. Only the rate at which
you can collect it moved.

V1 simplicities (deliberate): single projectiles, no spread, no pierce, no
damage falloff; straight lines except the rivet's arc. Feel constraint for
M2: every ranged weapon must aim upward comfortably — the Watcher drone is a
vertical threat.

## Clothing — LOCKED (identities & slot personalities), numbers TUNE

**Structural fact: clothing in V1 is progression, not choice.** Four pieces,
four slots — exactly one item per slot in the slice. Each piece is a
memorable acquisition moment, never a build option. Do not design competing
pieces for a slot inside the ten-item budget.

**No stat points on clothing.** DEF + one modifier, nothing else. Levels
raise the five stats, clothing owns DEF, modifiers carry the personality.
Stat-bearing clothing becomes interesting exactly when V2 makes builds real;
parked there.

Each slot has a fixed personality, expressed through its modifier — together
the set quietly demonstrates the whole intertwined kit:

| Slot | Identity | DEF | Modifier (slot personality) |
|---|---|---|---|
| Body | Utility worker's padded jacket | 2 | +max HP — survival |
| Legs | Steel-toe work boots | 1 | dash cooldown −15% — mobility |
| Hands | Insulated linesman's gloves, deck-jacked | 1 | +RAM regen — the hack slot |
| Head | Scavved hardhat, cracked HUD visor | 1 | +1 energy on melee hit — feeds the combat rhythm |

Full-set DEF totals 5 (`TUNE`): against the locked anchors a light hit drops
from ~6 to ~1–2, a heavy one from ~12 to ~7 — felt, never trivializing.

## Modifier table — LOCKED

A modifier is an engine hook, not content. Rules:

- **The pool contains exactly the modifiers shipped items use** — no
  speculative entries. Currently four, one per clothing piece:

| Modifier | Carried by | Engine hook | Lands in |
|---|---|---|---|
| `max_hp_bonus` (flat) | Jacket | Stats reads equipment into max HP | M3 |
| `dash_cooldown_mult` (−15%) | Boots | Controller reads *effective* dash cooldown via the stats layer, not raw MovementConfig | M3 (touches M1 code) |
| `ram_regen_mult` (+%) | Gloves | RAM regen consults equipment | M4 |
| `melee_energy_bonus` (+1/hit) | Hardhat | The melee→energy interlock constant becomes equipment-adjustable | M2 |

- **Weapons carry no modifiers in V1.** Their personality already lives in
  damage, attack speed, energy cost and projectile behavior; four more engine
  hooks would buy flavor the sidegrades already deliver.
- **Uniqueness is a juiced value, not a new modifier.** The quest-reward
  piece carries a stronger roll of its slot's modifier — zero new code.
- No stacking rules needed: each modifier exists on exactly one item. The
  whole system is one dictionary on the item resource plus four read-sites.
- Side benefit: `dash_cooldown_mult` forces the effective-stats layer to
  exist by M3 — the same indirection V2's independent builds need anyway.

## Placement — LOCKED

Principle: every acquisition method hands out at least one item, and the
better the item, the more deliberate the acquisition.

| Item | Source | Why there |
|---|---|---|
| Pipe wrench + zipgun | Start kit | Locked in §2 player kit |
| Powered utility blade | Early critical-path chest | First pickup (~10 min in): teaches the equip screen, proves weapons are worth finding |
| Work boots | Mid-path chest | First DEF, right as the Scav zone starts to hurt |
| Nailgun | Hidden room, mid | First optional reward — poking corners pays |
| Linesman's gloves | Hidden room, deeper | Hidden rooms stay generous |
| Padded jacket | Vendor | Biggest DEF piece is the credit sink, alongside the health/ammo upgrades |
| Breaker maul | Behind the Breach door | The experienced ability gate pays out the armor-cracker: gate teaches Breach, reward answers the Riot unit, one room |
| Rivet gun | Deep optional area, hard platforming | The skill-shot weapon behind the skill check |
| Hardhat (juiced roll: +2 energy/melee hit) | Quest reward | A dead worker's safety helmet recovered from the hazard area his body lies in — writes its own flavor text |

Pacing rules:

- Nothing found in the first ~10 minutes — movement carries the open.
- Roughly one felt pickup per ~10 minutes after that.

Constraint exported to `level-design/stacks-graph.md`: **Breach must be
acquirable before the district's midpoint** (the maul sits behind its door).

## Open sections

1. Names (blocked on narrative/hook.md) — every identity above is final,
   the label on it is not.
