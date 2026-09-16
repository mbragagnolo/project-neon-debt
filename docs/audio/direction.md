# Audio direction — built (M7)

**Status: built.** Every effect in `game/assets/audio/sfx/` is rendered by
the kiln sound-designer from `audio/sfx/recipes.py` (the recipes; the synth
lives in the skill) and mastered to a loudness class per sound
(`audio/sfx/sfx.json` is the table: event, class, variations, files;
`audio/sfx/runs/<date>/report.md` has every number). The music is rendered by
the kiln composer from `audio/music/tracks/*.json` (a track as data:
layers of patterns and textures on `audio/music/instruments.py`, the tune
in `audio/music/motifs.json`) into stems the engine layers by state;
`audio/music/music.json` is the table, `audio/music/runs/<date>/report.md`
has every number.
There are no found samples: a sound is a recipe, and a change to one is a
diff. `bible/events.json` maps every event key to its sound and effect.

## The sound, in one paragraph

Short, dry, a little crunchy. Square and saw waves through a lowpass,
noise bursts for impacts, a bit-crush on anything that dies — the sounds
agree with the pixel art. Menus blip, hacks shimmer, the Landlord roars
through a detuned saw. Music is a bed, not a song: a breathing pad under a
sub pulse with the district's noises on top, a pulse that comes in while
an enemy is on you and a heartbeat under 30 % HP, until the boss, whose
floor is a drone and a clock until his bar appears and a 128 BPM pulse
with a riser that rolls into the loop point after, with Dani's theme on a
square lead in his second phase.

## Buses

`default_bus_layout.tres`: **Master → Music, SFX**. `Settings` writes the
three volumes there and to `user://settings.cfg`.

## Effects (`Sfx` autoload, `src/audio/sfx.gd`)

`Sfx.play(id)` plays `assets/audio/sfx/<id>.wav` (or one of its variations
`<id>_2.wav`, `<id>_3.wav`, picked at random, for the frequent sounds) from a
pool of 16 players with a 6 % pitch wobble and a 35 ms floor between two
plays of the same id. Nobody in the game calls it for gameplay: `Sfx` listens to the
signal bus and answers.

| Signal | Sound |
|---|---|
| `player_action` jump / wall_jump / dash / land / swing | `jump`, `wall_jump`, `dash`, `land`, `swing` |
| `player_action` shoot_bolt / shoot_nail / shoot_rivet | `shoot`, `shoot_nail`, `shoot_rivet` |
| `player_action` hurt / hurt_guard / hazard | `hurt`, `hit_guard`, `hazard` |
| `damage_dealt` (to an enemy) | `hit`, or `hit_heavy` from 12 damage |
| `enemy_died` | `enemy_die`, `mech_die` for the drone and the Riot unit |
| `sfx_requested` from the states | `tell` (windup), `lunge`, `stun`, `drone_shot`, `slam`, `beam_charge`, `beam_fire` |
| `boss_phase_changed`, `boss_defeated` | `roar`; `roar` + `slam` |
| `hack_cast` firewall / overload / breach | `hack_guard`, `hack_burst`, `hack_pulse` |
| `hack_failed` | `deny` |
| `hack_acquired`, `ability_granted` | `hack_acquire` |
| `item_picked_up`, `stat_up_acquired`, `quest_item_acquired`, `quest_completed` | `pickup`, `stat_up`, `quest`, `quest` |
| `level_gained`, `save_point_activated`, `door_opened`, `room_entered` | `level_up`, `save`, `breach`, `door_pass` |
| `toast_requested`, `bark_requested`, `shop_purchased`, `item_equipped`, `player_died` | `toast`, `bark`, `buy`, `ui_confirm`, `die` |

Menus call `Sfx.play` directly for `ui_open`, `ui_close`, `ui_move`,
`ui_confirm`, `ui_back`, `text` (a dialogue page), `deny` (a purchase that
fails), `title_start`.

`Events.player_action(action, position, direction)` and
`Events.sfx_requested(id, position)` are the two M7 signals; the player
emits the first from its verbs, the enemy states the second from their
tells.

## Music (`Music` autoload, `src/audio/music.gd`)

Every track is an `AudioStreamSynchronized` in `assets/audio/music/`
(`<track>.tres`, written by the godot-integrator's `music.py` from the
composer's table) whose stems (`<track>/<layer>.ogg`, looping, all the
loop's exact length) play from one start; a stem is either always on
(`base`) or belongs to a state the autoload raises, fading in and out
over 1.2 s. Tracks crossfade over 1.8 s, one at a time. The table the
autoload reads is the generated `src/audio/music_table.gd`.

| Track | Where (the moods, `bible/moods.json`) | Length | Base | `combat` | `low` | `fight` | `phase2` |
|---|---|---|---|---|---|---|---|
| `stacks` | residential, mezz, shaft | 28.2 s, 68 BPM | pad, rain, hum, sub, thump, blips | pulse | heart | | |
| `gut` | gut | 32 s, 60 BPM | drone, pad, throb, steam, clanks | hammer | heart | | |
| `roof` | roof | 30 s, 64 BPM | wind, pad, bells, siren | drive | heart | | |
| `boss` | collections | 30 s, 128 BPM | drone, tick | | heart | kick, snare, hats, bass, stabs, riser | lead |
| `title` | title, the ending | 32 s, 60 BPM | pad, rain, theme, sub | | | | |

`room_entered` picks by the room's `style` in `world_graph.tres` through
the moods table; `boss_hp_changed` takes the boss track over and raises
`fight`, `boss_phase_changed` raises `phase2`, `boss_defeated` hands back
to `title`. `combat` is the autoload's own: it polls the enemies group
four times a second for one in Chase, Windup, Lunge, Aim or Track and
holds 3 s after the last; `low` follows `hp_changed` at 30 %. Dani's
theme is one motif, played by the title at a note per two beats and by
the boss's lead at 128 BPM. Every stem loops on its import flag; the
composer verifies every seam on the decoded file, and the full mixes it
writes to `audio/music/mix/` (not engine files) are the beds the
sound-designer measures the effects over.

## Regenerating

```
python <kiln>/skills/sound-designer/scripts/master.py --project .   # 49 effects, 63 files, the report
python <kiln>/skills/composer/scripts/render.py --project .          # 5 tracks, 35 stems, the report, ~50 s
python <kiln>/skills/godot-integrator/scripts/music.py --project game --write --import   # the .tres, the table script, the imports
```

then let Godot re-import. Recipes and tracks are deterministic (seeded
noise), so a regenerated file renders the same sound unless its recipe or
its track changed, and each report's first section says which did.
