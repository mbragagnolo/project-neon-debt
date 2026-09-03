class_name Weapon
extends Item
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

## `weapon_power` — the base the stat multiplier scales at step 4.
@export var power: float = 1.0
## Attacks per second. Authoritative: the animation is fitted to the cooldown,
## never the reverse.
@export var attack_speed: float = 1.0
## px/s impulse on a staggering hit. Flat per weapon, never derived from
## damage — deriving it couples two tuning axes and makes fast weapons feel
## weightless exactly when they need to stick.
@export var knockback: float = 0.0


## Damage for one landed hit at the given attacking stat, before the target's
## DEF. The equip screen's DMG/HIT reads this rather than `power`, so what the
## screen shows and what the pipeline computes cannot drift apart
## (docs/ui/screens.md, rule 4).
func damage_at(stat: int, config: CombatConfig) -> int:
	return roundi(power * Damage.stat_multiplier(
		stat, config.stat_max_bonus, config.stat_half_point
	))


## Damage per second at the given stat, ignoring DEF. Shown next to
## `damage_at` and never instead of it: the trio is built on the speed axis,
## and either number alone argues for the wrong weapon.
func dps_at(stat: int, config: CombatConfig) -> float:
	return float(damage_at(stat, config)) * attack_speed


## Seconds between attacks. The one place `attack_speed` becomes time.
func cooldown() -> float:
	if attack_speed <= 0.0:
		return 0.0
	return 1.0 / attack_speed
