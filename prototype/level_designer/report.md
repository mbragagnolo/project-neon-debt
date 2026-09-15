# Reach check: the Stacks against the envelope

Envelope from movement_config.tres: {'flat jump (px)': 290.1, 'dash (px)': 288.0, 'jump + air dash (px)': 578.1, 'jump height (px)': 168.0, 'wall jump reach (px)': 265.0}
Valid Sidewinder gate: 382px .. 551px lip to lip (6.4 .. 9.2 tiles)
Plain jump: up to 5.0 tiles. Step: up to 2.8 tiles. Shaft the Hook climbs: up to 4.6 tiles wide.

Final kit after the walk: ['breach', 'cyberdeck', 'mag_hook', 'overload', 'sidewinder', 'sidewinder_carried']

## Declared gates, re-judged (mirrors tests/test_stacks.gd)

| room | gate | values | measure | verdict |
|---|---|---|---|---|
| catwalks | air_dash | [5, 17, 21] | 900px lip to lip, widest hop 420px (support 1 down) | valid |
| catwalks | tease | [31, 21] | ledge 8 wide, drops [780, 660]px | out of reach |
| catwalks | shaft | [6, 9, 19, 31] | 240px wide, 13 tall | climbable |
| collections_lift | shaft | [14, 17, 1, 13] | 240px wide, 13 tall | climbable |
| collections_lift | shaft | [14, 17, 17, 31] | 240px wide, 15 tall | climbable |
| collections_lobby | tease | [15, 5] | ledge 8 wide, drops [660, 660]px | out of reach |
| gut_lift | shaft | [8, 11, 17, 31] | 240px wide, 15 tall | climbable |
| gut_pumps | shaft | [56, 59, 18, 31] | 240px wide, 14 tall | climbable |
| gut_pumps | shaft | [3, 6, 1, 13] | 240px wide, 13 tall | climbable |
| lift_shaft | shaft | [14, 17, 5, 13] | 240px wide, 9 tall | climbable |
| lift_shaft | shaft | [14, 17, 17, 34] | 240px wide, 18 tall | climbable |
| mezz_east | shaft | [14, 17, 1, 13] | 240px wide, 13 tall | climbable |
| roof_gap | air_dash | [8, 12, 17] | 480px lip to lip | valid |
| roof_span | tease | [43, 5] | ledge 8 wide, drops [660, 660]px | out of reach |
| stairwell_east | shaft | [14, 17, 1, 13] | 240px wide, 13 tall | climbable |
| stairwell_east | shaft | [14, 17, 17, 31] | 240px wide, 15 tall | climbable |

## Level gaps that are not plain jumps

| room | row | x1..x2 | tiles | widest hop | class | under | declared | crossable on arrival | kit on arrival |
|---|---|---|---|---|---|---|---|---|---|
| catwalks | 17 | 5 | 21 | 15 | 7 (support 1 down) | gate | floor 1 down | yes | NO | mag_hook |
| collections | 12 | 18 | 44 | 25 | 9 (support 2 down) | gate | floor 2 down |  | yes | breach,cyberdeck,mag_hook,overload,sidewinder,sidewinder_carried |
| gut_pumps | 17 | 8 | 16 | 7 | 7 | gate | hazard |  | NO | mag_hook |
| gut_pumps | 17 | 24 | 40 | 15 | 15 | beyond | floor 5 down |  | NO | mag_hook |
| roof_gap | 12 | 8 | 17 | 8 | 8 | gate | void | yes | NO | mag_hook |

Plain gaps not listed: 6

## Ledges that are not steps

| room | base row | base x | side | height (tiles) | facing wall (tiles) | class | kit on arrival |
|---|---|---|---|---|---|---|---|
| catwalks | 35 | 1 | left | 18 | 21 | wall | mag_hook |
| catwalks | 35 | 21 | right | 4 | 21 | wall | mag_hook |
| catwalks | 35 | 26 | left | 4 | 4 | wall+shaft | mag_hook |
| catwalks | 35 | 29 | right | 13 | 4 | wall+shaft | mag_hook |
| catwalks | 35 | 34 | left | 13 | 2 | wall+shaft | mag_hook |
| collections | 17 | 36 | left | 3 | 27 | tight-wall | breach,cyberdeck,mag_hook,overload,sidewinder,sidewinder_carried |
| collections_lift | 35 | 17 | right | 18 | - | wall | breach,cyberdeck,mag_hook,overload,sidewinder,sidewinder_carried |
| east_ledges | 17 | 26 | left | 4 | 26 | wall | mag_hook |
| east_ledges | 17 | 51 | right | 8 | 26 | wall | mag_hook |
| east_ledges | 17 | 56 | left | 8 | - | wall | mag_hook |
| gut_lift | 35 | 30 | right | 18 | - | wall | mag_hook |
| gut_pumps | 35 | 21 | right | 4 | 21 | wall | mag_hook |
| gut_pumps | 35 | 26 | left | 4 | 10 | wall | mag_hook |
| lift_shaft | 35 | 17 | right | 18 | 4 | wall+shaft | mag_hook |
| roof_gap | 17 | 9 | left | 5 | 8 | wall | mag_hook |
| roof_gap | 17 | 16 | right | 5 | 8 | wall | mag_hook |
| roof_span | 17 | 28 | left | 3 | 14 | tight-wall | mag_hook |
| roof_span | 17 | 41 | right | 11 | 14 | wall | mag_hook |
| roof_span | 17 | 46 | left | 11 | 10 | wall | mag_hook |
| roof_span | 17 | 72 | left | 4 | - | wall | mag_hook |
| west_stair | 21 | 30 | right | 4 | 30 | wall | mag_hook |
| west_stair | 39 | 1 | left | 4 | 30 | wall | mag_hook |

Steps not listed: 45

## Findings

- collections: a 3-tile ledge at x35 row 14 (from row 17, left) is a wall by only 12px, under the margin
- gut_pumps: UNDECLARED gate-class gap at row 17 x8..16 (7 tiles, gate) over hazard, reached without the Sidewinder
- gut_pumps: row 17 x24..40 is a one-way drop of 5 tiles (no jump back up the same way)
- roof_span: a 3-tile ledge at x27 row 14 (from row 17, left) is a wall by only 12px, under the margin

map: F:\Projects\Coding Projects\project-neon-debt\prototype\level_designer\district.png
