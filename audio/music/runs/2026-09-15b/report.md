# Music: 2026-09-15b

5 tracks, 35 stems in `game/assets/audio/music`, the full mixes in `audio/music/mix`, ceiling -1 dBTP, the classes integrated LUFS as files (default -20, bed -20, fight -17, title -19), the Music bus at -4 dB. The tracks: `audio/music/tracks/`; the instruments: `audio/music/instruments.py`.

## Since the last run

- `boss`: gain -0.13 -> -0.23 dB; layers added: `heart`; stems that changed: `drone`, `tick`, `kick`, `snare`, `hats`, `bass`, `stabs`, `riser`, `lead`
- `gut`: gain 1.11 -> 0.78 dB; stems that changed: `drone`, `pad`, `throb`, `steam`, `clanks`, `hammer`, `heart`
- `roof`: gain 8.96 -> 8.13 dB; stems that changed: `wind`, `pad`, `bells`, `siren`, `drive`, `heart`
- `stacks`: gain 2.88 -> 1.89 dB; stems that changed: `pad`, `rain`, `hum`, `sub`, `thump`, `blips`, `pulse`, `heart`

## Findings

- `gut/throb` clicks at the seam (1.98 dB louder in the high band than anywhere inside; reference/loops.md)

## The tracks

LUFS is integrated over the whole loop (BS.1770, gated); `full` is every layer, `base` the layers that always play; `at bus` adds the Music bus; `short` is how far the ceiling stopped the gain; `seam` is the full mix's click check.

| track | class | BPM | bars | s | full | base | target | gain dB | short | tpeak | at bus | seam |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| `boss` | fight | 128 | 16 | 30 | -17 | -28.6 | -17 | -0.23 | - | -1.76 | -21 | ok |
| `gut` | bed | 60 | 8 | 32 | -20 | -20.9 | -20 | 0.78 | - | -3.86 | -24 | ok |
| `roof` | bed | 64 | 8 | 30 | -20 | -22.8 | -20 | 8.13 | - | -2.62 | -24 | ok |
| `stacks` | bed | 68 | 8 | 28.2 | -20 | -23.0 | -20 | 1.89 | - | -3.22 | -24 | ok |
| `title` | title | 60 | 8 | 32 | -19 | -19 | -19 | 7.33 | - | -3.32 | -23 | ok |

### boss (128 BPM, 16 bars, 30 s, class fight)

| layer | state | kind | dB | LUFS | tpeak | seam step | click dB | seam |
|---|---|---|---|---|---|---|---|---|
| `drone` | base | texture | -18 | -28.6 | -16.1 | 0.07 | -11.4 | ok |
| `tick` | base | pattern | -26 | -55.0 | -29.5 | 0.08 | -0.77 | ok |
| `kick` | fight | pattern | -6 | -21.2 | -6.75 | 0.98 | -0.87 | ok |
| `snare` | fight | pattern | -12 | -33.1 | -14.1 | 0.03 | -22.1 | ok |
| `hats` | fight | pattern | -20 | -39.3 | -18.4 | 0.21 | -1.59 | ok |
| `bass` | fight | pattern | -9 | -21.8 | -12.0 | 0.01 | -23.2 | ok |
| `stabs` | fight | pattern | -14 | -34.3 | -13.3 | 0.02 | -36.4 | ok |
| `riser` | fight | pattern | -18 | -29.9 | -18.1 | 0.03 | -20.7 | ok |
| `lead` | phase2 | pattern | -17 | -18.8 | -9.61 | 0 | - | ok |
| `heart` | low | pattern | -12 | -30.8 | -15.9 | 0 | -0.97 | ok |

### gut (60 BPM, 8 bars, 32 s, class bed)

| layer | state | kind | dB | LUFS | tpeak | seam step | click dB | seam |
|---|---|---|---|---|---|---|---|---|
| `drone` | base | texture | -11 | -21.4 | -7.30 | 1.07 | -4.91 | ok |
| `pad` | base | texture | -20 | -34.8 | -19.7 | 0.25 | -12.0 | ok |
| `throb` | base | pattern | -13 | -30.6 | -15.5 | 2.24 | 1.98 | CLICK |
| `steam` | base | pattern | -27 | -33.1 | -23 | 0 | - | ok |
| `clanks` | base | scatter | -24 | -41.4 | -23.6 | 0 | - | ok |
| `hammer` | combat | pattern | -11 | -21.5 | -12.8 | 0 | - | ok |
| `heart` | low | pattern | -14 | -31.6 | -16.9 | 0.26 | -0.42 | ok |

### roof (64 BPM, 8 bars, 30 s, class bed)

| layer | state | kind | dB | LUFS | tpeak | seam step | click dB | seam |
|---|---|---|---|---|---|---|---|---|
| `wind` | base | texture | -20 | -35.0 | -19.8 | 0.56 | -1.69 | ok |
| `pad` | base | texture | -16 | -23.9 | -10.4 | 0.03 | -6.82 | ok |
| `bells` | base | scatter | -22 | -24.3 | -12.0 | 0.10 | -31.7 | ok |
| `siren` | base | pattern | -36 | -36.2 | -28.0 | 0 | - | ok |
| `drive` | combat | pattern | -15 | -24.5 | -10.0 | 0.01 | -31.0 | ok |
| `heart` | low | pattern | -14 | -24.4 | -9.52 | 0.29 | -0.91 | ok |

### stacks (68 BPM, 8 bars, 28.2 s, class bed)

| layer | state | kind | dB | LUFS | tpeak | seam step | click dB | seam |
|---|---|---|---|---|---|---|---|---|
| `pad` | base | texture | -13 | -27.3 | -11.4 | 0.02 | -10.2 | ok |
| `rain` | base | texture | -30 | -45.8 | -36.9 | 0.32 | -2.31 | ok |
| `hum` | base | texture | -24 | -30.3 | -23.4 | 0.72 | -1.86 | ok |
| `sub` | base | pattern | -12 | -24.5 | -13.2 | 0.61 | -4.86 | ok |
| `thump` | base | pattern | -16 | -48.3 | -31.3 | 0.03 | -29.2 | ok |
| `blips` | base | scatter | -21 | -33.1 | -19.4 | 0.03 | -33.7 | ok |
| `pulse` | combat | pattern | -12 | -22.9 | -13.0 | 0.05 | -28.1 | ok |
| `heart` | low | pattern | -14 | -30.6 | -15.8 | 0.25 | 0.19 | ok |

### title (60 BPM, 8 bars, 32 s, class title)

| layer | state | kind | dB | LUFS | tpeak | seam step | click dB | seam |
|---|---|---|---|---|---|---|---|---|
| `pad` | base | texture | -13 | -21.1 | -3.40 | 0.05 | -10.8 | ok |
| `rain` | base | texture | -32 | -43.9 | -34.2 | 0.56 | -2.39 | ok |
| `theme` | base | pattern | -19 | -24.6 | -13.6 | 0.90 | -2.07 | ok |
| `sub` | base | pattern | -13 | -19.9 | -8.76 | 0.47 | -0.18 | ok |

## The states

Each state's level is the base layers plus that state's layers, the way the engine plays it.

| track | state | layers | LUFS | at bus | over base LU |
|---|---|---|---|---|---|
| `boss` | fight | `kick`, `snare`, `hats`, `bass`, `stabs`, `riser` | -17.9 | -21.9 | 10.7 |
| `boss` | phase2 | `lead` | -22.5 | -26.5 | 6.12 |
| `boss` | low | `heart` | -27.1 | -31.1 | 1.50 |
| `gut` | combat | `hammer` | -20.1 | -24.1 | 0.72 |
| `gut` | low | `heart` | -20.7 | -24.7 | 0.16 |
| `roof` | combat | `drive` | -20.6 | -24.6 | 2.16 |
| `roof` | low | `heart` | -21.9 | -25.9 | 0.88 |
| `stacks` | combat | `pulse` | -20.4 | -24.4 | 2.56 |
| `stacks` | low | `heart` | -22.3 | -26.3 | 0.67 |

## The effects over the music

The sound-designer's classes (the loudest 400 ms, at the SFX bus) over the loudest track's full mix at the Music bus (`boss`, -21 LUFS); the margin is 3 LU.

| class | target | over the music LU |
|---|---|---|
| `death` | -12 | 9 |
| `default` | -16 | 5 |
| `enemy` | -14 | 7 |
| `hack` | -14 | 7 |
| `impact` | -14 | 7 |
| `move` | -17 | 4 |
| `shot` | -16 | 5 |
| `stinger` | -15 | 6 |
| `ui` | -17 | 4 |
| `world` | -16 | 5 |

## The moods

| mood | track | states it may raise |
|---|---|---|
| `residential` | `stacks` | combat, low |
| `mezz` | `stacks` | combat, low |
| `shaft` | `stacks` | combat, low |
| `gut` | `gut` | combat, low |
| `roof` | `roof` | combat, low |
| `collections` | `boss` | fight, phase2, low |
| `title` | `title` | - |
