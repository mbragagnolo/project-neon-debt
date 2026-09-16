# Neon Debt: the chain

Rendered from `factory/chain.json` by the game-factory skill's `chain.py`; edit that, never this.

| # | step | skill | reads | writes | gate |
|---|---|---|---|---|---|
| 1 | design | game-designer | `DESIGN.md` | `design/design.md`, `design/rooms.json`, `design/briefs/*.md` | *the design reads as a game* |
| 2 | plan | producer | @design | `plan/plan.json`, `plan/log.md` |  |
| 3 | feel | game-feel | @design, `feel/feel.json`, `feel/targets.csv`, `game/src/player/*.tres` | `feel/controller.json` | *moving around an empty room is fun* |
| 4 | reach (runs here) | level-designer | @feel | `game/tools/stacks/reach.json` |  |
| 5 | timings (runs here) | enemy-designer | @feel | `enemies/player.json` |  |
| 6 | numbers | systems-designer | @design, @timings, `systems/players.csv`, `systems/targets.csv`, `systems/godot.json` | `systems/tables/*.csv`, `enemies/stats.csv` |  |
| 7 | enemies | enemy-designer | @timings, @numbers, @design | `enemies/*.json`, `enemies/*.brief.md`, `enemies/*.encounter.md` |  |
| 8 | rooms | level-designer | @design, @reach, @enemies, `game/tools/stacks/district.json` | `game/tools/stacks/*.room` |  |
| 9 | words | narrative-designer | @design, `narrative/narrative.json` | `narrative/strings.json`, `narrative/dialogue/*.json`, `narrative/cast/*.md` |  |
| 10 | concept | concept-artist | @design, @rooms | `game/tools/art/sets/*.json` | *the concept is the room* |
| 11 | cast | character-designer | @design, @enemies | `game/tools/art/cast/*.json`, `game/tools/art/work/*/clips.json`, `game/assets/sprites/*.png` |  |
| 12 | sets | environment-artist | @concept | `game/assets/tiles/*.png`, `game/assets/props/*.png` |  |
| 13 | effects | vfx-artist | @cast, `bible/events.json` | `game/tools/art/vfx/*.json`, `game/tools/art/work/vfx/*/clips.json`, `game/assets/fx/*.png` |  |
| 14 | interface | ui-artist | @design, @words, `bible/art.json`, `ui/ui.json` | `ui/theme.json`, `game/assets/ui/*.png` |  |
| 15 | dress | level-artist | @rooms, @sets, @effects | `game/tools/stacks/*.dress.json` | *the district reads as one style at 1:1* |
| 16 | sfx | sound-designer | `bible/events.json`, `audio/audio.json`, `audio/sfx/recipes.py` | `audio/sfx/sfx.json`, `game/assets/audio/sfx/*.wav` |  |
| 17 | music | composer | @sfx, `bible/moods.json`, `audio/audio.json`, `audio/music/instruments.py`, `audio/music/motifs.json`, `audio/music/tracks/*.json` | `audio/music/music.json`, `game/assets/audio/music/**` |  |
| 18 | integrate (runs here) | godot-integrator | @cast, @effects, @enemies, @numbers, @interface, @sfx, @music, `game/tools/integrator.json` | `game/tools/integrator_report.md` |  |
| 19 | review | art-director | @cast, @sets, @effects, @interface, `bible/art.json` | `art/reviews/*/measure.json`, `art/reviews/*/report.md` |  |
| 20 | play (runs here) | autoplayer | @integrate, @dress, `runs/autoplayer.json` | `runs/*/runs.json` |  |
| 21 | ship | shipper | @play, @plan, `release/release.json` | `dist/*/receipt.json` |  |

## design: the pitch to a design doc, a room list and a brief per character

**Skill.** game-designer

**Why here.** Nothing else can start: every skill after this one reads the pillars, the verbs, the room list or a brief.

**Hands on.** `design/design.md`, `design/rooms.json`, `design/briefs/*.md`

**Checked by.**

- `scripts/loop_check.py --project {project}` (game-designer) -- every verb paid off, every room teaching something, every door with a partner

**Gate.** A person looks, and the producer's log gets a sign-off row quoting "the design reads as a game". Nothing after this step runs until it does.

## plan: the design's slice into milestones with acceptance as checks, and the pass log started

**Skill.** producer

**Why here.** The plan is what the gates close against, and the factory reads its log to know which gates a person has signed off.

**Hands on.** `plan/plan.json`, `plan/log.md`

**Leaves.** `plan/milestones.md`

**Checked by.**

- `scripts/plan.py --project {project} --check` (producer) -- the plan and the log parse, every check kind exists, every skill named is in the manifest

## feel: the controller measured headless and tuned until the design's targets are met

**Skill.** game-feel

**Why here.** The genre lives or dies on the jump, and two things downstream are arithmetic on it: how far a room may stretch, and how long an enemy's tell must be.

**Hands on.** `feel/controller.json`

**Leaves.** `feel/runs/*/report.md`, `feel/runs/*/measure.json`, `feel/log.md`

**Checked by.**

- `scripts/report.py --project {project} --strict` (game-feel) -- every target judged against the newest measurement

**Gate.** A person looks, and the producer's log gets a sign-off row quoting "moving around an empty room is fun". Nothing after this step runs until it does.

## reach: the movement model the level solver uses, read out of the controller's resource

**Skill.** level-designer (the factory runs this one)

**Why here.** The reach is never typed. A knob moves and every gap in the district is judged against a stale number until this runs again.

**Hands on.** `game/tools/stacks/reach.json`

**Checked by.**

- `scripts/reach.py --project {project} --strict` (game-feel) -- the measured reach against reach.json, in tiles

## timings: the player's side as data: the dash, the i-frames, every weapon's commit and reach

**Skill.** enemy-designer (the factory runs this one)

**Why here.** An enemy's tell is only long enough against a number, and that number comes out of the project, not out of a designer's head.

**Hands on.** `enemies/player.json`

## numbers: every number in tables, simulated against the slice until the design's targets hold

**Skill.** systems-designer

**Why here.** The enemies and the rooms are both priced from these; balancing after the content is built is a retune of everything.

**Hands on.** `systems/tables/*.csv`, `enemies/stats.csv`

**Leaves.** `systems/sim.json`, `systems/report.md`, `systems/log.md`

**Checked by.**

- `scripts/report.py --project {project} --strict` (systems-designer) -- every target judged over the simulated runs
- `scripts/adapters/godot_tables.py --project {project} --check` (systems-designer) -- the engine still holds what the tables say

## enemies: each archetype as a state machine, every attack dodgeable, punishable or ignorable on purpose

**Skill.** enemy-designer

**Why here.** The rooms need the encounter notes and the cast needs the briefs, and both are rendered from the machine.

**Hands on.** `enemies/*.json`, `enemies/*.brief.md`, `enemies/*.encounter.md`

**Leaves.** `enemies/matchup.md`

**Checked by.**

- `scripts/machine.py --project {project} {project}/enemies/*.json --strict` (enemy-designer) -- every state reachable, every attack behind a tell, the timings against the player's

## rooms: the district as ASCII specs, every room solved with the kit the walk grants at its door

**Skill.** level-designer

**Why here.** The layout is the last thing that is cheap to change. Everything after this is drawn on top of it.

**Hands on.** `game/tools/stacks/*.room`

**Leaves.** `game/tools/stacks/district.png`, `game/tools/stacks/pace.png`

**Checked by.**

- `scripts/reach.py --district {rooms}/district.json --strict` (level-designer) -- every gap and ledge against the movement reach
- `scripts/solve.py --district {rooms}/district.json --strict` (level-designer) -- every room solved for real, the district walked door by door

## words: the cast's voices, the dialogue and every string keyed and measured in its box

**Skill.** narrative-designer

**Why here.** The interface needs the longest line in each box before it can size one.

**Hands on.** `narrative/strings.json`, `narrative/dialogue/*.json`, `narrative/cast/*.md`

**Checked by.**

- `scripts/lint.py --project {project} --strict` (narrative-designer) -- every line inside its box with the real font, every page present

## concept: one concept still per room style, and the cut list sized from the figure

**Skill.** concept-artist

**Why here.** What is where and how the light falls is decided once, before anything is drawn at the size it ships at.

**Hands on.** `game/tools/art/sets/*.json`

**Leaves.** `game/tools/art/source/**`

**Gate.** A person looks, and the producer's log gets a sign-off row quoting "the concept is the room". Nothing after this step runs until it does.

## cast: every character and enemy from its brief to a sprite sheet with a clip table

**Skill.** character-designer

**Why here.** The effects fire over these frames and the integrator writes their clip tables into the scenes.

**Hands on.** `game/tools/art/cast/*.json`, `game/tools/art/work/*/clips.json`, `game/assets/sprites/*.png`

## sets: the wall ring, the props and the back and outside planes from the cut list

**Skill.** environment-artist

**Why here.** The dress step places these by name; nothing can be placed before it exists.

**Hands on.** `game/assets/tiles/*.png`, `game/assets/props/*.png`

## effects: the hit sparks, dust and bursts as sheets, and the light and particle presets by name

**Skill.** vfx-artist

**Why here.** The dress file names the presets and the integrator writes the clip tables, so both need these first.

**Hands on.** `game/tools/art/vfx/*.json`, `game/tools/art/work/vfx/*/clips.json`, `game/assets/fx/*.png`

## interface: the theme, the screen furniture and the palette the interface code imports

**Skill.** ui-artist

**Why here.** It is measured over a real room shot, so it wants the rooms dressed -- but the theme the integrator writes is needed before the build is played.

**Hands on.** `ui/theme.json`, `game/assets/ui/*.png`

**Checked by.**

- `scripts/lint.py --project {project} --strict` (ui-artist) -- every colour on a role, every text role's contrast over the room behind it
- `scripts/sprites.py --project {project} --check` (ui-artist) -- the sprites on disk are the ones the grids describe

## dress: every room dressed and lit from its assets, shot in the engine and measured

**Skill.** level-artist

**Why here.** The first shot is where the look either is the concept or is not, and it is the cheapest place to find out.

**Hands on.** `game/tools/stacks/*.dress.json`

**Gate.** A person looks, and the producer's log gets a sign-off row quoting "the district reads as one style at 1:1". Nothing after this step runs until it does.

## sfx: one sound per event, mastered to its class and routed to a bus

**Skill.** sound-designer

**Why here.** The music is mixed against these, and the integrator checks every id the code plays against the table.

**Hands on.** `audio/sfx/sfx.json`, `game/assets/audio/sfx/*.wav`

**Leaves.** `audio/sfx/runs/*/report.md`

**Checked by.**

- `scripts/table.py --project {project} --strict` (sound-designer) -- every event with a sound has a file and every file answers an event

## music: a track per mood as stems the engine raises by state, mastered under the effects

**Skill.** composer

**Why here.** It is mixed against the effects' classes, so the sounds come first.

**Hands on.** `audio/music/music.json`, `game/assets/audio/music/**`

**Leaves.** `audio/music/runs/*/report.md`

**Checked by.**

- `scripts/table.py --project {project} --strict` (composer) -- every mood has a track and every stem a state the engine raises

## integrate: every contract file landed in the engine as a resource, and proven to load

**Skill.** godot-integrator (the factory runs this one)

**Why here.** This is the one step where the pipeline's data becomes the game, and it is entirely mechanical.

**Hands on.** `game/tools/integrator_report.md`

**Checked by.**

- `scripts/tables.py --project {game}` (godot-integrator) -- every table in the engine is what the contract says
- `scripts/frames.py --project {game}` (godot-integrator) -- every clip table on the node that plays it
- `scripts/audio.py --project {game}` (godot-integrator) -- every sound and music id the code plays has a file on the right bus
- `scripts/imports.py --project {game}` (godot-integrator) -- every import sidecar against the rules

## review: every asset measured against the bible, the findings rolled up by cause

**Skill.** art-director

**Why here.** A set made over weeks drifts, and the review is what says how, in numbers, before anyone plays it.

**Hands on.** `art/reviews/*/measure.json`, `art/reviews/*/report.md`

**Checked by.**

- `scripts/audit.py --project {project} --strict` (art-director) -- every asset against its kind's floors

## play: the bot plays every room from every arrival door, headless, at fixed step

**Skill.** autoplayer (the factory runs this one)

**Why here.** It is the only step that finds out whether what the whole chain made can be played.

**Hands on.** `runs/*/runs.json`

**Leaves.** `runs/*/report.md`, `runs/*/heat/heat.md`

**Checked by.**

- `scripts/report.py --project {project} --strict` (autoplayer) -- every exit the solver proved, taken by the bot in the engine

## ship: the gates, the tag, the export from it, the shots, the changelog and the page

**Skill.** shipper

**Why here.** Last, and it refuses to run if the build has not been played since the game last changed.

**Hands on.** `dist/*/receipt.json`

**Leaves.** `dist/*/report.md`, `dist/*/changelog.md`

**Checked by.**

- `scripts/preflight.py --project {project}` (shipper) -- clean, committed, tests green, every milestone before this one, played since the last change
