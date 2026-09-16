# Music: 2026-09-15c

5 tracks, 35 stems in `game/assets/audio/music`, the full mixes in `audio/music/mix`, ceiling -1 dBTP, the classes integrated LUFS as files (default -20, bed -20, fight -17, title -19), the Music bus at -4 dB. The tracks: `audio/music/tracks/`; the instruments: `audio/music/instruments.py`.

## Since the last run

- `boss`: gain -0.23 -> -0.34 dB; stems that changed: `drone`, `tick`, `kick`, `snare`, `hats`, `bass`, `stabs`, `riser`, `lead`, `heart`
- `gut`: gain 0.78 -> 0.56 dB; stems that changed: `drone`, `pad`, `throb`, `steam`, `clanks`, `hammer`, `heart`
- `roof`: gain 8.13 -> 7.11 dB; stems that changed: `wind`, `pad`, `bells`, `siren`, `drive`, `heart`
- `stacks`: gain 1.89 -> 1.40 dB; stems that changed: `pad`, `rain`, `hum`, `sub`, `thump`, `blips`, `pulse`, `heart`

## Findings

- None: every stem loops clean at its length, every track is on its class, the effects clear the music.

## The tracks

LUFS is integrated over the whole loop (BS.1770, gated); `full` is every layer, `base` the layers that always play; `at bus` adds the Music bus; `short` is how far the ceiling stopped the gain; `seam` is the full mix's click check.

| track | class | BPM | bars | s | full | base | target | gain dB | short | tpeak | at bus | seam |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| `boss` | fight | 128 | 16 | 30 | -17 | -28.8 | -17 | -0.34 | - | -1.28 | -21 | ok |
| `gut` | bed | 60 | 8 | 32 | -20 | -21.1 | -20 | 0.56 | - | -4.08 | -24 | ok |
| `roof` | bed | 64 | 8 | 30 | -20 | -23.8 | -20 | 7.11 | - | -1.35 | -24 | ok |
| `stacks` | bed | 68 | 8 | 28.2 | -20 | -23.5 | -20 | 1.40 | - | -2.25 | -24 | ok |
| `title` | title | 60 | 8 | 32 | -19 | -19 | -19 | 7.33 | - | -3.32 | -23 | ok |

### boss (128 BPM, 16 bars, 30 s, class fight)

| layer | state | kind | dB | LUFS | tpeak | seam step | click dB | seam |
|---|---|---|---|---|---|---|---|---|
| `drone` | base | texture | -18 | -28.8 | -16.2 | 0.13 | -11.7 | ok |
| `tick` | base | pattern | -26 | -55.1 | -29.6 | 0.07 | -0.79 | ok |
| `kick` | fight | pattern | -6 | -21.3 | -6.86 | 0.95 | -0.71 | ok |
| `snare` | fight | pattern | -12 | -33.2 | -14.2 | 0.03 | -22.1 | ok |
| `hats` | fight | pattern | -20 | -39.4 | -18.5 | 0.24 | -1.88 | ok |
| `bass` | fight | pattern | -9 | -21.9 | -12.2 | 0.09 | -23.0 | ok |
| `stabs` | fight | pattern | -14 | -34.4 | -13.4 | 0.03 | -36.2 | ok |
| `riser` | fight | pattern | -18 | -30.0 | -18.2 | 0.07 | -20.9 | ok |
| `lead` | phase2 | pattern | -17 | -18.9 | -9.72 | 0 | - | ok |
| `heart` | low | pattern | -9 | -27.9 | -13.0 | 0.06 | -0.85 | ok |

### gut (60 BPM, 8 bars, 32 s, class bed)

| layer | state | kind | dB | LUFS | tpeak | seam step | click dB | seam |
|---|---|---|---|---|---|---|---|---|
| `drone` | base | texture | -11 | -21.7 | -7.52 | 0.07 | -11.1 | ok |
| `pad` | base | texture | -20 | -35.0 | -19.9 | 0.07 | -12.4 | ok |
| `throb` | base | pattern | -13 | -30.8 | -15.7 | 0.96 | 0.36 | ok |
| `steam` | base | pattern | -27 | -33.3 | -23.2 | 0 | - | ok |
| `clanks` | base | scatter | -24 | -41.6 | -23.8 | 0 | - | ok |
| `hammer` | combat | pattern | -11 | -21.7 | -13.0 | 0 | - | ok |
| `heart` | low | pattern | -9 | -26.8 | -12.1 | 0.23 | -0.68 | ok |

### roof (64 BPM, 8 bars, 30 s, class bed)

| layer | state | kind | dB | LUFS | tpeak | seam step | click dB | seam |
|---|---|---|---|---|---|---|---|---|
| `wind` | base | texture | -20 | -36.1 | -20.8 | 0.34 | -1.93 | ok |
| `pad` | base | texture | -16 | -24.9 | -11.5 | 0.44 | -7.14 | ok |
| `bells` | base | scatter | -22 | -25.3 | -13.0 | 0.08 | -31.6 | ok |
| `siren` | base | pattern | -36 | -37.2 | -29.0 | 0 | - | ok |
| `drive` | combat | pattern | -15 | -25.6 | -11.1 | 0.01 | -30.9 | ok |
| `heart` | low | pattern | -9 | -20.5 | -5.54 | 0.27 | -1.16 | ok |

### stacks (68 BPM, 8 bars, 28.2 s, class bed)

| layer | state | kind | dB | LUFS | tpeak | seam step | click dB | seam |
|---|---|---|---|---|---|---|---|---|
| `pad` | base | texture | -13 | -27.8 | -11.9 | 0.09 | -9.68 | ok |
| `rain` | base | texture | -30 | -46.2 | -37.4 | 0.43 | -2.62 | ok |
| `hum` | base | texture | -24 | -30.8 | -23.8 | 1.57 | 2.85 | ok |
| `sub` | base | pattern | -12 | -24.9 | -13.7 | 2.13 | -3.25 | ok |
| `thump` | base | pattern | -16 | -48.8 | -31.8 | 0.05 | -29.9 | ok |
| `blips` | base | scatter | -21 | -33.6 | -19.9 | 0.02 | -33.6 | ok |
| `pulse` | combat | pattern | -12 | -23.4 | -13.4 | 0.01 | -27.7 | ok |
| `heart` | low | pattern | -9 | -26.2 | -11.2 | 0.26 | -0.01 | ok |

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
| `boss` | fight | `kick`, `snare`, `hats`, `bass`, `stabs`, `riser` | -18.0 | -22.0 | 10.7 |
| `boss` | phase2 | `lead` | -22.6 | -26.6 | 6.12 |
| `boss` | low | `heart` | -26.1 | -30.1 | 2.61 |
| `gut` | combat | `hammer` | -20.4 | -24.4 | 0.72 |
| `gut` | low | `heart` | -20.7 | -24.7 | 0.41 |
| `roof` | combat | `drive` | -21.6 | -25.6 | 2.16 |
| `roof` | low | `heart` | -21.5 | -25.5 | 2.32 |
| `stacks` | combat | `pulse` | -20.9 | -24.9 | 2.56 |
| `stacks` | low | `heart` | -22.1 | -26.1 | 1.39 |

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
