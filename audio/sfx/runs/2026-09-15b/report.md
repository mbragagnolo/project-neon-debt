# Sound report, 2026-09-15b

49 sounds, 63 files in `game/assets/audio/sfx`, ceiling -1 dBTP, 5 beds auditioned. The recipes: `audio/sfx/recipes.py`.

## Since the last run

- `bark` changed: -19.9 -> -20 LUFS
- `dash` changed: -18.1 -> -17 LUFS, 0.20 -> 0.22 s
- `drone_shot` changed: -16.8 -> -16.2 LUFS
- `hazard` changed: -15.2 -> -15 LUFS
- `hit` changed: -17.2 -> -14.3 LUFS
- `hit_guard` changed: -18.2 -> -14 LUFS
- `land` changed: -19.1 -> -14.2 LUFS, 0.11 -> 0.14 s
- `lunge` changed: -20.9 -> -14.8 LUFS, 0.18 -> 0.20 s
- `mech_die` changed: -12.9 -> -12.3 LUFS
- `shoot_nail` changed: -21.8 -> -16 LUFS, 0.06 -> 0.07 s
- `swing` changed: -21.9 -> -17 LUFS, 0.16 -> 0.18 s
- `ui_back` changed: -18 -> -17 LUFS
- `ui_close` changed: -18.6 -> -17 LUFS
- `ui_confirm` changed: -18 -> -17 LUFS
- `ui_move` changed: -18 -> -17 LUFS, 0.04 -> 0.05 s
- `ui_open` changed: -18 -> -17 LUFS

## Findings

- none

## The sounds

LUFS is the loudest 400 ms, K-weighted; `raw` is before the gain; `short` is how far the peak ceiling stopped the gain; `over bed` is the margin over the loudest bed's average at the buses.

### death (target -12 LUFS)

| sound | s | LUFS | target | raw | gain dB | short | tpeak | over bed | var | event |
|---|---|---|---|---|---|---|---|---|---|---|
| `die` | 0.70 | -12 | -12 | -7.23 | -4.77 | - | -3.21 | 8.28 | 1 | player.died |
| `enemy_die` | 0.35 | -12 | -12 | -10.2 | -1.84 | - | -1.19 | 8.28 | 1 | enemy.die |
| `mech_die` | 0.49 | -12.3 | -12 | -11.2 | -1.07 | 0.31 | -1 | 7.97 | 1 | enemy.die_mech |

### enemy (target -14 LUFS)

| sound | s | LUFS | target | raw | gain dB | short | tpeak | over bed | var | event |
|---|---|---|---|---|---|---|---|---|---|---|
| `beam_charge` | 0.55 | -14 | -14 | -9.20 | -4.80 | - | -4.28 | 6.28 | 1 | enemy.beam_charge |
| `beam_fire` | 0.70 | -14 | -14 | -9.14 | -4.86 | - | -2.64 | 6.28 | 1 | enemy.beam_fire |
| `lunge` | 0.20 | -14.8 | -14 | -13.6 | -1.23 | 0.80 | -1 | 5.48 | 1 | enemy.lunge |
| `roar` | 0.90 | -14 | -14 | -5.75 | -8.25 | - | -8.24 | 6.28 | 1 | boss.phase |
| `stun` | 0.45 | -14 | -14 | -14.7 | 0.73 | - | -2.19 | 6.28 | 1 | enemy.stun |
| `tell` | 0.12 | -14 | -14 | -17.6 | 3.59 | - | -2.91 | 6.28 | 1 | enemy.tell |

### hack (target -14 LUFS)

| sound | s | LUFS | target | raw | gain dB | short | tpeak | over bed | var | event |
|---|---|---|---|---|---|---|---|---|---|---|
| `deny` | 0.24 | -14 | -14 | -16.1 | 2.06 | - | -5.29 | 6.28 | 1 | hack.failed |
| `hack_acquire` | 1.37 | -14 | -14 | -11.8 | -2.23 | - | -3.48 | 6.28 | 1 | hack.acquired |
| `hack_burst` | 0.45 | -14 | -14 | -8.94 | -5.06 | - | -4.57 | 6.28 | 1 | hack.overload |
| `hack_guard` | 0.40 | -14.3 | -14 | -15.7 | 1.42 | 0.31 | -1 | 5.97 | 1 | hack.firewall |
| `hack_pulse` | 0.77 | -14.2 | -14 | -17.1 | 2.87 | 0.23 | -1 | 6.05 | 1 | hack.breach |

### impact (target -14 LUFS)

| sound | s | LUFS | target | raw | gain dB | short | tpeak | over bed | var | event |
|---|---|---|---|---|---|---|---|---|---|---|
| `hazard` | 0.25 | -15 | -14 | -15.5 | 0.51 | 1 | -1 | 5.28 | 1 | player.hazard |
| `hit` | 0.09 | -14.3 | -14 | -12.5 | -1.83 | 0.29 | -1 | 5.99 | 3 | enemy.hit |
| `hit_guard` | 0.18 | -14 | -14 | -11.3 | -2.69 | - | -2.77 | 6.28 | 1 | player.hurt_guard |
| `hit_heavy` | 0.16 | -14 | -14 | -9.65 | -4.35 | - | -2.34 | 6.28 | 2 | enemy.hit_heavy |
| `hurt` | 0.22 | -14.6 | -14 | -14.2 | -0.33 | 0.57 | -1 | 5.71 | 1 | player.hurt |
| `land` | 0.14 | -14.2 | -14 | -13.4 | -0.82 | 0.25 | -1 | 6.03 | 3 | player.land |
| `slam` | 0.60 | -14 | -14 | -8.47 | -5.53 | - | -5.41 | 6.28 | 1 | enemy.slam |

### move (target -17 LUFS)

| sound | s | LUFS | target | raw | gain dB | short | tpeak | over bed | var | event |
|---|---|---|---|---|---|---|---|---|---|---|
| `dash` | 0.22 | -17 | -17 | -13.6 | -3.37 | - | -4.20 | 3.28 | 2 | player.dash |
| `jump` | 0.14 | -17 | -17 | -17.1 | 0.07 | - | -4.99 | 3.28 | 3 | player.jump |
| `swing` | 0.18 | -17 | -17 | -12.3 | -4.69 | - | -4.04 | 3.28 | 3 | player.swing |
| `wall_jump` | 0.14 | -17 | -17 | -17.6 | 0.62 | - | -3.39 | 3.28 | 2 | player.wall_jump |

### shot (target -16 LUFS)

| sound | s | LUFS | target | raw | gain dB | short | tpeak | over bed | var | event |
|---|---|---|---|---|---|---|---|---|---|---|
| `drone_shot` | 0.09 | -16.2 | -16 | -18.2 | 1.97 | 0.25 | -1 | 4.03 | 1 | enemy.drone_shot |
| `shoot` | 0.10 | -16 | -16 | -17.2 | 1.16 | - | -1.07 | 4.28 | 2 | player.shoot_bolt |
| `shoot_nail` | 0.07 | -16 | -16 | -15.2 | -0.83 | - | -1.03 | 4.28 | 2 | player.shoot_nail |
| `shoot_rivet` | 0.12 | -16 | -16 | -14.2 | -1.80 | - | -1.81 | 4.28 | 2 | player.shoot_rivet |

### stinger (target -15 LUFS)

| sound | s | LUFS | target | raw | gain dB | short | tpeak | over bed | var | event |
|---|---|---|---|---|---|---|---|---|---|---|
| `buy` | 0.24 | -15 | -15 | -16.8 | 1.80 | - | -1.84 | 5.28 | 1 | shop.purchased |
| `credits` | 0.22 | -15 | -15 | -17.7 | 2.68 | - | -4.86 | 5.28 | 1 | shop.credits |
| `level_up` | 1.70 | -15 | -15 | -10.7 | -4.26 | - | -4.30 | 5.28 | 1 | level.gained |
| `pickup` | 0.32 | -15 | -15 | -13.4 | -1.60 | - | -6.04 | 5.28 | 1 | item.picked_up |
| `quest` | 1.37 | -15 | -15 | -10.7 | -4.35 | - | -5.50 | 5.28 | 1 | quest.completed |
| `save` | 0.90 | -15 | -15 | -12.5 | -2.47 | - | -5.49 | 5.28 | 1 | save.activated |
| `stat_up` | 1.00 | -15 | -15 | -12.8 | -2.17 | - | -3.20 | 5.28 | 1 | stat_up.acquired |
| `title_start` | 0.80 | -15 | -15 | -7.95 | -7.05 | - | -7.21 | 5.28 | 1 | ui.title_start |
| `toast` | 0.25 | -15 | -15 | -18.7 | 3.71 | - | -2.33 | 5.28 | 1 | ui.toast |

### ui (target -17 LUFS)

| sound | s | LUFS | target | raw | gain dB | short | tpeak | over bed | var | event |
|---|---|---|---|---|---|---|---|---|---|---|
| `bark` | 0.09 | -20 | -20 | -24.0 | 3.97 | - | -1.14 | 0.28 | 1 | ui.bark |
| `text` | 0.02 | -24.4 | -24 | -37.7 | 13.3 | 0.37 | -1 | -4.09 | 1 | ui.text |
| `ui_back` | 0.16 | -17 | -17 | -22.0 | 5.02 | - | -4.78 | 3.28 | 1 | ui.back |
| `ui_close` | 0.18 | -17 | -17 | -16.7 | -0.32 | - | -1.89 | 3.28 | 1 | ui.close |
| `ui_confirm` | 0.16 | -17 | -17 | -20.9 | 3.88 | - | -5.68 | 3.28 | 1 | ui.confirm |
| `ui_move` | 0.05 | -17 | -17 | -27.3 | 10.3 | - | -1.28 | 3.28 | 1 | ui.move |
| `ui_open` | 0.22 | -17 | -17 | -25.1 | 8.09 | - | -3.49 | 3.28 | 1 | ui.open |

### world (target -16 LUFS)

| sound | s | LUFS | target | raw | gain dB | short | tpeak | over bed | var | event |
|---|---|---|---|---|---|---|---|---|---|---|
| `breach` | 0.70 | -16 | -16 | -11.8 | -4.16 | - | -4.34 | 4.28 | 1 | door.opened |
| `door` | 0.43 | -16 | -16 | -19.8 | 3.78 | - | -4.03 | 4.28 | 1 | door.closed |
| `door_pass` | 0.45 | -16.1 | -16 | -28.0 | 11.9 | 0.12 | -1 | 4.16 | 1 | room.entered |
| `lift` | 0.60 | -16 | -16 | -17.8 | 1.75 | - | -5.09 | 4.28 | 1 | lift.moved |

## The beds

Integrated and loudest 400 ms, as files and at the Music bus.

| bed | s | LUFS int | LUFS mom | at bus int | at bus mom |
|---|---|---|---|---|---|
| `game/assets/audio/music/boss.ogg` | 30 | -16.3 | -13.4 | -20.3 | -17.4 |
| `game/assets/audio/music/gut.ogg` | 32 | -18.1 | -11.3 | -22.1 | -15.3 |
| `game/assets/audio/music/roof.ogg` | 30 | -18.4 | -12.1 | -22.4 | -16.1 |
| `game/assets/audio/music/stacks.ogg` | 28.2 | -17.1 | -12.9 | -21.1 | -16.9 |
| `game/assets/audio/music/title.ogg` | 32 | -18.7 | -13.4 | -22.7 | -17.4 |
