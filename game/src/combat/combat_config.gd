class_name CombatConfig
extends Resource
## Every number the damage pipeline reads (docs/combat/damage-pipeline.md).
##
## Same rule as `MovementConfig`: the pipeline owns no magic numbers, it asks
## this resource. Tuning combat feel is an inspector session while the game
## runs, not a code change.
##
## Everything here is `TUNE` — these are M2's own tuning pass, and the exit
## test ("fighting 3 Scavs is legible and satisfying") is what closes them.

@export_group("Hitstop")
## Frames held on a normal hit. DESIGN.md §3.2 budgets ~2–3.
@export var hitstop_light_frames: int = 2
## Frames held on a heavy hit. The gap between this and light is what makes
## the maul feel unlike the blade.
@export var hitstop_heavy_frames: int = 4
## Damage at or above this counts as heavy. Sits under the maul's 18 and over
## the wrench's 8 (items.md), so the trio reads as three distinct weights.
@export var hitstop_heavy_threshold: int = 12
## Safety cap. Hitstop is real-time, so a runaway value would freeze the game
## rather than slow it; this bounds the damage a bad number can do.
@export var hitstop_max_seconds: float = 0.5

@export_group("Knockback")
## Multiplier applied to knockback when a hit lands but fails to stagger.
## This is what makes `stagger_threshold` visible without any UI.
@export var flinch_knockback_mult: float = 0.25
## px/s pushed into the player on hurt. Deliberately its own (much smaller)
## number: enemy knockback is juice, player knockback is loss of control.
@export var player_hurt_knockback: float = 220.0

@export_group("I-frames")
## Seconds of invulnerability granted to the player on hurt. Enemies never get
## timed i-frames — they get per-swing multi-hit rejection instead.
@export var player_iframe_time: float = 0.7
## Flashes per second while invulnerable. An i-frame window the player cannot
## see is indistinguishable from the hitbox missing.
@export var iframe_flash_hz: float = 12.0

@export_group("Contact damage")
## Enemy contact damage as a fraction of `attack_power` (characters/enemies.md
## locks this at half).
@export var contact_damage_mult: float = 0.5

@export_group("Stat scaling")
## The saturating curve from docs/rpg/stats-and-curves.md. Lives here because
## M2's pipeline needs it and M3 owns stats; when M3 lands a real stat sheet,
## these two move with it.
## The most a stat can ever add (asymptote ×3.0 total, never reached).
@export var stat_max_bonus: float = 2.0
## Stat value at which half of `stat_max_bonus` is earned.
@export var stat_half_point: float = 40.0


## Frames to hold for a hit of `damage`. Floor-1 hits get nothing: a freeze
## reporting an impact the health bar disagrees with is a lie, and silence
## teaches "wrong tool" faster than a number does.
func hitstop_frames_for(damage: int) -> int:
	if damage <= 1:
		return 0
	return hitstop_heavy_frames if damage >= hitstop_heavy_threshold else hitstop_light_frames
