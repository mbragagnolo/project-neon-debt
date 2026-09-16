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
