# Neon Debt v0.1.0

2026-09-16 from 6aa90b0 on Godot 4.7.2.stable. 6 artifact(s), 257.7 MB.

## What changed

First release: nothing to compare against.

## Gates

| gate | | note |
|---|---|---|
| clean | ok | no tracked changes, the contract is committed |
| branch | ok | on vertical-slice |
| command | ok | tests: exit 0 |
| milestones | ok | 9 milestone(s) before M9 are done (sign-offs not counted: this release is how they get gathered) |
| autoplay | ok | 2026-09-16: 32 rooms, 0 engine errors |
| templates | ok | export templates 4.7.2.stable: 35 files |

## Exports

| preset | platform | files | bytes | pack | boots |
|---|---|---:|---:|---|---|
| windows | Windows Desktop | 2 | 110.0 MB | 775 files | yes |
| linux | Linux | 2 | 76.0 MB | 775 files | n/a |

- `neon-debt-0.1.0-windows.zip` 40.4 MB
- `neon-debt-0.1.0-linux.zip` 31.3 MB

## Screenshots

From `dist/0.1.0/exports/windows/NeonDebt.pck` (sha256 `0bde98a57abae9ec...`), at 1920x1080.

| shot | size | weight | light | |
|---|---|---:|---|---|
| 01_title | 1920x1080 | 48.3 KB | ink 89% | ok |
| 02_unit_14c | 1920x1080 | 317.6 KB | dark 68%, bright 3% | 3% bright, under the budget's 4% |
| 03_mezz | 1920x1080 | 203.1 KB | dark 79%, bright 1% | 79% dark, over the budget's 70%; 1% bright, under the budget's 4% |
| 04_defaulter_den | 1920x1080 | 201.4 KB | dark 88%, bright 1% | 88% dark, over the budget's 70%; 1% bright, under the budget's 4% |
| 05_east_ledges | 1920x1080 | 83.1 KB | dark 87%, bright 1% | 87% dark, over the budget's 70%; 1% bright, under the budget's 4% |
| 06_collections | 1920x1080 | 137.2 KB | dark 92%, bright 2% | 92% dark, over the budget's 70%; 2% bright, under the budget's 4% |
| 07_map | 1920x1080 | 68.0 KB | ink 31% | ok |
| 08_equip | 1920x1080 | 44.3 KB | ink 6% | ok |

Trailer: 142 frames at 20 fps, 9.05s, 640x360, 910.6 KB; mp4 735.1 KB

## The page

`page.md`, 15 controls read from the input map.

## The upload

- `butler push dist/0.1.0/exports/windows <your-itch-user>/neon-debt:windows --userversion 0.1.0`
- `butler push dist/0.1.0/exports/linux <your-itch-user>/neon-debt:linux --userversion 0.1.0`

No store configured yet, so there is nothing to push to and nothing was. The zips above are the deliverable.

- butler is not installed -- https://itch.io/docs/butler/installing.html (or `scoop install butler`)
- the store target is <your-itch-user>/neon-debt: put the real one in release.json

## What is somebody else's

- **environment-artist**: 5 shot(s) are darker than the level-artist's budget (02_unit_14c, 03_mezz, 04_defaulter_den, 05_east_ledges, 06_collections): the surfaces, not the lights
- **producer**: M8 (The look) has no shipped row in the log
- **producer**: M9 (Go or no-go) has no shipped row in the log
