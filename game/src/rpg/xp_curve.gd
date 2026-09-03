class_name XPCurve
extends Resource
## The level thresholds (docs/rpg/stats-and-curves.md, XP curve).
##
##     xp_to_next(level) = round(base_xp × growth^(level − 1))
##
## Two constants rather than a hand-authored table, because the curve was
## solved against an *assumed* district XP total and M5 has to re-solve it
## against the real one. A table would make that a twelve-number edit with
## twelve chances to break the shape; this way it is one number.
##
## `assumed_district_xp` is stored here rather than left in the doc so the
## assumption is executable: `tests/test_xp_curve.gd` checks that reaching
## level 6 still costs the right *fraction* of the district's XP, and fails
## loudly when the roster moves. That test is the whole reason it was safe to
## solve this curve before M5 and M6 exist.

## XP for the first level-up. The knob M5 re-solves.
@export var base_xp: int = 60
## Per-level multiplier on the requirement.
@export var growth: float = 1.5
## Backstop only. The slice cannot reach 7 (1248 XP against a 959-XP
## district), so this exists to bound the level-up loop, not to cap anything a
## player will meet.
@export var max_level: int = 99

@export_group("The assumption this was solved against")
## Total XP the district is expected to contain — the roster table in
## docs/rpg/stats-and-curves.md. Not gameplay data: it is the recorded
## premise, and it is what the guard test compares against.
@export var assumed_district_xp: int = 959


## XP needed to get from `level` to `level + 1`.
func xp_to_next(level: int) -> int:
	if level < 1 or level >= max_level:
		return 0
	return roundi(float(base_xp) * pow(growth, float(level - 1)))


## Total XP needed to *reach* `level` from a fresh start. Level 1 is free.
func cumulative_to(level: int) -> int:
	var total: int = 0
	for step: int in range(1, level):
		total += xp_to_next(step)
	return total


## The level a given lifetime XP total buys. Inverse of `cumulative_to`.
func level_for(total_xp: int) -> int:
	var level: int = 1
	while level < max_level and total_xp >= cumulative_to(level + 1):
		level += 1
	return level
