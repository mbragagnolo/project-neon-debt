# Feel log: one row per knob tried

| date | knob | from | to | moved | targets | applied | why |
|---|---|---|---|---|---|---|---|
| 2026-09-15 | coyote_time | 0.1 | 0.133 | coyote_frames 4 to 5; coyote_ms 66.7 to 83.3 | none | no | the design says about 0.1 s of coyote; the pressable window measured 4 frames of 6, so 0.133 s should give 6 |
| 2026-09-15 | fall_gravity_multiplier | 1.6 | 1.0 | jump_airtime_frames 39 to 44; jump_fall_frames 18 to 23; jump_fall_rise_ratio 0.86 to 1.1; hop_1_airtime_frames 20 to 22; hop_1_fall_frames 10 to 12; hop_2_airtime_frames 21 to 24 ... | jump_fall_rise_ratio PASS to MISS | no | priced for reference: a symmetric arc |
| 2026-09-15 | jump_time_to_apex | 0.36 | 0.28 | jump_height 175.9 to 178.2; jump_rise_frames 21 to 16; jump_airtime_frames 39 to 31; jump_fall_frames 18 to 15; jump_fall_rise_ratio 0.86 to 0.94; run_jump_height 175.9 to 178.2 ... | jump_rise_frames PASS to MISS | no | priced for reference: a snappier jump at the same height |
| 2026-09-15 | player_hurt_knockback | 220 | 600 | knockback_distance 3.3 to 32.7; knockback_frames 2 to 7; knockback_speed 140 to 520; knockback_held_distance 1.2 to 15; knockback_held_frames 1 to 4 | knockback_distance MISS to PASS | no | priced for reference: what it takes for a hit to move the player a quarter tile |
