# Pass log

One row per event; the grammar is the producer skill's templates/log.md.
Rows before 2026-09-14 were reconstructed from the git history and the
docs' status lines after the slice shipped: a shipped row's why is the
commit, and a signoff row whose why says "inferred" has no recorded
playtest behind it, only the fact that the next milestone started.

| date | milestone | kind | what | why |
|---|---|---|---|---|
| 2026-08-27 | M0 | shipped | Godot project skeleton, signal bus, save state, headless test CI | f43f7f5 |
| 2026-08-27 | - | decided | base viewport 1920x1080, canvas_items stretch; the pixel-art defaults dropped | 769a0fd; texture filter stays linear until the art call is made |
| 2026-08-27 | - | deferred | the double jump: two or three visible ledges the player never reaches in V1 | DESIGN.md section 1: the metroidvania promise, paid in V2 |
| 2026-08-27 | M1 | shipped | player controller, movement states, and the platforming gym | df218ee; Godot to 4.7.2 first (8efbcd9) so the controller is never written against an engine to migrate off |
| 2026-08-28 | - | decided | credits-only currency; four clothing slots | ee69a72 |
| 2026-08-28 | - | deferred | independent builds, manual stat allocation and respec | 8d8a465: V1 is one intertwined kit; the rework is priced into V2 |
| 2026-08-30 | - | decided | stat scaling as a soft-capped multiplier; DEF as flat subtraction with a floor at 1; DEF from gear only | bfaed00, c321d98, 46778cf |
| 2026-08-30 | M3 | scope-cut | weapon modifiers | 6938ffc then f630d1a: weapons carry flat stats only, clothing keeps one modifier per piece |
| 2026-08-31 | M4 | scope-cut | Static Wall | 47c1b18: Firewall replaces it and is the starter hack; the corp protects its collateral |
| 2026-08-31 | M6 | deferred | drop tables | 1f63bc8: the vendor refill and the melee interlock cover ammo; V1 ships no drops |
| 2026-08-31 | - | decided | the hook: firmware paywalls, the unlock is stolen authority; credits never touch an ability | e5d3024 |
| 2026-09-02 | M1 | signoff | moving around an empty room is fun | Marcos; inferred: M1 merged to main (b675ab1) and M2 started the same day |
| 2026-09-02 | M2 | shipped | the damage pipeline, the first two verbs, and a lab to feel them in | 1b69bed |
| 2026-09-02 | M2 | note | wrench to 1.6/s: the first tuning number closed by feel | 2e6c5fd |
| 2026-09-03 | M2 | deferred | the heavy stagger threshold | 599de5d: set enemy DEF last, after the weapons are tuned; done in M6 |
| 2026-09-03 | M2 | signoff | fighting three Scavs is legible and satisfying | Marcos; inferred: the tuning pass closed (8135b36, 4e8b424), merged (9134bd9), M3 started the same day |
| 2026-09-05 | M3 | shipped | stats, the XP curve, the ten items, the equip screen, pickups, save | dbb68c9 (the merge; the work is 09-03) |
| 2026-09-05 | M3 | signoff | equipping better gear visibly changes combat math; HUD shows it | Marcos; inferred: merged and M4 started the same day |
| 2026-09-05 | M4 | shipped | the three programs, RAM, the quickslot, and the Breach door | 1a603ca |
| 2026-09-05 | - | decided | ground dash from the start; the air dash is the Sidewinder, the wall jump the Mag-Hook | 7595dc2 |
| 2026-09-06 | M4 | signoff | all three combat verbs used naturally in one fight | Marcos; inferred: M5 started the next day |
| 2026-09-06 | M5 | shipped | The Stacks: 34 rooms, doors, terminals, the map, the hub and the quest | a57c598 |
| 2026-09-06 | M5 | decided | death penalty: respawn at the last care terminal, the room reloads, keep everything | DESIGN.md section 7 |
| 2026-09-06 | M5 | signoff | can play the loop: explore, unlock, open what it gates, gear up, level, complete the quest | Marcos; inferred: M6 started the same day |
| 2026-09-06 | M6 | shipped | the roster and the Landlord | 9ecd39a |
| 2026-09-06 | M6 | signoff | boss beatable, demands all verbs | Marcos; inferred: M7 started the same day; the three-to-eight-attempts figure has no recorded playtest |
| 2026-09-06 | M7 | shipped | art, audio, juice, title screen and settings | bf64f8f |
| 2026-09-06 | - | note | dash i-frames still a playtest call | config flag, off |
| 2026-09-06 | - | decided | hi-bit pixel art, the REPLACED and The Last Night band | DESIGN.md section 7; docs/art/refs/README.md |
| 2026-09-06 | M8 | decided | the cast look sheet approved: skin tone, heights, chrome legs | docs/art/cast.md |
| 2026-09-07 | M8 | note | pipeline v2 and seven character sheets: Dani, the Scav, the Elite, the drone, the Riot unit, the Landlord, Stitch and Marisol | 2e981c1 to 9b1c445 |
| 2026-09-07 | M8 | note | 14-C dressed at the figure's scale from its concept; the camera to 1.5x bounded to the air | 142b790, 1de7375, 7915d35, cb45ade |
| 2026-09-08 | M5 | reopened | the slice could not be played past its fourth room | the level-designer's solver: three passages the body cannot fit through, the catwalks gate crossable with the starting kit, the Gut a trap before Breach; the room-level tests could not see any of it |
| 2026-09-08 | M5 | shipped | three one-line repairs and the Gut's way back; 34 rooms solved with the full kit in the locked order | 47311a5, ea517f4, bf61ac5 |
| 2026-09-08 | M8 | note | the vfx pass: spark.hit, dust.land and burst.die baked through the character bake, one shot per family | uncommitted in game/tools/art/vfx and game/assets/fx |
| 2026-09-14 | - | note | the plan written as data after the fact | plan/plan.json; the sign-offs before this row are inferred from the next milestone starting |
| 2026-09-16 | M7 | note | the music check was a stale glob, not a missing track: it looked for audio/music/*.ogg and the composer writes a folder per track with a stem per layer | 5 tres and 35 stems were there all along; the check is now *.tres and */*.ogg |
| 2026-09-16 | M8 | note | the district is lit from a vocabulary, 34 dress files; it still misses the budget and cannot meet it with light | the generic back planes are 0.0025-0.0103 median luma against back_unit_14c's 0.0297; lighting.md step 2 says a wall that stays black is painted too dark, and that is the environment-artist's |
| 2026-09-16 | M9 | note | the playtest build is made: v0.1.0, windows and linux, with a card and a page | f31759e; dist/0.1.0/receipt.json. Not in anybody's hands yet, so no shipped row |
