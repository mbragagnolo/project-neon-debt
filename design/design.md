# Neon Debt: the design

Written from `DESIGN.md` and the `docs/` it locked, in the game-designer's
form (kiln), so the room list and the briefs can be checked against it.
`DESIGN.md` stays the record of the decisions; this is the design the
other skills read.

## Pitch

A cyberpunk 2D metroidvania with Castlevania's RPG layer, in Godot 4,
made by one person and coding agents. The fantasy is not the street
samurai: you are behind on the payments for the body you live in, and the
augments that would let you climb are already installed and locked
pending payment. References: Hollow Knight for the pull of a corner you
cannot reach yet, Symphony of the Night for gear and levels that are felt
in the arithmetic, REPLACED for the look. The first slice is one district
in thirty to forty-five minutes.

## Pillars (table)

| Pillar | It cut |
|---|---|
| Movement feels great | The movement lock on melee (swinging while running is the point) and the jump-cancelled dash: a jump pressed mid-dash waits in the buffer and fires as the dash ends. |
| Combat has texture, one intertwined kit | Independent build-your-own systems and manual stat allocation: deferred to V2 whole, so the slice's verbs share one resource loop and enemies force the switch. |
| Exploration pulls | Any shaft as a double-jump tease: every shaft is climbable once the Mag-Hook is owned, so a tease is always a single high wall with no facing wall. |
| Numbers matter, felt not read | Speech checks, dialogue stats, crafting and a scrap currency: stats are combat only and credits buy convenience, never an unlock. |
| The boss is a wall worth climbing | A boss any one verb can solve: DEF 4 blunts light melee, the wrench never interrupts him, the drones in phase two answer only to Breach. |

## Loop

Explore until a gap or a door says what you lack, fight what is on the
way and gear up and level from it, take the ability that opens the gap,
and go back to open what it gated, until the Landlord.

## Verbs (table)

| Verb | id | kind | kit | paid off by |
|---|---|---|---|---|
| run | run | move | start | gates, encounters |
| jump, with coyote time and a buffer, cut on release | jump | move | start | gates, encounters |
| ground dash, altitude held, no i-frames yet | dash | move | start | gates, encounters |
| wall slide | wall_slide | move | start | gates |
| wall jump | wall_jump | move | mag_hook | gates |
| air dash | air_dash | move | sidewinder | gates |
| double jump | double_jump | move | never | gates |
| melee, swinging while moving, a commitment | melee | attack | start | damage, stagger, ammo, encounters |
| shoot, eight-way off the movement keys, no commitment | ranged | attack | start | damage, stagger, ammo, encounters |
| cast Firewall, the factory-installed program | firewall | cast | start | ram, damage |
| cast Overload | overload | cast | overload | ram, damage, stagger |
| cast Breach | breach | cast | breach | ram, gates, stagger |
| cycle the quickslot | quickslot | interact | cyberdeck | ram |
| equip, from the six slots | equip | interact | start | gear, stats |
| use a care terminal | save | interact | start | terminals, ram |
| talk | talk | interact | start | quest, credits |
| read the map | map | interact | start | gates |

## Systems (table)

| System | id | what it does | tuned by |
|---|---|---|---|
| ability gates and teases | gates | one gap shape per ability, readable at a glance: a shaft is the Mag-Hook, a sealed terminal door is Breach, a wide flat gap is the Sidewinder, a high single wall is the double jump the slice never grants; the map shows the pull | `movement_config.tres` through the reach table; never a typed width |
| encounters | encounters | one enemy teaches one thing; contact damage always on at half power, so spacing always matters | `enemies/*.tres`, the roster's ratios |
| the damage pipeline | damage | one ordered pipeline, no per-verb exceptions: weapon power times a saturating stat multiplier, minus flat DEF, floor 1; hitstop, knockback, i-frames on the player only | `combat_config.tres`, `docs/combat/damage-pipeline.md` |
| stagger | stagger | one threshold per enemy: a hit over it interrupts; the Riot unit ignores a wrench and crumples to a maul or a hack | `stagger_threshold` per enemy |
| ammo, refilled by melee | ammo | ranged draws from one pool that melee hits refill; a rhythm of shoot, close, swing, back out; the refill is a field on the melee weapon | the weapon `.tres` |
| RAM | ram | the hack pool: slow regen, full on save, one second global cooldown, three casts to an early pool; the Cyberdeck grows it | `docs/combat/hacks.md` |
| stats and levels | stats | XP to levels, auto-allocated over HP, RAM, STR, DEX, INT; DEF from gear only; a level is a full heal; the slice ends near level 5 | `docs/rpg/stats-and-curves.md` |
| gear | gear | ten items in six slots: two weapon trios as sidegrades on the speed axis with a better total, four clothing pieces with one modifier each; tools, never weapons | `docs/rpg/items.md` |
| credits and the stall | credits | drops and one vendor with four entries; never an unlock | `docs/rpg/economy.md` |
| the quest | quest | one fetch quest, offered, active, complete, no branch, no choice; the reward is the dead man's hardhat | `quests/memory_chip.tres` |
| care terminals | terminals | save, full heal, full RAM, the respawn point; three in the slice | placement |

## Fail state

Death returns the player to the last care terminal used with everything
kept, and the room reloads so its enemies are back. No terminal used yet
means back to 14-C. Falling short of the roof gap is a void, not a death:
the lip, and damage. Losing a terminal's worth of progress for testing a
gap would teach players not to test gaps.

## Cast (table)

| Character | id | role | teaches | brief |
|---|---|---|---|---|
| Dani Okonkwo | dani | player | | briefs/dani.md |
| Scav | scav | enemy | melee | briefs/scav.md |
| Watcher drone | drone | enemy | ranged | briefs/drone.md |
| Riot unit | riot | enemy | stagger | briefs/riot.md |
| Elite Scav | elite_scav | elite | gear | briefs/elite_scav.md |
| The Landlord | landlord | boss | damage | briefs/landlord.md |
| Stitch | stitch | npc | | briefs/stitch.md |
| Marisol | marisol | npc | | briefs/marisol.md |
| Ferro | ferro | prop | | briefs/ferro.md |

## Slice

The Stacks: one district of vertical write-off housing, thirty-four
rooms, from waking in unit 14-C to the Landlord on floor 40. The kit
grows in a locked order: Mag-Hook (wall jump) minutes in, the Cyberdeck
(the quickslot), Overload, Breach before the midpoint, the Sidewinder
(air dash) carried back to Stitch for surgery. Three visible double-jump
ledges the slice never opens; the closing shot lights one up. Four enemy
kinds and one elite, one boss in two phases, one hub with a terminal, the
vendor and the quest giver, one fetch quest into the Gut, ten items, two
one-way shortcut grates back toward the hub. Greybox first: the art pass
came last and only on the slice. Cut from the slice on purpose: the
double jump, manual stats, drops, a second district, any purchase that
opens a way.

Ten items: three melee, three ranged, four clothing, two of them from
the start, one bought, one the quest's. Three hacks, one from the start.

## Budget (table)

| What | id | count |
|---|---|---|
| rooms | rooms | 34 |
| Scavs placed | scav | 31 |
| Watcher drones placed | drone | 17 |
| Riot units placed | riot | 7 |
| the Elite | elite_scav | 1 |
| the boss | landlord | 1 |
| care terminals | save | 3 |
| double-jump teases | tease | 3 |
| HP ups | hp_up | 3 |
| RAM ups | ram_up | 3 |
| items found in rooms | item | 6 |
| programs found in rooms | hack | 2 |
| npcs | npc | 2 |

## Success

Three to five strangers play it. They finish without being told what to
do. At least one asks how to get up to a teased ledge. They can say why
they would pick melee, ranged or a hack in a given fight. Someone asks
when they can play more.
