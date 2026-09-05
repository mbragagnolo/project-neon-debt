extends GutTest
## The level thresholds, and the assumption they were solved against
## (docs/rpg/stats-and-curves.md, XP curve).
##
## The table test is the ordinary kind: the doc is the contract. The budget
## test below it is the interesting one — it is the reason it was safe to solve
## this curve in M3 at all, before the district and the roster that determine
## its scale exist. It converts "we assumed ~959 XP in the district" from a
## sentence in a doc into something that fails a build.

var _curve: XPCurve


func before_each() -> void:
	_curve = load("res://src/rpg/xp_curve.tres")


func test_thresholds_match_the_locked_table() -> void:
	var expected: Dictionary = {1: 60, 2: 90, 3: 135, 4: 203, 5: 304, 6: 456}
	for level: int in expected:
		assert_eq(_curve.xp_to_next(level), int(expected[level]), "level %d" % level)


func test_cumulative_totals_match_the_locked_table() -> void:
	var expected: Dictionary = {1: 0, 2: 60, 3: 150, 4: 285, 5: 488, 6: 792}
	for level: int in expected:
		assert_eq(_curve.cumulative_to(level), int(expected[level]), "to level %d" % level)


func test_level_for_is_the_exact_inverse_of_cumulative_to() -> void:
	# Off-by-one here is a level-up that fires one XP early or one XP late,
	# which is invisible in play and obvious in a save file.
	for level: int in range(1, 8):
		var threshold: int = _curve.cumulative_to(level)
		assert_eq(_curve.level_for(threshold), level, "exactly at the threshold")
		if level > 1:
			assert_eq(_curve.level_for(threshold - 1), level - 1, "one XP short")


func test_the_first_level_up_arrives_before_the_first_pickup() -> void:
	# items.md pacing: nothing is found in the first ~10 minutes, so the first
	# level-up has to be the thing that opens the game. Six Scavs' worth.
	assert_eq(_curve.xp_to_next(1), 60)
	assert_lte(_curve.xp_to_next(1) / 10, 6, "more than six Scavs to level 2")


# --- The guard on the assumption --------------------------------------------

func test_reaching_level_six_costs_the_right_share_of_the_district() -> void:
	# DESIGN.md §2 wants a finishing player at ~level 5–6. Against the recorded
	# district budget that means level 6 must cost enough that a player who
	# skips fights lands at 5, and little enough that a thorough one gets there
	# — 70–90% of everything the district contains.
	#
	# When M5 lays out real rooms and M6 sets real xp_rewards, this is the test
	# that tells you whether `base_xp` still holds. It failing is not a bug, it
	# is the milestone's homework arriving.
	var share: float = float(_curve.cumulative_to(6)) / float(_curve.assumed_district_xp)
	assert_between(share, 0.70, 0.90, "level 6 costs %.0f%% of the district" % (share * 100.0))


func test_level_seven_is_out_of_reach_in_the_slice() -> void:
	# Not a cap — a consequence. The curve outruns the district, so the slice
	# needs no max-level special case and V2 can extend it without a cliff.
	assert_gt(_curve.cumulative_to(7), _curve.assumed_district_xp)


func test_the_curve_terminates_at_max_level() -> void:
	# The level-up loop trusts this: an unbounded curve plus a debug XP grant
	# is an infinite loop rather than an absurd level. `max_level` is a
	# backstop, not a destination — at 1.5× per level a billion XP is still
	# only level 40, which is the sanity check that the growth is exponential
	# in the direction it is supposed to be.
	assert_eq(_curve.xp_to_next(_curve.max_level), 0)
	assert_lte(_curve.level_for(1_000_000_000), _curve.max_level)
