# Neon Debt: the chain

Written by the game-factory's `run.py --render` on 2026-09-16. `factory/chain.json` is the chain; `factory/state.json` is the ledger.

**11** done, **7** blocked, **3** gated

**Next: design** -- the pitch to a design doc, a room list and a brief per character

| step | skill | state | last pass | note |
|---|---|---|---|---|
| **design** | game-designer | gated | 2026-09-16 14:42:06 | nobody has signed off "the design reads as a game" |
| plan | producer | done | 2026-09-16 14:42:06 | sitting on design |
| feel | game-feel | blocked |  | waiting on design; checked 2026-09-16, failed: every target judged against the newest measurement |
| reach | level-designer | blocked |  | waiting on feel; checked 2026-09-16, failed: the measured reach against reach.json, in tiles |
| timings | enemy-designer | done | 2026-09-16 14:50:52 | sitting on feel |
| numbers | systems-designer | blocked |  | waiting on design; checked 2026-09-16, failed: every target judged over the simulated runs |
| enemies | enemy-designer | done | 2026-09-16 14:42:06 | sitting on numbers, design |
| rooms | level-designer | blocked |  | waiting on design, reach; checked 2026-09-16, failed: every gap and ledge against the movement reach |
| words | narrative-designer | done | 2026-09-16 14:42:06 | sitting on design |
| concept | concept-artist | gated | 2026-09-16 14:42:06 | nobody has signed off "the concept is the room"; sitting on design, rooms |
| cast | character-designer | done | 2026-09-16 14:42:06 | sitting on design |
| sets | environment-artist | done | 2026-09-16 14:42:06 | sitting on concept |
| effects | vfx-artist | done | 2026-09-16 14:42:06 |  |
| interface | ui-artist | blocked |  | waiting on design; checked 2026-09-16, failed: every colour on a role, every text role's contrast over the room behind it |
| dress | level-artist | gated | 2026-09-16 14:42:06 | nobody has signed off "the district reads as one style at 1:1"; sitting on rooms |
| sfx | sound-designer | done | 2026-09-16 14:42:06 |  |
| music | composer | done | 2026-09-16 14:42:06 |  |
| integrate | godot-integrator | done | 2026-09-16 15:02:06 | sitting on numbers, interface |
| review | art-director | done | 2026-09-16 15:02:07 | sitting on interface |
| play | autoplayer | blocked |  | waiting on dress; checked 2026-09-16, failed: every exit the solver proved, taken by the bot in the engine |
| ship | shipper | blocked |  | waiting on play; checked 2026-09-16, failed: clean, committed, tests green, every milestone before this one, played since the last change |

## Waiting on a person

- **design**: "the design reads as a game" -- `log.py --project . - signoff "the design reads as a game" --why <who>`
- **concept**: "the concept is the room" -- `log.py --project . - signoff "the concept is the room" --why <who>`
- **dress**: "the district reads as one style at 1:1" -- `log.py --project . M8 signoff "the district reads as one style at 1:1" --why <who>`
