class_name Damage
extends RefCounted
## The one ordered pipeline (docs/combat/damage-pipeline.md).
##
## Pure math and pure decisions — nothing here touches the tree, applies a
## number or emits a signal, so the steps that decide *how much* can be tested
## without a scene. `Hitbox` owns steps 1–2 (overlap, multi-hit rejection) and
## `Hurtbox` owns steps 7–11 (apply, juice, interlocks, death); this file is
## the middle, and the reason "does DEF apply before or after the floor" has a
## single answer.

## The saturating curve from docs/rpg/stats-and-curves.md:
##
##     1 + max_bonus × stat / (stat + half_point)
##
## Saturating rather than linear so the soft cap bounds damage forever and
## enemy HP tuned for the slice survives V2's manual allocation.
static func stat_multiplier(stat: int, max_bonus: float, half_point: float) -> float:
	if stat <= 0:
		return 1.0
	return 1.0 + max_bonus * float(stat) / (float(stat) + half_point)


## Step 4. Enemies skip the multiplier entirely — flat `attack_power`, so what
## an encounter author types is what the thing hits for.
static func raw_damage(attack: Attack, config: CombatConfig) -> float:
	if not attack.scales_with_stat:
		return attack.power
	return attack.power * stat_multiplier(
		attack.stat, config.stat_max_bonus, config.stat_half_point
	)


## Step 6. Flat subtraction, floor at 1, universal and with zero exceptions.
##
## The floor means every landed hit does something: DEF can never make a
## target unhittable with the "wrong" verb, and chip-killing a tank one point
## at a time stays a legitimate desperate tactic rather than a softlock.
##
## Rounds after subtracting, matching the spec's formula literally — `max(1,
## 7×1.4 − 3)` is the mental arithmetic a solo tuner does in a spreadsheet.
static func final_damage(raw: float, defense: int) -> int:
	return maxi(1, roundi(raw - float(defense)))


## Steps 3–8, minus the application itself. Returns what *would* happen so the
## caller can decide whether to make it happen.
static func resolve(attack: Attack, health: Health, config: CombatConfig) -> DamageResult:
	# Step 3 — dead things and invulnerable things are not targets.
	if health.is_dead() or health.is_invulnerable():
		return DamageResult.rejected(DamageResult.Rejection.INVULNERABLE)

	# Step 4 — weapon is the base, the stat is a multiplier.
	var raw: float = raw_damage(attack, config)

	# Step 5 — positional immunity, checked *before* DEF. A blocked frontal
	# hit is rejected outright, not ground down to the floor of 1; otherwise
	# the shield leaks chip damage and the tag reads as a lie.
	if health.blocks(attack):
		return DamageResult.rejected(DamageResult.Rejection.IMMUNE)

	# Step 6 — DEF, then the floor.
	var amount: int = final_damage(raw, health.defense)

	# Step 8 — one field, one comparison. Contact never staggers.
	var did_stagger: bool = not attack.is_contact and amount >= health.stagger_threshold

	return DamageResult.hit(amount, did_stagger)
