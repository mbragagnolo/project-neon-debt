# docs/ — design specs by area

Working design documents, split by discipline. [`DESIGN.md`](../DESIGN.md) at
the repo root stays the master: locked decisions, scope, milestones. The files
here *elaborate* those decisions into implementable specs — numbers, tables,
graphs, text.

**Precedence rule:** if an area doc contradicts DESIGN.md, DESIGN.md wins.
When a discussion here locks something new, the one-line decision goes back
into DESIGN.md and the detail stays here.

| Area | Owns | Feeds |
|---|---|---|
| [`combat/`](combat/) | Damage pipeline constants, hack specs, hitstop/knockback/i-frame rules | M2, M4 |
| [`rpg/`](rpg/) | Stat & XP curves, item list, credit economy, vendor stock | M3 |
| [`level-design/`](level-design/) | District topology, room graph, gate & save placement, gym notes | M5 |
| [`characters/`](characters/) | Enemy stat blocks & behaviors, boss phases, NPC roster | M2, M6 |
| [`narrative/`](narrative/) | Hook, tone, names, quest & NPC text | M5 (names land everywhere) |
| [`ui/`](ui/) | HUD layout, pause menu, map screen, inventory screen | M3, M5, M7 |

A spec is **draft** until its decisions are reflected in DESIGN.md or in a
merged implementation; mark the status at the top of each file.
