# The Stacks

**Status: built (M5).** The district as shipped: 34 rooms, the critical
path, every gate, every placement. Elaborates DESIGN.md §2 and §3.4.

Rooms are authored as ASCII grids in `game/tools/stacks/*.room` (one
character per 60px tile) and generated into scenes by
`tools/make_stacks.tscn`. The specs are the level design; the `.tscn` files
are output. `tests/test_stacks.gd` reads the specs and holds them to
everything on this page.

## The shape

```
                       roof_span ─────── roof_access ── roof_gap ── collections_lift
 west_stair ───────────┘   (tease 1)       │  (Sidewinder gate)        │
   │  west_alcove (HP)                stairwell_east            collections_lobby (save 3, tease 3)
   │                        unit_14c ── hall_14 ──┤                        │
   │                        closet ─── hall_13 ───┘ (save 1)           collections (boss)
   └─ mezz_east ── mezz (hub: save 2, Stitch, Marisol)
        │  pawn_back (Cyberdeck) ── underpass (boots) ── lift_base ══ armory_chute
        │                             │ (drain riser)      │ shaft        │
        │                             │                lift_shaft (RAM)  armory (maul)
        │                             │                    │               │ (Breach door)
        │                             │             east_ledges (blade, HP) ── breach_gate_room (Breach)
        │                             │                    │
        │                             │             server_nook (Overload) ── catwalks (Sidewinder gate 2: rivet gun; tease 2; RAM)
   gut_stair                          │
   service_tunnel                     │
   gut_pumps (HP) ── gut_vent (nailgun)
   gut_lift ── (Breach door) ── defaulter_den (Elite, chip) ── gut_deep (Sidewinder) ══ drain_riser (lift)
   gut_cistern (gloves, RAM)
```

`══` is a shortcut grate: solid until released from the far side, then a
hole in the wall both ways.

## The critical path, and the kit at each step

| # | Where | Kit gained | Minutes (rough) |
|---|---|---|---|
| 1 | Unit 14-C → Floor 14 hall → stairwell (drop) → Floor 13 hall (**terminal 1**) | — | 0–3 |
| 2 | Maintenance closet | **Mag-Hook** (wall jump) | 4 |
| 3 | Back up the stairwell shaft → roof → across Tower 7 (tease 1 visible; the Collections gap visible east) | — | 5–8 |
| 4 | Stair West down (alcove: HP up) → Mezzanine East → **the Mezz** (terminal 2, Stitch, Marisol — the quest is offered) | — | 10 |
| 5 | Stitch's back room | **Cyberdeck** (RAM +6, quickslot) | 12 |
| 6 | Underpass (boots chest) → east lift shaft (RAM up at the top) → East Ledges (blade chest, HP up) | boots, blade | 14–16 |
| 7 | Edge Node 7 | **Overload** | 17 |
| 8 | Drop from the ledges into the Collections bulkhead room | **Breach**, and the door it opens | 19 |
| 9 | Repossessed Assets (maul) → disposal chute → release the grate into the lift base — the loop back | maul | 21 |
| 10 | The Gut: stair → service tunnel → pump hall (HP up; vent: nailgun) → lift (cistern: gloves, RAM up) → **Breach door** → the sump (Elite, **the chip**) | nailgun, gloves, chip | 24–32 |
| 11 | Retrieval room | **Sidewinder** (sealed) | 33 |
| 12 | Drain riser: release the grate, ride the freight lift up to the underpass — the second loop | — | 35 |
| 13 | The Mezz: Marisol (**hardhat**), Stitch installs the **Sidewinder** (air dash) | hardhat, air dash | 37 |
| 14 | Optional: back east, past the catwalks' gap for the **rivet gun** | rivet gun | +4 |
| 15 | Roof → the gap → Collections lift → reception (**terminal 3**, tease 3) → **the Landlord** | — | 40–45 |

Every one of items.md's placement rules holds: nothing is found in the first
ten minutes (the Hook is a gadget, not gear), the blade is the first felt
pickup, the boots land as the Scav zone starts to hurt, the nailgun and the
gloves are hidden-room rewards, the maul waits behind the first Breach door,
the rivet gun sits past a skill check, the hardhat is the quest reward, and
the jacket is the credit sink at Stitch.

## Gates, by the grammar

| Gate | Where | Opened by | Test |
|---|---|---|---|
| Shaft | stairwell_east (to the roof), lift_base → lift_shaft, gut_pumps (to the vent), gut_lift (to the cistern) | Mag-Hook | `gate shaft` — 4-tile shafts, certified against `wall_jump_reach()` |
| Sealed door with terminal | breach_gate_room → armory, gut_lift → defaulter_den | Breach | `requires <door> breach` in the progression walk |
| Wide flat gap | roof_gap (8 tiles, over a void), catwalks (8 tiles, over the lower band) | Sidewinder | `gate air_dash` — lip to lip against `max_gap()` both ways, ≥15% margin |
| High single-wall ledge | roof_span (the water tower), catwalks (the chimney), collections_lobby (the hanging balcony) | **Never in V1** | `gate tease` — ≥15% above a jump, no facing wall within a wall jump |
| One-way grate | lift_base ← armory_chute, drain_riser ← gut_deep | Nothing (released from the far side) | placement |

### The envelope the gates were sized against

Derived from `movement_config.tres` by `MovementEnvelope`, never typed in
(DESIGN.md §3.4):

| Move | Reach |
|---|---|
| Running jump, edge to edge | ~290px — a 4–5 tile gap |
| Ground dash | 288px, altitude held |
| Jump + air dash (Sidewinder) | ~578px — an 8-tile gap with the body width folded in |
| Jump height | 168px — a 2-tile step; a 3-tile step is a wall |
| Wall jump | +144px per bounce; a 4-tile shaft is comfortable |

Two controller rules exist for these numbers to hold, both in `Player`:
**a dash that runs off a ledge forfeits the jump at its end** (otherwise the
starting kit crosses ~480px by dashing off the edge and jumping in the
coyote window), and **the air dash does not wait on the ground dash's
cooldown** (otherwise dash → jump → air dash is a timing puzzle). And for
the teases: **a wall the player just jumped off refuses them for the whole
flight** (`same_wall_lockout_time`), so a single wall is never a ladder.
`tests/test_movement_envelope.gd` proves all three with real physics.

## Rooms

| Room | Cell | Size | What it holds |
|---|---|---|---|
| unit_14c | 5,1 | 1×1 | Start. The repossession notice. |
| hall_14 | 6,1 | 2×1 | 1 Scav — the first fight. |
| stairwell_east | 8,1 | 1×2 | The first shaft. Drop down now, climb later. |
| hall_13 | 6,2 | 2×1 | 2 Scavs, **terminal 1**. |
| maintenance_closet | 5,2 | 1×1 | **Mag-Hook** on a dead tech. |
| roof_access | 8,0 | 1×1 | Top of the shaft; the way to Collections. |
| roof_span | 5,0 | 3×1 | 3 Scavs, 2 drones, **tease 1** (water tower). |
| west_stair | 4,0 | 1×3 | Zig-zag ledges down; 2 Scavs; the alcove door. |
| west_alcove | 3,1 | 1×1 | **HP up**. |
| mezz_east | 4,3 | 1×1 | 1 Scav. |
| mezz | 1,3 | 3×1 | **The hub**: terminal 2, Stitch, Marisol. No enemies. |
| pawn_back | 5,3 | 1×1 | **Cyberdeck**. |
| underpass | 6,3 | 3×1 | 3 Scavs, 1 Riot unit; **boots**; the drain riser's hole. |
| lift_base | 9,3 | 1×1 | The east shaft's mouth; the chute grate. |
| lift_shaft | 9,1 | 1×2 | Shaft; 1 drone; **RAM up** at the very top. |
| east_ledges | 10,1 | 2×1 | Platforming; 2 Scavs, 3 drones; **blade**, **HP up**; the drop to the bulkhead. |
| server_nook | 12,1 | 1×1 | **Overload**; 1 drone. |
| breach_gate_room | 11,2 | 1×1 | **Breach** and its door; 2 Scavs. |
| armory | 10,2 | 1×1 | **Maul**; 1 Riot unit. |
| armory_chute | 10,3 | 1×1 | 1 Scav; leads to the grate. |
| catwalks | 13,1 | 2×2 | **Sidewinder gate 2** → **rivet gun**; below: **tease 2**, **RAM up**; 3 drones, 2 Scavs. |
| roof_gap | 9,0 | 1×1 | **Sidewinder gate 1** over a void; 1 drone. |
| collections_lift | 10,-1 | 1×2 | Shaft; 1 Riot unit, 1 drone. |
| collections_lobby | 11,-1 | 1×1 | **Terminal 3**, **tease 3**. |
| collections | 12,-1 | 2×1 | **The Landlord.** |
| gut_stair | 1,4 | 1×1 | 1 Scav; ledges back up. |
| service_tunnel | 0,5 | 3×1 | 3 Scavs, 2 Riot units; live water. |
| gut_pumps | 0,6 | 2×2 | 2 Scavs, 2 drones, 1 Riot; **HP up**; the shaft to the vent. |
| gut_vent | 2,6 | 1×1 | **Nailgun** (hidden). |
| gut_lift | 2,7 | 1×2 | The second Breach door; 1 drone; the cistern door at the bottom. |
| gut_cistern | 1,8 | 1×1 | **Gloves**, **RAM up** (hidden). |
| defaulter_den | 3,7 | 2×1 | **The Elite Scav**, 2 Scavs, **the memory chip**. |
| gut_deep | 5,7 | 1×1 | **Sidewinder** (sealed); 1 Riot, 2 Scavs. |
| drain_riser | 6,4 | 1×4 | The freight lift; 2 Scavs, 2 drones; the grate. |

Enemy letters in the specs (`d`, `r`, `E`, `B`) are placed now and
instanced once M6 ships their scenes; the generator skips a letter whose
scene does not exist and says so.

## The spec format

```
room hall_13
name Floor 13 - Hall
cell 6 2
size 2 1
door 1 stairwell_east 2        digit → target room, target door
marker S save                  a char in the grid → what stands there
marker c sign VESTA CARE TERMINAL\nRestoration is a service.
gate shaft 14 17 1 13          what the tests measure
requires 3 mag_hook            what a door (or marker) needs
oneway 1                       a door this room cannot be left through (a drop, a grate)
grid
####...
```

Grid characters: `#` solid, `.` air, `=` one-way ledge, `~` live water
(damage + bounce out), `v` void (damage + back to the last safe ground),
digits doors, `P` the player start, `e d r E B` enemies. Marker types:
`save`, `npc`, `sign` (`!` prefix for red), `notice`, `tease`, `grate <id>
<side>`, `breach_door <id>`, `item`, `hack`, `ability`, `hp_up`, `ram_up`,
`quest_item`, `lift <width> <top_row>`.

## Decisions made here

- **Death**: respawn at the last care terminal with everything kept; the
  room reloads so enemies come back (DESIGN.md §7's slice default). With no
  terminal used yet, back to 14-C.
- **Vertical doors** are drops. Arriving from above you fall in; arriving
  from below (a shaft top) you are placed *beside* the hole with your
  momentum, never back down through it.
- **The Sidewinder gate over the roof gap is a void**, not a death: falling
  short returns you to the lip with damage. Losing a terminal's worth of
  progress for testing a gap would teach players not to test gaps.
- **The drain riser is a freight lift**, not a ladder of ledges — four
  cells of shaft is 28 wall jumps, and the way back to the hub after the
  Sidewinder should feel like a reward, not a chore.
- **Two shortcut grates** rather than one: the armory loop back to the east
  lift, and the riser back to the underpass. Both are stat-check-free and
  open from the far side only.
