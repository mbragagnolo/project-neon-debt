# Neon Debt v0.1.0

2026-09-16. The first release: 119 commits, 38 logged events from 2026-08-27.

## What shipped

- **M0** Godot project skeleton, signal bus, save state, headless test CI -- f43f7f5
- **M1** player controller, movement states, and the platforming gym -- df218ee; Godot to 4.7.2 first (8efbcd9) so the controller is never written against an engine to migrate off
- **M2** the damage pipeline, the first two verbs, and a lab to feel them in -- 1b69bed
- **M3** stats, the XP curve, the ten items, the equip screen, pickups, save -- dbb68c9 (the merge; the work is 09-03)
- **M4** the three programs, RAM, the quickslot, and the Breach door -- 1a603ca
- **M5** The Stacks: 34 rooms, doors, terminals, the map, the hub and the quest -- a57c598
- **M6** the roster and the Landlord -- 9ecd39a
- **M7** art, audio, juice, title screen and settings -- bf64f8f
- **M5** three one-line repairs and the Gut's way back; 34 rooms solved with the full kit in the locked order -- 47311a5, ea517f4, bf61ac5

## Signed off

- **M1** moving around an empty room is fun -- Marcos; inferred: M1 merged to main (b675ab1) and M2 started the same day
- **M2** fighting three Scavs is legible and satisfying -- Marcos; inferred: the tuning pass closed (8135b36, 4e8b424), merged (9134bd9), M3 started the same day
- **M3** equipping better gear visibly changes combat math; HUD shows it -- Marcos; inferred: merged and M4 started the same day
- **M4** all three combat verbs used naturally in one fight -- Marcos; inferred: M5 started the next day
- **M5** can play the loop: explore, unlock, open what it gates, gear up, level, complete the quest -- Marcos; inferred: M6 started the same day
- **M6** boss beatable, demands all verbs -- Marcos; inferred: M7 started the same day; the three-to-eight-attempts figure has no recorded playtest

## Reopened

- **M5** the slice could not be played past its fourth room -- the level-designer's solver: three passages the body cannot fit through, the catwalks gate crossable with the starting kit, the Gut a trap before Breach; the room-level tests could not see any of it

## Cut down

- **M3** weapon modifiers -- 6938ffc then f630d1a: weapons carry flat stats only, clothing keeps one modifier per piece
- **M4** Static Wall -- 47c1b18: Firewall replaces it and is the starter hack; the corp protects its collateral

## Deferred

- the double jump: two or three visible ledges the player never reaches in V1 -- DESIGN.md section 1: the metroidvania promise, paid in V2
- independent builds, manual stat allocation and respec -- 8d8a465: V1 is one intertwined kit; the rework is priced into V2
- **M6** drop tables -- 1f63bc8: the vendor refill and the melee interlock cover ammo; V1 ships no drops
- **M2** the heavy stagger threshold -- 599de5d: set enemy DEF last, after the weapons are tuned; done in M6

## Decided

- base viewport 1920x1080, canvas_items stretch; the pixel-art defaults dropped -- 769a0fd; texture filter stays linear until the art call is made
- credits-only currency; four clothing slots -- ee69a72
- stat scaling as a soft-capped multiplier; DEF as flat subtraction with a floor at 1; DEF from gear only -- bfaed00, c321d98, 46778cf
- the hook: firmware paywalls, the unlock is stolen authority; credits never touch an ability -- e5d3024
- ground dash from the start; the air dash is the Sidewinder, the wall jump the Mag-Hook -- 7595dc2
- **M5** death penalty: respawn at the last care terminal, the room reloads, keep everything -- DESIGN.md section 7
- hi-bit pixel art, the REPLACED and The Last Night band -- DESIGN.md section 7; docs/art/refs/README.md
- **M8** the cast look sheet approved: skin tone, heights, chrome legs -- docs/art/cast.md

## Also

- **M2** wrench to 1.6/s: the first tuning number closed by feel (note) -- 2e6c5fd
- dash i-frames still a playtest call (note) -- config flag, off
- **M8** pipeline v2 and seven character sheets: Dani, the Scav, the Elite, the drone, the Riot unit, the Landlord, Stitch and Marisol (note) -- 2e981c1 to 9b1c445
- **M8** 14-C dressed at the figure's scale from its concept; the camera to 1.5x bounded to the air (note) -- 142b790, 1de7375, 7915d35, cb45ade
- **M8** the vfx pass: spark.hit, dust.land and burst.die baked through the character bake, one shot per family (note) -- uncommitted in game/tools/art/vfx and game/assets/fx
- the plan written as data after the fact (note) -- plan/plan.json; the sign-offs before this row are inferred from the next milestone starting
- **M7** the music check was a stale glob, not a missing track: it looked for audio/music/*.ogg and the composer writes a folder per track with a stem per layer (note) -- 5 tres and 35 stems were there all along; the check is now *.tres and */*.ogg
- **M8** the district is lit from a vocabulary, 34 dress files; it still misses the budget and cannot meet it with light (note) -- the generic back planes are 0.0025-0.0103 median luma against back_unit_14c's 0.0297; lighting.md step 2 says a wall that stays black is painted too dark, and that is the environment-artist's

## Not in the log

The log is the record; these are gaps in it, not in the build.

- M8 (The look) has no shipped row in the log
- M9 (Go or no-go) has no shipped row in the log
