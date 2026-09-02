# player/

The controller, its state machine, and `movement_config.tres`.

**Rule:** no movement constant is allowed to live in code. Everything the
controller reads comes from `MovementConfig` so tuning is an inspector session,
not a code change (DESIGN.md §3.1).

## The split

- `player.gd` owns the **physics**: velocity, gravity, the feel timers (coyote,
  jump buffer, dash cooldown, wall-jump lockout) and the helpers that act on
  them. Input edges are sampled once per frame here, so two states can never
  disagree about whether a button was tapped.
- `states/` owns the **decisions**: which helper runs this frame. A state's
  `physics_update` *returns* the next state rather than switching directly, so
  transitions happen in one place and a test can call it and inspect the answer.

Adding a state (M4's hacks) is one new file plus one child node
under `StateMachine` — the node's name is its id.

## States

| State | Holds while | Notable |
|---|---|---|
| `Idle` / `Run` | On a floor | Share `PlayerGroundState`; they differ only in what they become |
| `Air` | Not on a floor | One state, not Jump + Fall — the rise/fall boundary is the worst possible place for a state change, and there is nothing to switch on |
| `Dash` | 0.16s | No jump cancel: a jump pressed mid-dash is caught by the buffer and fires as the dash ends, which gives dash-jump for free |
| `WallSlide` | Clinging, descending capped | Requires holding *into* the wall; `wall_stick_time` stops a stick-flick from dropping you |
| `MeleeAttack` | `commit_time` (0.16s) | The only attack with a state, because it is the only one that costs commitment. Momentum is kept, not zeroed — swinging while running is the point |

## Combat (M2)

The controller gained a second half, under the same rule: no number in code.
Weapons are `.tres` resources and everything else comes from
`combat_config.tres` (`src/combat/`, spec in
`docs/combat/damage-pipeline.md`).

**Ranged deliberately has no state.** A shot costs a cooldown, never
commitment, so it stays legal while running, jumping, dashing or wall-sliding
— giving it a state would mean five near-identical transitions and would turn
the nailgun's 4/s fire rate into a state-machine problem. Melee gets a state
precisely because it *is* a commitment.

Aim is eight-way off the movement keys: neutral fires along facing, up fires
straight up, up + forward the 45° diagonal, down only while airborne. No new
inputs and no aiming UI — the Watcher drone is a vertical threat, so shooting
upward has to be comfortable.

## Open feel questions for playtest

These are config flags, so flipping them is free:

- `can_dash_in_air` (on) — one air dash per airtime. It changes how wide a gap
  can be, so **decide it before M5 lays out the district**.
- `dash_grants_iframes` (off) — DESIGN.md §3.1 leaves it to playtest.
- `turn_acceleration` — "instant turn" is implemented as a steep acceleration
  rather than a hard snap to zero. Raise it if reversals feel soggy.
