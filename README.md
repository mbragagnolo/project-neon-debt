# Neon Debt

Cyberpunk 2D metroidvania with Castlevania-style RPG elements, built in
**Godot 4.7** (GDScript). See [DESIGN.md](DESIGN.md) for the full vertical-slice
design and the milestone plan.

**Status: M3 (RPG layer) ready to play.** Stats, levels, the ten items,
inventory and equip screen, pickups and the level-up moment are in and tested.
The exit test — "equipping better gear visibly changes combat math; HUD shows
it" — is Marcos's to call: open a chest in the RPG gym, swap a weapon, hit the
same dummy and watch the number. The two earlier gyms are still there and
still tested; each milestone's lab outlives its milestone.

---

## Getting set up

1. Install [Godot 4.7](https://godotengine.org/download) (standard build, no
   .NET needed).
2. Open `game/project.godot` in the editor, or run from the command line below.

The GUT test framework is vendored at `game/addons/gut` (MIT), so nothing needs
downloading and CI runs offline.

## Running

```bash
cd game

# Play it (opens the M3 gear-and-levels gym)
godot --path .

# Boot headless (what CI does — must log no errors)
godot --headless --path . --quit-after 120

# Run the test suite
godot --headless --path . -s addons/gut/gut_cmdln.gd -gconfig=.gutconfig.json
```

## Layout

```
game/
  project.godot        # input map (keyboard + gamepad), collision layers, autoloads
  icon.svg
  src/
    core/              # Events (signal bus), GameState, SaveLoad
    player/            # controller, state machine, movement_config.tres
    world/             # room.gd
    combat/ rpg/ enemies/ quests/ ui/    # scaffolded, filled in per milestone
  rooms/               # one .tscn per room; gym.tscn is the main scene
  tests/               # GUT tests, run headless in CI
  tools/               # greybox room generators (editor-side, not shipped)
  addons/gut/          # vendored test framework
```

Each `src/` subdirectory has a README naming what belongs there and which
milestone builds it.

## Conventions

These are what make the solo-plus-agents model work (DESIGN.md §4):

- **Everything is text.** GDScript, `.tscn` and `.tres` in text format — every
  file is readable and diffable.
- **`.uid` sidecars are committed.** Godot 4.4+ writes a `.uid` next to every
  script; it keeps `res://` references stable across renames, so it belongs in
  git next to the script it names. Never hand-edit one. (`.tscn`/`.tres` get a
  `uid=` in their own header once 4.4+ re-saves them — same idea, no sidecar.)
- **Talk over the bus.** Systems emit on `Events` rather than reaching across
  the scene tree. New feature, new signal — not a new node path.
- **Balance is data.** Movement, items, enemies and the XP curve live in
  `.tres`/JSON. Tuning must never require touching logic.
- **Logic is tested, feel is played.** Damage maths, XP, save/load, inventory
  and quest states get GUT tests. Whether the jump feels good is Marcos's call,
  and no test can make it for him.
- **Room ids are permanent.** They land in save files and on the map screen.
- Small, PR-sized changes; CI green before merge.

## What M0 actually pinned down

Decisions made here that later milestones inherit — call them out if they need
revisiting:

| Decision | Value | Why / when to revisit |
|---|---|---|
| Engine | Godot 4.7 (standard build) | Started on 4.3; moved to 4.7 before M1 so the movement controller is never written against an engine we then migrate off. CI pins the exact patch (`GODOT_VERSION` in `ci.yml`) — keep the local editor on the same one. |
| Base viewport | 1920×1080, `canvas_items` stretch, `keep` aspect | The *coordinate space*, not the output resolution — `canvas_items` renders natively at whatever the window is, so 1440p and 4K are already crisp. 1080p keeps world units equal to pixels at the most common display size. |
| Default window | 1280×720 windowed | Fits any laptop on first launch; fullscreen gives native. A resolution/fullscreen setting is M7. |
| Texture filter | Linear | Nearest would be a pixel-art commitment, and DESIGN.md §7 hasn't made that call. One-line flip if the art pass goes pixel. |
| Greybox grid | 60px — 1920×1080 is exactly 32×18 units | Clean divisor for M5 level layout; a 60×90 player is 1×1.5 units. |
| Room size | One room = one screen at M0 | The M1 gym and M5's district rooms get a following camera and can be any size. |
| Jump authoring | Height + time-to-apex; gravity is derived | Lets you type "3.5 tiles, snappy" instead of guessing at px/s². |
| Save format | JSON in `user://saves`, 3 slots, versioned | Corrupt or missing saves degrade to a fresh run, never a crash. |
| Collision layers | 1 world, 2 player, 3–4 player hit/hurt, 5 enemy, 6–7 enemy hit/hurt, 8 interactable, 9 hazard, 10 projectile, 11 one-way, 12 room transition | Named in `project.godot`; combat in M2 depends on this split. |
