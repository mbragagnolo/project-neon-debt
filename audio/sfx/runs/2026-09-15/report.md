# Sound report, 2026-09-15

49 sounds, 63 files in `game/assets/audio/sfx`, ceiling -1 dBTP, 5 beds auditioned. The recipes: `audio/sfx/recipes.py`.

## Since the last run

First run; nothing to diff against.

## Findings

- `bark` stops 1.86 LU short of its class target (-18) at the peak ceiling: the recipe is peaky, make it denser (reference/loudness.md)
- `bark` sits 0.42 LU over the loudest bed at the buses, under the 6 LU margin
- `breach` sits 4.28 LU over the loudest bed at the buses, under the 6 LU margin
- `buy` sits 5.28 LU over the loudest bed at the buses, under the 6 LU margin
- `credits` sits 5.28 LU over the loudest bed at the buses, under the 6 LU margin
- `dash` stops 1.05 LU short of its class target (-17) at the peak ceiling: the recipe is peaky, make it denser (reference/loudness.md)
- `dash` sits 2.23 LU over the loudest bed at the buses, under the 6 LU margin
- `door` sits 4.28 LU over the loudest bed at the buses, under the 6 LU margin
- `door_pass` sits 4.16 LU over the loudest bed at the buses, under the 6 LU margin
- `drone_shot` sits 3.47 LU over the loudest bed at the buses, under the 6 LU margin
- `hack_guard` sits 5.97 LU over the loudest bed at the buses, under the 6 LU margin
- `hazard` stops 1.21 LU short of its class target (-14) at the peak ceiling: the recipe is peaky, make it denser (reference/loudness.md)
- `hazard` sits 5.07 LU over the loudest bed at the buses, under the 6 LU margin
- `hit` stops 3.19 LU short of its class target (-14) at the peak ceiling: the recipe is peaky, make it denser (reference/loudness.md)
- `hit` sits 3.09 LU over the loudest bed at the buses, under the 6 LU margin
- `hit_guard` stops 4.19 LU short of its class target (-14) at the peak ceiling: the recipe is peaky, make it denser (reference/loudness.md)
- `hit_guard` sits 2.09 LU over the loudest bed at the buses, under the 6 LU margin
- `hurt` sits 5.71 LU over the loudest bed at the buses, under the 6 LU margin
- `jump` sits 3.28 LU over the loudest bed at the buses, under the 6 LU margin
- `land` stops 5.12 LU short of its class target (-14) at the peak ceiling: the recipe is peaky, make it denser (reference/loudness.md)
- `land` sits 1.16 LU over the loudest bed at the buses, under the 6 LU margin
- `level_up` sits 5.28 LU over the loudest bed at the buses, under the 6 LU margin
- `lift` sits 4.28 LU over the loudest bed at the buses, under the 6 LU margin
- `lunge` stops 6.93 LU short of its class target (-14) at the peak ceiling: the recipe is peaky, make it denser (reference/loudness.md)
- `lunge` sits -0.65 LU over the loudest bed at the buses, under the 6 LU margin
- `pickup` sits 5.28 LU over the loudest bed at the buses, under the 6 LU margin
- `quest` sits 5.28 LU over the loudest bed at the buses, under the 6 LU margin
- `save` sits 5.28 LU over the loudest bed at the buses, under the 6 LU margin
- `shoot` sits 4.28 LU over the loudest bed at the buses, under the 6 LU margin
- `shoot_nail` stops 5.83 LU short of its class target (-16) at the peak ceiling: the recipe is peaky, make it denser (reference/loudness.md)
- `shoot_nail` sits -1.55 LU over the loudest bed at the buses, under the 6 LU margin
- `shoot_rivet` sits 4.28 LU over the loudest bed at the buses, under the 6 LU margin
- `stat_up` sits 5.28 LU over the loudest bed at the buses, under the 6 LU margin
- `swing` stops 4.92 LU short of its class target (-17) at the peak ceiling: the recipe is peaky, make it denser (reference/loudness.md)
- `swing` sits -1.64 LU over the loudest bed at the buses, under the 6 LU margin
- `text` stops 6.37 LU short of its class target (-18) at the peak ceiling: the recipe is peaky, make it denser (reference/loudness.md)
- `text` sits -4.09 LU over the loudest bed at the buses, under the 6 LU margin
- `title_start` sits 5.28 LU over the loudest bed at the buses, under the 6 LU margin
- `toast` sits 5.28 LU over the loudest bed at the buses, under the 6 LU margin
- `ui_back` sits 2.28 LU over the loudest bed at the buses, under the 6 LU margin
- `ui_close` sits 1.73 LU over the loudest bed at the buses, under the 6 LU margin
- `ui_confirm` sits 2.28 LU over the loudest bed at the buses, under the 6 LU margin
- `ui_move` sits 2.28 LU over the loudest bed at the buses, under the 6 LU margin
- `ui_open` sits 2.28 LU over the loudest bed at the buses, under the 6 LU margin
- `wall_jump` sits 3.28 LU over the loudest bed at the buses, under the 6 LU margin

## The sounds

LUFS is the loudest 400 ms, K-weighted; `raw` is before the gain; `short` is how far the peak ceiling stopped the gain; `over bed` is the margin over the loudest bed's average at the buses.

### death (target -12 LUFS)

| sound | s | LUFS | raw | gain dB | short | tpeak | over bed | var | event |
|---|---|---|---|---|---|---|---|---|---|
| `die` | 0.70 | -12 | -7.23 | -4.77 | - | -3.21 | 8.28 | 1 | player.died |
| `enemy_die` | 0.35 | -12 | -10.2 | -1.84 | - | -1.19 | 8.28 | 1 | enemy.die |
| `mech_die` | 0.49 | -12.9 | -10.3 | -2.66 | 0.93 | -1 | 7.35 | 1 | enemy.die_mech |

### enemy (target -14 LUFS)

| sound | s | LUFS | raw | gain dB | short | tpeak | over bed | var | event |
|---|---|---|---|---|---|---|---|---|---|
| `beam_charge` | 0.55 | -14 | -9.20 | -4.80 | - | -4.28 | 6.28 | 1 | enemy.beam_charge |
| `beam_fire` | 0.70 | -14 | -9.14 | -4.86 | - | -2.64 | 6.28 | 1 | enemy.beam_fire |
| `lunge` | 0.18 | -20.9 | -23.4 | 2.44 | 6.93 | -1 | -0.65 | 1 | enemy.lunge |
| `roar` | 0.90 | -14 | -5.75 | -8.25 | - | -8.24 | 6.28 | 1 | boss.phase |
| `stun` | 0.45 | -14 | -14.7 | 0.73 | - | -2.19 | 6.28 | 1 | enemy.stun |
| `tell` | 0.12 | -14 | -17.6 | 3.59 | - | -2.91 | 6.28 | 1 | enemy.tell |

### hack (target -14 LUFS)

| sound | s | LUFS | raw | gain dB | short | tpeak | over bed | var | event |
|---|---|---|---|---|---|---|---|---|---|
| `deny` | 0.24 | -14 | -16.1 | 2.06 | - | -5.29 | 6.28 | 1 | hack.failed |
| `hack_acquire` | 1.37 | -14 | -11.8 | -2.23 | - | -3.48 | 6.28 | 1 | hack.acquired |
| `hack_burst` | 0.45 | -14 | -8.94 | -5.06 | - | -4.57 | 6.28 | 1 | hack.overload |
| `hack_guard` | 0.40 | -14.3 | -15.7 | 1.42 | 0.31 | -1 | 5.97 | 1 | hack.firewall |
| `hack_pulse` | 0.77 | -14.2 | -17.1 | 2.87 | 0.23 | -1 | 6.05 | 1 | hack.breach |

### impact (target -14 LUFS)

| sound | s | LUFS | raw | gain dB | short | tpeak | over bed | var | event |
|---|---|---|---|---|---|---|---|---|---|
| `hazard` | 0.25 | -15.2 | -13.9 | -1.33 | 1.21 | -1 | 5.07 | 1 | player.hazard |
| `hit` | 0.09 | -17.2 | -13.7 | -3.46 | 3.19 | -1 | 3.09 | 3 | enemy.hit |
| `hit_guard` | 0.18 | -18.2 | -18.3 | 0.11 | 4.19 | -1 | 2.09 | 1 | player.hurt_guard |
| `hit_heavy` | 0.16 | -14 | -9.65 | -4.35 | - | -2.34 | 6.28 | 2 | enemy.hit_heavy |
| `hurt` | 0.22 | -14.6 | -14.2 | -0.33 | 0.57 | -1 | 5.71 | 1 | player.hurt |
| `land` | 0.11 | -19.1 | -21.4 | 2.23 | 5.12 | -1 | 1.16 | 3 | player.land |
| `slam` | 0.60 | -14 | -8.47 | -5.53 | - | -5.41 | 6.28 | 1 | enemy.slam |

### move (target -17 LUFS)

| sound | s | LUFS | raw | gain dB | short | tpeak | over bed | var | event |
|---|---|---|---|---|---|---|---|---|---|
| `dash` | 0.20 | -18.1 | -21.8 | 3.73 | 1.05 | -1 | 2.23 | 2 | player.dash |
| `jump` | 0.14 | -17 | -17.1 | 0.07 | - | -4.99 | 3.28 | 3 | player.jump |
| `swing` | 0.16 | -21.9 | -21.2 | -0.73 | 4.92 | -1 | -1.64 | 3 | player.swing |
| `wall_jump` | 0.14 | -17 | -17.6 | 0.62 | - | -3.39 | 3.28 | 2 | player.wall_jump |

### shot (target -16 LUFS)

| sound | s | LUFS | raw | gain dB | short | tpeak | over bed | var | event |
|---|---|---|---|---|---|---|---|---|---|
| `drone_shot` | 0.09 | -16.8 | -23.6 | 6.76 | 0.81 | -1 | 3.47 | 1 | enemy.drone_shot |
| `shoot` | 0.10 | -16 | -17.2 | 1.16 | - | -1.07 | 4.28 | 2 | player.shoot_bolt |
| `shoot_nail` | 0.06 | -21.8 | -27.3 | 5.44 | 5.83 | -1 | -1.55 | 2 | player.shoot_nail |
| `shoot_rivet` | 0.12 | -16 | -14.2 | -1.80 | - | -1.81 | 4.28 | 2 | player.shoot_rivet |

### stinger (target -15 LUFS)

| sound | s | LUFS | raw | gain dB | short | tpeak | over bed | var | event |
|---|---|---|---|---|---|---|---|---|---|
| `buy` | 0.24 | -15 | -16.8 | 1.80 | - | -1.84 | 5.28 | 1 | shop.purchased |
| `credits` | 0.22 | -15 | -17.7 | 2.68 | - | -4.86 | 5.28 | 1 | shop.credits |
| `level_up` | 1.70 | -15 | -10.7 | -4.26 | - | -4.30 | 5.28 | 1 | level.gained |
| `pickup` | 0.32 | -15 | -13.4 | -1.60 | - | -6.04 | 5.28 | 1 | item.picked_up |
| `quest` | 1.37 | -15 | -10.7 | -4.35 | - | -5.50 | 5.28 | 1 | quest.completed |
| `save` | 0.90 | -15 | -12.5 | -2.47 | - | -5.49 | 5.28 | 1 | save.activated |
| `stat_up` | 1.00 | -15 | -12.8 | -2.17 | - | -3.20 | 5.28 | 1 | stat_up.acquired |
| `title_start` | 0.80 | -15 | -7.95 | -7.05 | - | -7.21 | 5.28 | 1 | ui.title_start |
| `toast` | 0.25 | -15 | -18.7 | 3.71 | - | -2.33 | 5.28 | 1 | ui.toast |

### ui (target -18 LUFS)

| sound | s | LUFS | raw | gain dB | short | tpeak | over bed | var | event |
|---|---|---|---|---|---|---|---|---|---|
| `bark` | 0.09 | -19.9 | -24.0 | 4.11 | 1.86 | -1 | 0.42 | 1 | ui.bark |
| `text` | 0.02 | -24.4 | -37.7 | 13.3 | 6.37 | -1 | -4.09 | 1 | ui.text |
| `ui_back` | 0.16 | -18 | -22.0 | 4.02 | - | -5.78 | 2.28 | 1 | ui.back |
| `ui_close` | 0.18 | -18.6 | -23.7 | 5.18 | 0.55 | -1 | 1.73 | 1 | ui.close |
| `ui_confirm` | 0.16 | -18 | -20.9 | 2.88 | - | -6.68 | 2.28 | 1 | ui.confirm |
| `ui_move` | 0.04 | -18 | -28.9 | 10.9 | - | -1.36 | 2.28 | 1 | ui.move |
| `ui_open` | 0.22 | -18 | -25.1 | 7.09 | - | -4.49 | 2.28 | 1 | ui.open |

### world (target -16 LUFS)

| sound | s | LUFS | raw | gain dB | short | tpeak | over bed | var | event |
|---|---|---|---|---|---|---|---|---|---|
| `breach` | 0.70 | -16 | -11.8 | -4.16 | - | -4.34 | 4.28 | 1 | door.opened |
| `door` | 0.43 | -16 | -19.8 | 3.78 | - | -4.03 | 4.28 | 1 | door.closed |
| `door_pass` | 0.45 | -16.1 | -28.0 | 11.9 | 0.12 | -1 | 4.16 | 1 | room.entered |
| `lift` | 0.60 | -16 | -17.8 | 1.75 | - | -5.09 | 4.28 | 1 | lift.moved |

## The beds

Integrated and loudest 400 ms, as files and at the Music bus.

| bed | s | LUFS int | LUFS mom | at bus int | at bus mom |
|---|---|---|---|---|---|
| `game/assets/audio/music/boss.ogg` | 30 | -16.3 | -13.4 | -20.3 | -17.4 |
| `game/assets/audio/music/gut.ogg` | 32 | -18.1 | -11.3 | -22.1 | -15.3 |
| `game/assets/audio/music/roof.ogg` | 30 | -18.4 | -12.1 | -22.4 | -16.1 |
| `game/assets/audio/music/stacks.ogg` | 28.2 | -17.1 | -12.9 | -21.1 | -16.9 |
| `game/assets/audio/music/title.ogg` | 32 | -18.7 | -13.4 | -22.7 | -17.4 |
