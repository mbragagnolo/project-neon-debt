# Feel: 2026-09-15

Tick 60; body 48x88 px; tile 60 px; 60 trials.

## Since the last run

The first measurement; nothing to diff against.

## Targets

| metric | measured | target | verdict | why |
|---|---|---|---|---|
| coyote_frames | 4 | 4..7 frames | PASS | DESIGN.md 3.1: coyote time about 0.1 s. The pressable window runs two frames under the knob (the walk-off frame and the zero boundary each cost one) |
| buffer_frames | 9 | 8..10 frames | PASS | DESIGN.md 3.1: jump buffering about 0.15 s |
| turn_frames | 3 | 1..4 frames | PASS | DESIGN.md 3.1: instant turn. A reversal whose velocity crosses zero inside four frames reads as instant; one frame would be a snap |
| accel_frames | 8 | 4..12 frames | PASS | DESIGN.md 3.1: slight acceleration. Under a fifth of a second to top speed and more than one frame |
| stop_frames | 6 | 2..8 frames | PASS | DESIGN.md 3.1: slight deceleration. A released stick stops inside a few frames and not on the spot |
| jump_rise_frames | 21 | 18..26 frames | PASS | the jump is authored at 0.36 s to the apex: springy not floaty |
| jump_height | 175.9 | 160..190 px | PASS | the jump is authored at 168 px (2.8 tiles of 60) so a three-tile ledge is a wall; the discrete step adds about v0*dt/2 |
| jump_fall_rise_ratio | 0.86 | 0.60..0.95 ratio | PASS | the fall multiplier is 1.6: the fall is quicker than the rise and the jump lands with weight |
| min_hop_ratio | 0.28 | 0.20..0.45 ratio | PASS | variable height: a one-frame tap hops clearly under half the full jump |
| dash_frames | 10 | 8..12 frames | PASS | the dash is a 0.16 s commitment: a step and not a cutscene |
| dash_jump_press_first | 3 | 1..3 frames | PASS | design.md pillars: the jump-cancelled dash. A jump pressed almost anywhere in the dash fires at its end; the first frame or two may be lost to the buffer |
| landing_lag_frames | 1 | 0..1 frames | PASS | no landing lag: the run is back at speed on touchdown |
| wall_slide_speed | 120 | 100..140 px/s | PASS | the slide is authored at 120 px/s: a wall is a place to think |
| ladder_rate | 89.7 | 0..144 px/s | PASS | DESIGN.md 3.1 (2026-09-15): a single wall is a slow ladder at under a wall jump's height (144 px) per second |
| hitstop_light_frames | 2 | 2..3 frames | PASS | docs/combat/damage-pipeline.md: light hitstop 2 frames; short or it is lag |
| hitstop_heavy_frames | 4 | 3..5 frames | PASS | docs/combat/damage-pipeline.md: heavy hitstop 4 frames; the difference from light is the weight |
| knockback_distance | 3.30 | 15..60 px | **MISS** | docs/combat/damage-pipeline.md: player knockback is loss of control on a small budget |
| knockback_frames | 2 | 2..8 frames | PASS | the same: a hit costs a few frames of control and not a dozen |

1 MISS of 18.

## The numbers

Measured against the model (what the knobs' arithmetic expects); tiles where the unit is px.

### Run

| metric | measured | model | unit | tiles |
|---|---|---|---|---|
| top_speed | 450 | 450 | px/s |  |
| accel_frames | 8 | 7.50 | frames |  |
| accel_distance | 34.5 | 28.1 | px | 0.57 |
| stop_frames | 6 | 5.62 | frames |  |
| stop_distance | 17.5 | 21.1 | px | 0.29 |
| turn_frames | 3 | 3 | frames |  |
| turn_to_speed_frames | 11 |  | frames |  |

### Jump

| metric | measured | model | unit | tiles |
|---|---|---|---|---|
| jump_height | 175.9 | 168 | px | 2.93 |
| jump_rise_frames | 21 | 21.6 | frames |  |
| jump_fall_frames | 18 | 17.1 | frames |  |
| jump_airtime_frames | 39 | 38.7 | frames |  |
| jump_fall_rise_ratio | 0.86 |  | ratio |  |
| hop_1_height | 50 |  | px | 0.83 |
| hop_2_height | 61.7 |  | px | 1.03 |
| hop_4_height | 83.4 |  | px | 1.39 |
| hop_8_height | 120.1 |  | px | 2 |
| min_hop_ratio | 0.28 |  | ratio |  |
| harness_latency_frames | 1 |  | frames |  |

### Coyote and buffer

| metric | measured | model | unit | tiles |
|---|---|---|---|---|
| coyote_frames | 4 | 6 | frames |  |
| coyote_ms | 66.7 |  | ms |  |
| buffer_frames | 9 | 9 | frames |  |
| buffer_ms | 150 |  | ms |  |

### Dash

| metric | measured | model | unit | tiles |
|---|---|---|---|---|
| dash_speed | 1800 | 1800 | px/s |  |
| dash_frames | 10 | 9.60 | frames |  |
| dash_distance | 300 | 288 | px | 5 |
| dash_exit_speed | 450 |  | px/s |  |
| dash_cooldown_frames | 32 | 30 | frames |  |
| dash_jump_press_first | 3 |  | frames |  |
| dash_jump_press_last | 10 |  | frames |  |
| dash_jump_distance | 608.5 | 578.1 | px | 10.1 |
| dash_jump_flight_distance | 292.5 |  | px | 4.88 |
| dash_jump_height | 175.9 |  | px | 2.93 |

### Running jump and air dash

| metric | measured | model | unit | tiles |
|---|---|---|---|---|
| run_jump_distance | 292.5 | 290.1 | px | 4.88 |
| run_jump_height | 175.9 | 168 | px | 2.93 |
| run_jump_airtime_frames | 39 |  | frames |  |
| air_dash_distance | 607.5 | 578.1 | px | 10.1 |
| air_dash_airtime_frames | 51 |  | frames |  |
| air_dash_early_distance | 405 |  | px | 6.75 |
| air_dash_early_height | 58 |  | px | 0.97 |

### Fall and landing

| metric | measured | model | unit | tiles |
|---|---|---|---|---|
| terminal_velocity | 1200 | 1200 | px/s |  |
| terminal_frames | 17 | 17.4 | frames |  |
| drop_impact_speed | 1200 |  | px/s |  |
| landing_lag_frames | 1 |  | frames |  |
| drop_landing_lag_frames | 1 |  | frames |  |

### Wall

| metric | measured | model | unit | tiles |
|---|---|---|---|---|
| wall_grab_frame | 5 |  | frames |  |
| wall_slide_speed | 120 | 120 | px/s |  |
| wall_jump_height | 151.2 | 144 | px | 2.52 |
| wall_jump_rise_frames | 20 | 20 | frames |  |
| wall_jump_push_speed | 420 | 420 | px/s |  |
| wall_jump_reach | 271.2 | 265 | px | 4.52 |
| wall_jump_neutral_reach | 101.5 | 50.4 | px | 1.69 |
| wall_jump_tap_height | 43.9 |  | px | 0.73 |
| wall_jump_tap_reach | 138.1 |  | px | 2.30 |
| shaft_width_max | 300 |  | px | 5 |
| shaft_gain_per_kick_widest | 12.9 |  | px | 0.21 |
| shaft_climb_rate_widest | 21.5 |  | px/s |  |
| shaft_climb_rate | 409.2 |  | px/s |  |
| shaft_climb_rate_width | 200 |  | px | 3.33 |
| ladder_gain_per_kick | 23.2 |  | px | 0.39 |
| ladder_frames_per_kick | 15.5 |  | frames |  |
| ladder_rate | 89.7 |  | px/s |  |

### Hit-stop and knockback

| metric | measured | model | unit | tiles |
|---|---|---|---|---|
| hitstop_light_requested | 2 |  | frames |  |
| hitstop_light_frames | 2 | 2 | frames |  |
| hitstop_light_fixed_frames | 87 |  | frames |  |
| hitstop_heavy_requested | 4 |  | frames |  |
| hitstop_heavy_frames | 4 | 4 | frames |  |
| hitstop_heavy_fixed_frames | 87 |  | frames |  |
| knockback_speed | 140 | 220 | px/s |  |
| knockback_distance | 3.30 | 5 | px | 0.06 |
| knockback_frames | 2 | 2.75 | frames |  |
| knockback_held_distance | 1.20 |  | px | 0.02 |
| knockback_held_frames | 1 |  | frames |  |

Shafts, by width (inner faces):

| width px | kicks | px a kick | frames a kick | px/s | ends px up | highest | climbs |
|---|---|---|---|---|---|---|---|
| 200 | 14 | 150 | 22 | 409.2 | 2074.2 | 2074.2 | yes |
| 250 | 11 | 109.7 | 29 | 227 | 1188.8 | 1221.1 | yes |
| 300 | 9 | 12.9 | 36 | 21.5 | 200.2 | 324.1 | yes |
| 350 | 7 | 0 | 48 | 0 | 96.9 | 233.8 | no |
| 400 | 6 | 0 | 55 | 0 | 218.6 | 233.8 | no |
| 500 | 5 | 0 | 68 | 0 | 229.4 | 233.8 | no |

## Reach, for the level-designer

Model: game/tools/stacks/reach.json; tile 60 px.

| move | measured px | tiles | model px | tiles | delta px |
|---|---|---|---|---|---|
| running jump, travel | 292.5 | 4.88 | 290.1 | 4.83 | 2.43 |
| running jump, widest gap lip to lip | 340.5 | 5.67 | 338.1 | 5.63 | 2.43 |
| dash, travel | 300 | 5 | 288 | 4.80 | 12 |
| dash then jump, from the dash's start | 608.5 | 10.1 | 578.1 | 9.63 | 30.4 |
| jump then air dash, travel | 607.5 | 10.1 | 578.1 | 9.63 | 29.4 |
| jump then air dash, widest gap lip to lip | 655.5 | 10.9 | 626.1 | 10.4 | 29.4 |
| jump, height | 175.9 | 2.93 | 168 | 2.80 | 7.90 |
| wall jump, height a kick gains | 151.2 | 2.52 | 144 | 2.40 | 7.20 |
| wall jump, reach back at its own height | 271.2 | 4.52 | 265.0 | 4.42 | 6.25 |
| shaft, widest climbed (the macro) | 300 | 5 | 313.0 | 5.22 | -13.0 |

What the census draws from the model, and from the measurement:

| threshold | model px | tiles | measured px | tiles |
|---|---|---|---|---|
| plain jump, widest gap lip to lip | 300.2 | 5 | 308.9 | 5.15 |
| air-dash gate, narrowest valid gap | 381.6 | 6.36 | 393 | 6.55 |
| air-dash gate, widest valid gap | 550.7 | 9.18 | 576.3 | 9.60 |
| step, tallest ledge that is not a wall | 168 | 2.80 | 175.9 | 2.93 |
| wall, shortest ledge that is one (by the margin) | 193.2 | 3.22 | 202.3 | 3.37 |
| shaft, widest one kick climbs | 278.4 | 4.64 | 283.8 | 4.73 |

- dash, travel: measured 300 px (5.00 tiles) against the model's 288 (4.80): a different whole tile; the census may class a room's gap or ledge differently from the engine
- dash then jump, from the dash's start: measured 608 px (10.14 tiles) against the model's 578 (9.63): a different whole tile; the census may class a room's gap or ledge differently from the engine
- jump then air dash, travel: measured 608 px (10.12 tiles) against the model's 578 (9.63): a different whole tile; the census may class a room's gap or ledge differently from the engine

## Findings

- a jump pressed on any of the first 4 airborne frames after a ledge still fires; the knob says 6 frames. The frame that walks off the ledge and the frame that presses each tick the timer once, so the pressable window is two frames shorter than the knob
- the jump reaches 176 px against 168 authored: +8 px (a discrete step overshoots the analytic apex by about v0*dt/2)
- the dash covers 300 px against 288 authored: +12 px (a duration that is not a whole number of frames runs to the next frame)
- hitstop_light: 2 frames asked, 87 physics frames held at fixed step (still held when the trial ended). The freeze counts wall-clock milliseconds, so at a fixed step it holds for a machine-dependent number of frames; a bot run must pin the time scale at 1, and the design's frames hold only at real time
- hitstop_heavy: 4 frames asked, 87 physics frames held at fixed step (still held when the trial ended). The freeze counts wall-clock milliseconds, so at a fixed step it holds for a machine-dependent number of frames; a bot run must pin the time scale at 1, and the design's frames hold only at real time
- the hurt knockback moves the player 3 px in 2 frames, under a quarter tile: it reads as nothing
- a held stick cancels the hurt knockback in 1 frames: being hit costs no control
- a jump pressed on frames 1..2 of the 10-frame dash is lost (the buffer runs out before the dash ends); presses on frames 3..10 fire at its end
- a single wall climbs at 90 px/s, 23 px a kick (0.62 wall jumps of height per second)
- the widest shaft that climbs (300 px) climbs 13 px a kick, 22 px/s: climbable by the census, a chore by the hands
- dash, travel: measured 300 px (5.00 tiles) against the model's 288 (4.80): a different whole tile; the census may class a room's gap or ledge differently from the engine
- dash then jump, from the dash's start: measured 608 px (10.14 tiles) against the model's 578 (9.63): a different whole tile; the census may class a room's gap or ledge differently from the engine
- jump then air dash, travel: measured 608 px (10.12 tiles) against the model's 578 (9.63): a different whole tile; the census may class a room's gap or ledge differently from the engine

## Trials

| trial | what happened |
|---|---|
| run | top 450 px/s in 8 frames, stop in 6 frames |
| turn | velocity crosses zero 3 frames after the reversal, full speed back in 11 |
| jump | 176 px high, apex at frame 21, lands at 39, 0.0 px along |
| hop_1 | 50 px high, apex at frame 10, lands at 20, 0.0 px along |
| hop_2 | 62 px high, apex at frame 10, lands at 21, 0.0 px along |
| hop_4 | 83 px high, apex at frame 11, lands at 24, 0.0 px along |
| hop_8 | 120 px high, apex at frame 14, lands at 29, 0.0 px along |
| dash | 300.0 px in 10 frames at 1800 px/s |
| dash_cooldown | second dash 32 frames after the first ends |
| dash_jump | 608.5 px from the dash press to the landing |
| run_jump | 176 px high, apex at frame 21, lands at 39, 292.5 px along |
| air_dash | 176 px high, apex at frame 21, lands at 51, 607.5 px along |
| air_dash_early | 58 px high, apex at frame 3, lands at 24, 405.0 px along |
| fall | terminal 1200 px/s by frame 17, lands at 158, running 1 frames late |
| drop | lands at frame 28 |
| wall_slide | grabs at frame 5, slides at 120.0 px/s |
| wall_jump | 151.2 px up, back level 271.2 px out |
| wall_jump_neutral | 151.2 px up, back level 101.5 px out |
| wall_jump_tap | 43.9 px up, back level 138.1 px out |
| shaft_200 | climbs: 150 px a kick, a kick every 22 frames, 409 px/s; ends 2074 px up |
| shaft_250 | climbs: 110 px a kick, a kick every 29 frames, 227 px/s; ends 1189 px up |
| shaft_300 | climbs: 13 px a kick, a kick every 36 frames, 22 px/s; ends 200 px up |
| shaft_350 | does not climb: 7 kicks, +0 px a kick; ends 97 px up |
| shaft_400 | does not climb: 6 kicks, +0 px a kick; ends 219 px up |
| shaft_500 | does not climb: 5 kicks, +0 px a kick; ends 229 px up |
| ladder | a single wall climbs: 23 px a kick every 16 frames, 90 px/s; ends 648 px up |
| hitstop_light | asked 2 frames; held 2 frames (41 ms) at real time; at fixed step 87 frames and still held when the trial ended |
| hitstop_heavy | asked 4 frames; held 4 frames (76 ms) at real time; at fixed step 87 frames and still held when the trial ended |
| knockback | 3.3 px back in 2 frames |
| knockback_held | 1.2 px back against a held stick, forward again after 1 frames |

coyote sweep: 0:fire 1:fire 2:fire 3:fire 4:- 5:- 6:- 7:- 8:- 9:- 10:- 11:- 12:- 13:- 14:- 15:-

buffer sweep: 1:fire 2:fire 3:fire 4:fire 5:fire 6:fire 7:fire 8:fire 9:fire 10:- 11:- 12:- 13:- 14:- 15:- 16:- 17:- 18:- 19:- 20:- 21:-

dash-jump press sweep: 0:fire 1:- 2:- 3:fire 4:fire 5:fire 6:fire 7:fire 8:fire 9:fire 10:fire 11:fire 12:fire 13:fire
