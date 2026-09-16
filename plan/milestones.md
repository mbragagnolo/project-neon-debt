# Neon Debt: the plan

Rendered from `plan.json` and `log.md` by the producer skill's `plan.py`; edit those, never this.

| # | milestone | status |
|---|---|---|
| M0 | Skeleton | done |
| M1 | Movement feel | done |
| M2 | Combat core | done |
| M3 | RPG layer | done |
| M4 | Hacks | done |
| M5 | The district | done |
| M6 | Enemies and boss | done |
| M7 | Slice polish | open (shipped 2026-09-06 but sign-off: "external playtesters run it start to finish without guidance" fails now) |
| M8 | The look | open (1 of 7 checks fail) |
| M9 | Go or no-go | open (4 of 4 checks fail) |

## M0: Skeleton

**Deliverable.** A Godot project that runs headless and windowed, with the input map, the signal bus, GUT and CI, and one empty test room.

**Retires.** The engine and the agent workflow: text scenes, headless tests, a green CI before any feature exists.

**Acceptance.**

- [x] `game/project.godot` exists
- [x] `.github/workflows/ci.yml` exists
- [x] `game/src/core/events.gd` exists
- [x] `game/rooms/test_room.tscn` exists
- [x] a commit matching `^M0:`  (f43f7f5 2026-08-27)
- [x] `boot` exits 0  (exit 0)
- [x] `tests` exits 0  (exit 0)

**Log.**

- 2026-08-27 shipped: Godot project skeleton, signal bus, save state, headless test CI (f43f7f5)

## M1: Movement feel

**Deliverable.** The full controller (run, jump, dash, wall slide, coyote, buffer) tuned from one resource, in a gym with platforming challenges.

**Retires.** The genre lives or dies on the jump; nothing downstream is worth building until moving around an empty room is fun.

**Calls.** game-feel

**Acceptance.**

- [x] `game/src/player/movement_config.tres` exists
- [x] `game/src/player/movement_envelope.gd` exists
- [x] `game/rooms/gym.tscn` exists
- [x] `game/tests/test_player_movement.gd` exists
- [x] a commit matching `^M1:`  (df218ee 2026-08-27)
- [x] sign-off: "moving around an empty room is fun"  (2026-09-02, Marcos; inferred: M1 merged to main (b675ab1) and M2 started the same day)

**Log.**

- 2026-08-27 shipped: player controller, movement states, and the platforming gym (df218ee; Godot to 4.7.2 first (8efbcd9) so the controller is never written against an engine to migrate off)
- 2026-09-02 signoff: moving around an empty room is fun (Marcos; inferred: M1 merged to main (b675ab1) and M2 started the same day)

## M2: Combat core

**Deliverable.** Melee and ranged against a training dummy and the Scav: the damage pipeline, hitstop, knockback, i-frames, death, in a lab room.

**Retires.** Whether three verbs sharing one pipeline can feel different; whether the first enemy teaches spacing.

**Calls.** systems-designer, enemy-designer, game-feel

**Acceptance.**

- [x] `game/src/combat/damage.gd` exists
- [x] `game/src/enemies/scav/scav.tres` exists
- [x] `game/rooms/combat_gym.tscn` exists
- [x] `game/tests/test_damage_pipeline.gd` exists
- [x] `game/tests/test_scav.gd` exists
- [x] a commit matching `^M2:`  (1b69bed 2026-09-02)
- [x] sign-off: "fighting three Scavs is legible and satisfying"  (2026-09-03, Marcos; inferred: the tuning pass closed (8135b36, 4e8b424), merged (9134bd9), M3 started the same day)

**Log.**

- 2026-09-02 shipped: the damage pipeline, the first two verbs, and a lab to feel them in (1b69bed)
- 2026-09-02 note: wrench to 1.6/s: the first tuning number closed by feel (2e6c5fd)
- 2026-09-03 deferred: the heavy stagger threshold (599de5d: set enemy DEF last, after the weapons are tuned; done in M6)
- 2026-09-03 signoff: fighting three Scavs is legible and satisfying (Marcos; inferred: the tuning pass closed (8135b36, 4e8b424), merged (9134bd9), M3 started the same day)

## M3: RPG layer

**Deliverable.** Stats, XP and levels, the ten items as resources, the equip screen, pickups and the level-up moment, in a gear-and-levels lab.

**Retires.** Whether a gear swap produces a felt difference without trivialising enemies; the effective-stats layer the pipeline and the screen must share.

**Calls.** systems-designer

**Acceptance.**

- [x] `game/src/rpg/stats.gd` exists
- [x] `game/src/rpg/items/catalog.tres` exists
- [x] `game/src/ui/menus/equip_screen.gd` exists
- [x] `game/rooms/rpg_gym.tscn` exists
- [x] `game/tests/test_save_load.gd` exists
- [x] a commit matching `^Merge pull request #5 .*m3-rpg-layer`  (dbb68c9 2026-09-05)
- [x] sign-off: "equipping better gear visibly changes combat math"  (2026-09-05, Marcos; inferred: merged and M4 started the same day)

**Log.**

- 2026-08-30 scope-cut: weapon modifiers (6938ffc then f630d1a: weapons carry flat stats only, clothing keeps one modifier per piece)
- 2026-09-05 shipped: stats, the XP curve, the ten items, the equip screen, pickups, save (dbb68c9 (the merge; the work is 09-03))
- 2026-09-05 signoff: equipping better gear visibly changes combat math; HUD shows it (Marcos; inferred: merged and M4 started the same day)

## M4: Hacks

**Deliverable.** RAM, the three programs, the quickslot and a Breach-locked door, in a hacks lab.

**Retires.** Whether all three verbs get used naturally in one fight, or hacks stay a menu nobody opens.

**Calls.** systems-designer, game-feel

**Acceptance.**

- [x] `game/src/combat/hacks/breach.tres` exists
- [x] `game/src/combat/hacks/firewall.tres` exists
- [x] `game/src/combat/hacks/overload.tres` exists
- [x] `game/src/world/breach_door.tscn` exists
- [x] `game/rooms/hack_gym.tscn` exists
- [x] a commit matching `^M4:`  (1a603ca 2026-09-05)
- [x] sign-off: "all three combat verbs used naturally in one fight"  (2026-09-06, Marcos; inferred: M5 started the next day)

**Log.**

- 2026-08-31 scope-cut: Static Wall (47c1b18: Firewall replaces it and is the starter hack; the corp protects its collateral)
- 2026-09-05 shipped: the three programs, RAM, the quickslot, and the Breach door (1a603ca)
- 2026-09-06 signoff: all three combat verbs used naturally in one fight (Marcos; inferred: M5 started the next day)

## M5: The district

**Deliverable.** The Stacks: 25 to 35 greybox rooms with doors, the map screen, save points, the ability pickups in order, the double-jump teases, the shortcut loop, the hub with Stitch and Marisol, and the fetch quest.

**Retires.** Whether the loop plays end to end (explore, unlock, open what it gates, gear up, level, complete the quest) and whether every gate holds against the kit at that point.

**Calls.** game-designer, level-designer, narrative-designer

**Acceptance.**

- [x] at least 25 of `game/rooms/stacks/*.tscn`  (34 found)
- [x] `game/tools/stacks/district.json` exists
- [x] `game/src/world/world_graph.tres` exists
- [x] `game/src/ui/menus/map_screen.gd` exists
- [x] `game/src/quests/memory_chip.tres` exists
- [x] `game/tests/test_stacks.gd` exists
- [x] `game/tests/test_stacks_passage.gd` exists
- [x] a commit matching `^M5:`  (a57c598 2026-09-06)
- [x] sign-off: "can play the loop"  (2026-09-06, Marcos; inferred: M6 started the same day)

**Log.**

- 2026-09-06 shipped: The Stacks: 34 rooms, doors, terminals, the map, the hub and the quest (a57c598)
- 2026-09-06 decided: death penalty: respawn at the last care terminal, the room reloads, keep everything (DESIGN.md section 7)
- 2026-09-06 signoff: can play the loop: explore, unlock, open what it gates, gear up, level, complete the quest (Marcos; inferred: M6 started the same day)
- 2026-09-08 reopened: the slice could not be played past its fourth room (the level-designer's solver: three passages the body cannot fit through, the catwalks gate crossable with the starting kit, the Gut a trap before Breach; the room-level tests could not see any of it)
- 2026-09-08 shipped: three one-line repairs and the Gut's way back; 34 rooms solved with the full kit in the locked order (47311a5, ea517f4, bf61ac5)

## M6: Enemies and boss

**Deliverable.** The Watcher drone, the Riot unit, the Elite Scav, and the Landlord with two phases in a sealed arena, ending the slice.

**Retires.** Whether the boss is a wall worth climbing: beatable, demanding every verb, three to eight attempts for a decent player.

**Calls.** enemy-designer, character-designer

**Acceptance.**

- [x] `game/src/enemies/drone` exists
- [x] `game/src/enemies/riot` exists
- [x] `game/src/enemies/boss_landlord` exists
- [x] `game/src/enemies/scav/elite_scav.tres` exists
- [x] `game/tests/test_landlord.gd` exists
- [x] a commit matching `^M6:`  (9ecd39a 2026-09-06)
- [x] sign-off: "boss beatable, demands all verbs"  (2026-09-06, Marcos; inferred: M7 started the same day; the three-to-eight-attempts figure has no recorded playtest)

**Log.**

- 2026-08-31 deferred: drop tables (1f63bc8: the vendor refill and the melee interlock cover ammo; V1 ships no drops)
- 2026-09-06 shipped: the roster and the Landlord (9ecd39a)
- 2026-09-06 signoff: boss beatable, demands all verbs (Marcos; inferred: M7 started the same day; the three-to-eight-attempts figure has no recorded playtest)

## M7: Slice polish

**Deliverable.** The balance pass, the sound, the juice, the menus and settings, save and load hardened, a title screen with three slots, and a first art pass.

**Retires.** Whether a stranger can run it start to finish without guidance.

**Calls.** sound-designer, composer, ui-artist, vfx-artist

**Acceptance.**

- [x] `game/src/ui/hud/hud.gd` exists
- [x] `game/src/ui/title/title_screen.gd` exists
- [x] `game/src/core/settings.gd` exists
- [x] at least 40 of `game/assets/audio/sfx/*.wav`  (63 found)
- [x] at least 5 of `game/assets/audio/music/*.tres`  (5 found)
- [x] at least 20 of `game/assets/audio/music/*/*.ogg`  (35 found)
- [x] a commit matching `^feat\(m7\):`  (bf64f8f 2026-09-06)
- [ ] sign-off: "external playtesters run it start to finish without guidance"  (no signoff row in log.md quotes it)

**Log.**

- 2026-09-06 shipped: art, audio, juice, title screen and settings (bf64f8f)
- 2026-09-16 note: the music check was a stale glob, not a missing track: it looked for audio/music/*.ogg and the composer writes a folder per track with a stem per layer (5 tres and 35 stems were there all along; the check is now *.tres and */*.ogg)

## M8: The look

**Deliverable.** The hi-bit art pass on the slice: every character as a baked sheet, every room dressed and lit from its concept at the figure's scale, the effects baked like the characters, the HUD in the palette, all reviewed against the bible.

**Retires.** Whether generated stills, rigs and bakes can hold one style across a cast and a district without a hand-drawn pass.

**Calls.** character-designer, concept-artist, environment-artist, level-artist, vfx-artist, ui-artist, art-director

**Acceptance.**

- [x] `docs/art/direction.md` exists
- [x] at least 9 of `game/assets/sprites/*.png`  (9 found)
- [x] at least 9 of `game/tools/art/cast/*.json`  (9 found)
- [x] `game/tools/art/sets/unit_14c.json` exists
- [x] at least 34 of `game/tools/stacks/*.dress.json`  (34 found)
- [x] at least 3 of `game/tools/art/vfx/*.json`  (3 found)
- [ ] sign-off: "the district reads as one style at 1:1"  (no signoff row in log.md quotes it)

**Log.**

- 2026-09-06 decided: the cast look sheet approved: skin tone, heights, chrome legs (docs/art/cast.md)
- 2026-09-07 note: pipeline v2 and seven character sheets: Dani, the Scav, the Elite, the drone, the Riot unit, the Landlord, Stitch and Marisol (2e981c1 to 9b1c445)
- 2026-09-07 note: 14-C dressed at the figure's scale from its concept; the camera to 1.5x bounded to the air (142b790, 1de7375, 7915d35, cb45ade)
- 2026-09-08 note: the vfx pass: spark.hit, dust.land and burst.die baked through the character bake, one shot per family (uncommitted in game/tools/art/vfx and game/assets/fx)
- 2026-09-16 note: the district is lit from a vocabulary, 34 dress files; it still misses the budget and cannot meet it with light (the generic back planes are 0.0025-0.0103 median luma against back_unit_14c's 0.0297; lighting.md step 2 says a wall that stays black is painted too dark, and that is the environment-artist's)

## M9: Go or no-go

**Deliverable.** The slice in the hands of three to five people who owe nothing, and the decision to continue to V2 or not.

**Retires.** Whether the game is worth building: the loop is readable, the pull works, the verbs are distinguishable, somebody wants more.

**Calls.** shipper

**Acceptance.**

- [ ] sign-off: "testers finish without being told what to do"  (no signoff row in log.md quotes it)
- [ ] sign-off: "a tester asks how do I get up there"  (no signoff row in log.md quotes it)
- [ ] sign-off: "testers can say why they would pick melee, ranged or hacks"  (no signoff row in log.md quotes it)
- [ ] sign-off: "someone asks when they can play more"  (no signoff row in log.md quotes it)

**Log.**

- 2026-09-16 note: the playtest build is made: v0.1.0, windows and linux, with a card and a page (f31759e; dist/0.1.0/receipt.json. Not in anybody's hands yet, so no shipped row)

## Across the plan

- 2026-08-27 decided: base viewport 1920x1080, canvas_items stretch; the pixel-art defaults dropped (769a0fd; texture filter stays linear until the art call is made)
- 2026-08-27 deferred: the double jump: two or three visible ledges the player never reaches in V1 (DESIGN.md section 1: the metroidvania promise, paid in V2)
- 2026-08-28 decided: credits-only currency; four clothing slots (ee69a72)
- 2026-08-28 deferred: independent builds, manual stat allocation and respec (8d8a465: V1 is one intertwined kit; the rework is priced into V2)
- 2026-08-30 decided: stat scaling as a soft-capped multiplier; DEF as flat subtraction with a floor at 1; DEF from gear only (bfaed00, c321d98, 46778cf)
- 2026-08-31 decided: the hook: firmware paywalls, the unlock is stolen authority; credits never touch an ability (e5d3024)
- 2026-09-05 decided: ground dash from the start; the air dash is the Sidewinder, the wall jump the Mag-Hook (7595dc2)
- 2026-09-06 note: dash i-frames still a playtest call (config flag, off)
- 2026-09-06 decided: hi-bit pixel art, the REPLACED and The Last Night band (DESIGN.md section 7; docs/art/refs/README.md)
- 2026-09-14 note: the plan written as data after the fact (plan/plan.json; the sign-offs before this row are inferred from the next milestone starting)
