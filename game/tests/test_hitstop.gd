extends GutTest
## The global freeze (docs/combat/damage-pipeline.md, hitstop rules).
##
## The rule worth a test file of its own is rule 2: overlapping hits take the
## maximum remaining, never the sum. Summing is invisible in a one-on-one and
## catastrophic in the three-Scav exit test, where it turns the most
## interesting moment of the fight into a slideshow — and it would present as
## a performance bug rather than as a tuning mistake.
##
## Everything here counts *real* time, because scaled time cannot measure its
## own suspension. Waiting is done on `process_frame` rather than GUT's
## second-based waits, which run on scaled timers and would never fire while
## the engine is held at zero.

const FRAME_MSEC := 1000.0 / 60.0


func before_each() -> void:
	Hitstop.cancel()


func after_each() -> void:
	# A stranded time_scale of 0 is indistinguishable from a hang, and it would
	# take every later test in the suite with it.
	Hitstop.cancel()
	Engine.time_scale = 1.0


## Advances real time without depending on a scaled timer.
func _real_frames(count: int) -> void:
	for _i: int in count:
		await get_tree().process_frame


func test_a_request_freezes_the_engine() -> void:
	Hitstop.request(4)
	assert_true(Hitstop.is_active())
	assert_eq(Engine.time_scale, 0.0, "the whole combat picture holds, not one body")


func test_the_freeze_releases_itself() -> void:
	Hitstop.request(2)
	assert_true(Hitstop.is_active())
	# 2 frames is ~33ms; 20 real frames is a generous margin either way.
	await _real_frames(20)
	assert_false(Hitstop.is_active())
	assert_eq(Engine.time_scale, 1.0)


func test_overlapping_requests_take_the_maximum_not_the_sum() -> void:
	Hitstop.request(2)
	var after_light: int = Hitstop.remaining_msec()
	Hitstop.request(6)
	var after_heavy: int = Hitstop.remaining_msec()

	# The sum would be 8 frames. The max is 6. Anything at or above 8 frames'
	# worth means hits are compounding, which is the slideshow bug.
	assert_gt(after_heavy, after_light, "a longer request must extend the hold")
	assert_lt(
		float(after_heavy),
		8.0 * FRAME_MSEC,
		"overlapping hitstop is summing instead of taking the maximum"
	)


func test_a_shorter_request_never_cuts_a_longer_hold_short() -> void:
	Hitstop.request(6)
	var before: int = Hitstop.remaining_msec()
	Hitstop.request(1)
	assert_gte(Hitstop.remaining_msec(), before - 2, "a light hit truncated a heavy hold")


func test_zero_frames_is_a_no_op() -> void:
	# Floor-1 hits resolve to 0 frames, and must not produce a one-frame stutter.
	Hitstop.request(0)
	assert_false(Hitstop.is_active())
	assert_eq(Engine.time_scale, 1.0)


func test_the_hold_is_capped() -> void:
	var config: CombatConfig = load("res://src/combat/combat_config.tres")
	# Hitstop is real-time, so a bad number would freeze the game rather than
	# slow it. The cap is what bounds the damage a typo can do.
	Hitstop.request(100000)
	assert_lte(float(Hitstop.remaining_msec()), config.hitstop_max_seconds * 1000.0 + 20.0)


func test_the_signal_bus_drives_it() -> void:
	# The pipeline emits rather than calling, so nothing in combat needs to
	# know this autoload exists.
	Events.hitstop_requested.emit(3)
	assert_true(Hitstop.is_active())
