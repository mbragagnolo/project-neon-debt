# Integrator report

One section per run, newest last. Written by the godot-integrator scripts; do not edit.

## 2026-09-15 08:06 imports.py --project F:/Projects/Coding Projects/project-neon-debt/game

imports.py: 167 sidecars checked, 0 fixed, 0 never imported; 0 fail, 0 warn, 1 note, 0 written

- NOTE skipped 2 folders under a .gdignore, as the engine does: tools/art/source, tools/art/work

## 2026-09-15 08:06 frames.py --project F:/Projects/Coding Projects/project-neon-debt/game

frames.py: 8 clip tables against 9 targets; 0 fail, 0 warn, 0 note, 0 written


## 2026-09-15 08:06 tables.py --project F:/Projects/Coding Projects/project-neon-debt/game

tables.py: 1 tables; 0 fail, 0 warn, 3 note, 0 written

- NOTE enemies/drone: kept from the file, not in the contract: patrol_speed, patrol_range, patrol_pause, chase_speed, lunge_range, windup_time, lunge_speed, lunge_time, recover_time, lunge_cooldown, attack_size, attack_offset, lunge_knockback
- NOTE enemies/landlord: kept from the file, not in the contract: patrol_speed, patrol_range, patrol_pause, projectile_knockback
- NOTE enemies/player.json: no `source.tres` in player.json; not a EnemyConfig contract, skipped

## 2026-09-15 08:06 audio.py --project F:/Projects/Coding Projects/project-neon-debt/game

audio.py: 45 sound ids, 2 buses; 0 fail, 4 warn, 2 note, 0 written

- WARN sfx: assets/audio/sfx/credits.wav is played by no line of code
- WARN sfx: assets/audio/sfx/door.wav is played by no line of code
- WARN sfx: assets/audio/sfx/enemy_die.wav is played by no line of code
- WARN sfx: assets/audio/sfx/hit.wav is played by no line of code
- NOTE music: the loop is set in src/audio/music.gd, not in the .import (loop=false there is right)
- NOTE events: no table at ../bible/events.json; the sound map is the code's

## 2026-09-15 08:06 theme.py --project F:/Projects/Coding Projects/project-neon-debt/game

theme.py: 4 styleboxes, 5 types; 0 fail, 1 warn, 0 note, 0 written

- WARN nine-patch panel_frame: no script or scene under ['src', 'rooms'] names res://assets/ui/panel_frame.png

## 2026-09-15 18:42 tables.py --project F:/Projects/Coding Projects/project-neon-debt/game --only enemies --write

tables.py: 1 tables; 0 fail, 0 warn, 4 note, 1 written

- NOTE enemies/drone: kept from the file, not in the contract: patrol_speed, patrol_range, patrol_pause, chase_speed, lunge_range, windup_time, lunge_speed, lunge_time, recover_time, lunge_cooldown, attack_size, attack_offset, lunge_knockback
- NOTE enemies/landlord: kept from the file, not in the contract: patrol_speed, patrol_range, patrol_pause, projectile_knockback
- NOTE enemies/landlord: src/enemies/boss_landlord/landlord.tscn Health updated: max_hp 240 -> 270, defense 4 -> 5
- NOTE enemies/player.json: no `source.tres` in player.json; not a EnemyConfig contract, skipped
- wrote `src/enemies/boss_landlord/landlord.tscn`

## 2026-09-15 20:22 audio.py --project F:/Projects/Coding Projects/project-neon-debt/game

audio.py: 45 sound ids, 2 buses; 0 fail, 6 warn, 1 note, 0 written

- WARN sfx: assets/audio/sfx/credits.wav is played by no line of code
- WARN sfx: assets/audio/sfx/door.wav is played by no line of code
- WARN sfx: assets/audio/sfx/enemy_die.wav is played by no line of code
- WARN sfx: assets/audio/sfx/hit.wav is played by no line of code
- WARN sfx: assets/audio/sfx/hit_2.wav is played by no line of code
- WARN sfx: assets/audio/sfx/hit_3.wav is played by no line of code
- NOTE music: the loop is set in src/audio/music.gd, not in the .import (loop=false there is right)

## 2026-09-15 23:31 music.py --project F:/Projects/Coding Projects/project-neon-debt/game --write --import

music.py: 5 tracks, 35 stems, 0 missing, 0 import params wrong, 6 written; 0 fail, 0 warn, 36 note, 41 written

- NOTE music: assets/audio/music/boss/drone.ogg.import: loop=false wanted true, bpm=0 wanted 128, beat_count=0 wanted 64, fixed
- NOTE music: assets/audio/music/boss/tick.ogg.import: loop=false wanted true, bpm=0 wanted 128, beat_count=0 wanted 64, fixed
- NOTE music: assets/audio/music/boss/kick.ogg.import: loop=false wanted true, bpm=0 wanted 128, beat_count=0 wanted 64, fixed
- NOTE music: assets/audio/music/boss/snare.ogg.import: loop=false wanted true, bpm=0 wanted 128, beat_count=0 wanted 64, fixed
- NOTE music: assets/audio/music/boss/hats.ogg.import: loop=false wanted true, bpm=0 wanted 128, beat_count=0 wanted 64, fixed
- NOTE music: assets/audio/music/boss/bass.ogg.import: loop=false wanted true, bpm=0 wanted 128, beat_count=0 wanted 64, fixed
- NOTE music: assets/audio/music/boss/stabs.ogg.import: loop=false wanted true, bpm=0 wanted 128, beat_count=0 wanted 64, fixed
- NOTE music: assets/audio/music/boss/riser.ogg.import: loop=false wanted true, bpm=0 wanted 128, beat_count=0 wanted 64, fixed
- NOTE music: assets/audio/music/boss/lead.ogg.import: loop=false wanted true, bpm=0 wanted 128, beat_count=0 wanted 64, fixed
- NOTE music: assets/audio/music/boss/heart.ogg.import: loop=false wanted true, bpm=0 wanted 128, beat_count=0 wanted 64, fixed
- NOTE music: assets/audio/music/gut/drone.ogg.import: loop=false wanted true, bpm=0 wanted 60, beat_count=0 wanted 32, fixed
- NOTE music: assets/audio/music/gut/pad.ogg.import: loop=false wanted true, bpm=0 wanted 60, beat_count=0 wanted 32, fixed
- NOTE music: assets/audio/music/gut/throb.ogg.import: loop=false wanted true, bpm=0 wanted 60, beat_count=0 wanted 32, fixed
- NOTE music: assets/audio/music/gut/steam.ogg.import: loop=false wanted true, bpm=0 wanted 60, beat_count=0 wanted 32, fixed
- NOTE music: assets/audio/music/gut/clanks.ogg.import: loop=false wanted true, bpm=0 wanted 60, beat_count=0 wanted 32, fixed
- NOTE music: assets/audio/music/gut/hammer.ogg.import: loop=false wanted true, bpm=0 wanted 60, beat_count=0 wanted 32, fixed
- NOTE music: assets/audio/music/gut/heart.ogg.import: loop=false wanted true, bpm=0 wanted 60, beat_count=0 wanted 32, fixed
- NOTE music: assets/audio/music/roof/wind.ogg.import: loop=false wanted true, bpm=0 wanted 64, beat_count=0 wanted 32, fixed
- NOTE music: assets/audio/music/roof/pad.ogg.import: loop=false wanted true, bpm=0 wanted 64, beat_count=0 wanted 32, fixed
- NOTE music: assets/audio/music/roof/bells.ogg.import: loop=false wanted true, bpm=0 wanted 64, beat_count=0 wanted 32, fixed
- NOTE music: assets/audio/music/roof/siren.ogg.import: loop=false wanted true, bpm=0 wanted 64, beat_count=0 wanted 32, fixed
- NOTE music: assets/audio/music/roof/drive.ogg.import: loop=false wanted true, bpm=0 wanted 64, beat_count=0 wanted 32, fixed
- NOTE music: assets/audio/music/roof/heart.ogg.import: loop=false wanted true, bpm=0 wanted 64, beat_count=0 wanted 32, fixed
- NOTE music: assets/audio/music/stacks/pad.ogg.import: loop=false wanted true, bpm=0 wanted 68, beat_count=0 wanted 32, fixed
- NOTE music: assets/audio/music/stacks/rain.ogg.import: loop=false wanted true, bpm=0 wanted 68, beat_count=0 wanted 32, fixed
- NOTE music: assets/audio/music/stacks/hum.ogg.import: loop=false wanted true, bpm=0 wanted 68, beat_count=0 wanted 32, fixed
- NOTE music: assets/audio/music/stacks/sub.ogg.import: loop=false wanted true, bpm=0 wanted 68, beat_count=0 wanted 32, fixed
- NOTE music: assets/audio/music/stacks/thump.ogg.import: loop=false wanted true, bpm=0 wanted 68, beat_count=0 wanted 32, fixed
- NOTE music: assets/audio/music/stacks/blips.ogg.import: loop=false wanted true, bpm=0 wanted 68, beat_count=0 wanted 32, fixed
- NOTE music: assets/audio/music/stacks/pulse.ogg.import: loop=false wanted true, bpm=0 wanted 68, beat_count=0 wanted 32, fixed
- NOTE music: assets/audio/music/stacks/heart.ogg.import: loop=false wanted true, bpm=0 wanted 68, beat_count=0 wanted 32, fixed
- NOTE music: assets/audio/music/title/pad.ogg.import: loop=false wanted true, bpm=0 wanted 60, beat_count=0 wanted 32, fixed
- NOTE music: assets/audio/music/title/rain.ogg.import: loop=false wanted true, bpm=0 wanted 60, beat_count=0 wanted 32, fixed
- NOTE music: assets/audio/music/title/theme.ogg.import: loop=false wanted true, bpm=0 wanted 60, beat_count=0 wanted 32, fixed
- NOTE music: assets/audio/music/title/sub.ogg.import: loop=false wanted true, bpm=0 wanted 60, beat_count=0 wanted 32, fixed
- NOTE engine import ran (exit 0, 0 error lines)
- wrote `assets/audio/music/boss/drone.ogg.import`
- wrote `assets/audio/music/boss/tick.ogg.import`
- wrote `assets/audio/music/boss/kick.ogg.import`
- wrote `assets/audio/music/boss/snare.ogg.import`
- wrote `assets/audio/music/boss/hats.ogg.import`
- wrote `assets/audio/music/boss/bass.ogg.import`
- wrote `assets/audio/music/boss/stabs.ogg.import`
- wrote `assets/audio/music/boss/riser.ogg.import`
- wrote `assets/audio/music/boss/lead.ogg.import`
- wrote `assets/audio/music/boss/heart.ogg.import`
- wrote `assets/audio/music/boss.tres`
- wrote `assets/audio/music/gut/drone.ogg.import`
- wrote `assets/audio/music/gut/pad.ogg.import`
- wrote `assets/audio/music/gut/throb.ogg.import`
- wrote `assets/audio/music/gut/steam.ogg.import`
- wrote `assets/audio/music/gut/clanks.ogg.import`
- wrote `assets/audio/music/gut/hammer.ogg.import`
- wrote `assets/audio/music/gut/heart.ogg.import`
- wrote `assets/audio/music/gut.tres`
- wrote `assets/audio/music/roof/wind.ogg.import`
- wrote `assets/audio/music/roof/pad.ogg.import`
- wrote `assets/audio/music/roof/bells.ogg.import`
- wrote `assets/audio/music/roof/siren.ogg.import`
- wrote `assets/audio/music/roof/drive.ogg.import`
- wrote `assets/audio/music/roof/heart.ogg.import`
- wrote `assets/audio/music/roof.tres`
- wrote `assets/audio/music/stacks/pad.ogg.import`
- wrote `assets/audio/music/stacks/rain.ogg.import`
- wrote `assets/audio/music/stacks/hum.ogg.import`
- wrote `assets/audio/music/stacks/sub.ogg.import`
- wrote `assets/audio/music/stacks/thump.ogg.import`
- wrote `assets/audio/music/stacks/blips.ogg.import`
- wrote `assets/audio/music/stacks/pulse.ogg.import`
- wrote `assets/audio/music/stacks/heart.ogg.import`
- wrote `assets/audio/music/stacks.tres`
- wrote `assets/audio/music/title/pad.ogg.import`
- wrote `assets/audio/music/title/rain.ogg.import`
- wrote `assets/audio/music/title/theme.ogg.import`
- wrote `assets/audio/music/title/sub.ogg.import`
- wrote `assets/audio/music/title.tres`
- wrote `src/audio/music_table.gd`

## 2026-09-15 23:31 music.py --project F:/Projects/Coding Projects/project-neon-debt/game

music.py: 5 tracks, 35 stems, 0 missing, 0 import params wrong, 0 written; 0 fail, 0 warn, 0 note, 0 written


## 2026-09-15 23:31 audio.py --project F:/Projects/Coding Projects/project-neon-debt/game

audio.py: 45 sound ids, 2 buses; 4 fail, 6 warn, 0 note, 0 written

- WARN sfx: assets/audio/sfx/credits.wav is played by no line of code
- WARN sfx: assets/audio/sfx/door.wav is played by no line of code
- WARN sfx: assets/audio/sfx/enemy_die.wav is played by no line of code
- WARN sfx: assets/audio/sfx/hit.wav is played by no line of code
- WARN sfx: assets/audio/sfx/hit_2.wav is played by no line of code
- WARN sfx: assets/audio/sfx/hit_3.wav is played by no line of code
- FAIL music: code plays `collections` (src/audio/music_table.gd) and assets/audio/music/collections.tres does not exist
- FAIL music: code plays `mezz` (src/audio/music_table.gd) and assets/audio/music/mezz.tres does not exist
- FAIL music: code plays `residential` (src/audio/music_table.gd) and assets/audio/music/residential.tres does not exist
- FAIL music: code plays `shaft` (src/audio/music_table.gd) and assets/audio/music/shaft.tres does not exist

## 2026-09-15 23:31 audio.py --project F:/Projects/Coding Projects/project-neon-debt/game

audio.py: 45 sound ids, 2 buses; 0 fail, 6 warn, 0 note, 0 written

- WARN sfx: assets/audio/sfx/credits.wav is played by no line of code
- WARN sfx: assets/audio/sfx/door.wav is played by no line of code
- WARN sfx: assets/audio/sfx/enemy_die.wav is played by no line of code
- WARN sfx: assets/audio/sfx/hit.wav is played by no line of code
- WARN sfx: assets/audio/sfx/hit_2.wav is played by no line of code
- WARN sfx: assets/audio/sfx/hit_3.wav is played by no line of code

## 2026-09-15 23:39 music.py --project F:/Projects/Coding Projects/project-neon-debt/game --import

music.py: 5 tracks, 35 stems, 0 missing, 0 import params wrong, 0 written; 0 fail, 0 warn, 1 note, 0 written

- NOTE engine import ran (exit 0, 0 error lines)

