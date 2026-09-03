class_name Weapon
extends Resource
## What every weapon carries (docs/rpg/items.md).
##
## Same rule as `MovementConfig`: no combat number lives in code. A weapon is a
## `.tres` you edit in the inspector, which is what makes the whole trio
## tunable without touching a script.
##
## `attack_speed` is deliberately a first-class field rather than something
## that falls out of animation length. DPS through armour is
## `(raw − DEF) × attacks_per_second`, so speed is half the balance lever for
## the flat-DEF heavy-hit bias (docs/rpg/stats-and-curves.md) — and it is only
## a usable lever if it is a number someone can type.

@export var display_name: String = ""
## `weapon_power` — the base the stat multiplier scales at step 4.
@export var power: float = 1.0
## Attacks per second. Authoritative: the animation is fitted to the cooldown,
## never the reverse.
@export var attack_speed: float = 1.0
## px/s impulse on a staggering hit. Flat per weapon, never derived from
## damage — deriving it couples two tuning axes and makes fast weapons feel
## weightless exactly when they need to stick.
@export var knockback: float = 0.0


## Seconds between attacks. The one place `attack_speed` becomes time.
func cooldown() -> float:
	if attack_speed <= 0.0:
		return 0.0
	return 1.0 / attack_speed
