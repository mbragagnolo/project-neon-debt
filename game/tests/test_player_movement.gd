extends GutTest
## Behavioural tests for the M1 controller.
##
## These drive real input through real physics steps and measure the result,
## because the thing worth protecting is not "the code calls jump_velocity()" —
## it is "the jump goes as high as the config says, the coyote window is as
## long as the config says". Those are the numbers Marcos will tune by feel,
## and a regression in them is invisible until someone plays.
##
## Tolerances are generous on purpose: the engine integrates gravity per step,
## so a discrete apex overshoots the analytic one by roughly v0*dt/2.

const FLOOR_TOP := 600.0

var _config: MovementConfig
var _root: Node2D
var _player: Player


func before_each() -> void:
	TestArena.release_all_input()
	_config = load("res://src/player/movement_config.tres")
	_root = Node2D.new()
	add_child_autofree(_root)


func after_each() -> void:
	TestArena.release_all_input()


## Wide floor, player standing in the middle of it.
func _standing_start() -> void:
	TestArena.solid(_root, Vector2(0, FLOOR_TOP + 100.0), Vector2(6000, 200))
	_player = TestArena.player(_root, Vector2(0, FLOOR_TOP))
	await wait_frames(3)


func _hold(action: String) -> void:
	Input.action_press(action)


func _release(action: String) -> void:
	Input.action_release(action)


## Runs `frames` physics steps and returns the highest point reached (smallest
## y, since y grows downward).
func _apex_over(frames: int) -> float:
	var highest: float = _player.position.y
	for _i: int in frames:
		await wait_frames(1)
		highest = minf(highest, _player.position.y)
	return highest


# --- Ground movement --------------------------------------------------------

func test_player_starts_idle_on_the_floor() -> void:
	await _standing_start()
	assert_true(_player.is_on_floor())
	assert_eq(_player.state_name(), &"Idle")


func test_falls_and_lands() -> void:
	TestArena.solid(_root, Vector2(0, FLOOR_TOP + 100.0), Vector2(6000, 200))
	_player = TestArena.player(_root, Vector2(0, FLOOR_TOP - 400.0))
	await wait_frames(60)
	assert_true(_player.is_on_floor(), "player never landed")
	assert_almost_eq(_player.position.y, FLOOR_TOP, 2.0)


func test_running_reaches_configured_top_speed() -> void:
	await _standing_start()
	_hold("move_right")
	await wait_frames(30)
	assert_almost_eq(_player.velocity.x, _config.run_speed, 1.0)
	assert_eq(_player.state_name(), &"Run")
	assert_eq(_player.facing, 1)


func test_running_left_flips_facing() -> void:
	await _standing_start()
	_hold("move_left")
	await wait_frames(30)
	assert_almost_eq(_player.velocity.x, -_config.run_speed, 1.0)
	assert_eq(_player.facing, -1)


func test_releasing_input_decelerates_to_a_stop() -> void:
	await _standing_start()
	_hold("move_right")
	await wait_frames(30)
	_release("move_right")
	await wait_frames(30)
	assert_almost_eq(_player.velocity.x, 0.0, 0.001)
	assert_eq(_player.state_name(), &"Idle")


func test_turning_around_is_faster_than_stopping() -> void:
	# DESIGN.md §3.1 asks for an instant turn, so a reversal must beat the
	# plain deceleration rate.
	await _standing_start()
	_hold("move_right")
	await wait_frames(30)
	_release("move_right")
	_hold("move_left")
	var frames_to_reverse: int = 0
	while _player.velocity.x > 0.0 and frames_to_reverse < 60:
		await wait_frames(1)
		frames_to_reverse += 1
	var stopping_frames: float = _config.run_speed / _config.ground_deceleration * 60.0
	assert_lt(float(frames_to_reverse), stopping_frames,
		"reversing should be quicker than decelerating to a stop")


# --- Jump -------------------------------------------------------------------

func test_jump_reaches_the_configured_height() -> void:
	await _standing_start()
	_hold("jump")
	var apex: float = await _apex_over(45)
	assert_almost_eq(FLOOR_TOP - apex, _config.jump_height, 20.0)


func test_releasing_jump_early_gives_a_shorter_hop() -> void:
	await _standing_start()
	_hold("jump")
	await wait_frames(4)
	_release("jump")
	var apex: float = await _apex_over(45)
	var height: float = FLOOR_TOP - apex
	assert_lt(height, _config.jump_height * 0.7,
		"a clipped jump should be clearly shorter than a full one")
	assert_gt(height, 0.0)


func test_jump_returns_to_the_floor() -> void:
	await _standing_start()
	_hold("jump")
	await wait_frames(2)
	_release("jump")
	await wait_frames(90)
	assert_true(_player.is_on_floor())
	assert_almost_eq(_player.position.y, FLOOR_TOP, 2.0)


func test_cannot_jump_again_while_airborne() -> void:
	await _standing_start()
	_hold("jump")
	await wait_frames(2)
	_release("jump")
	await wait_frames(20)
	var height_before: float = _player.position.y
	_hold("jump")
	await wait_frames(1)
	assert_gte(_player.position.y, height_before - 1.0,
		"a second jump press in mid-air must do nothing in V1 — there is no double jump")


# --- Coyote time and jump buffering ----------------------------------------

## Ledge ending at x = 0, so the player walks right off into open air.
func _ledge_start() -> void:
	TestArena.solid(_root, Vector2(-1500, FLOOR_TOP + 100.0), Vector2(3000, 200))
	_player = TestArena.player(_root, Vector2(-200, FLOOR_TOP))
	await wait_frames(3)


func test_coyote_time_allows_a_jump_just_after_walking_off() -> void:
	await _ledge_start()
	_hold("move_right")
	while _player.is_on_floor():
		await wait_frames(1)
	# One frame into the fall — comfortably inside the ~0.1s window.
	var y_at_edge: float = _player.position.y
	_hold("jump")
	var apex: float = await _apex_over(40)
	assert_lt(apex, y_at_edge - _config.jump_height * 0.5,
		"the coyote jump did not fire")


func test_coyote_window_expires() -> void:
	await _ledge_start()
	_hold("move_right")
	while _player.is_on_floor():
		await wait_frames(1)
	# Wait out the window with a healthy margin, then try.
	await wait_frames(int(_config.coyote_time * 60.0) + 6)
	var y_before: float = _player.position.y
	_hold("jump")
	await wait_frames(2)
	assert_gt(_player.position.y, y_before,
		"jump fired after the coyote window should have closed")


func test_jump_pressed_before_landing_fires_on_touchdown() -> void:
	TestArena.solid(_root, Vector2(0, FLOOR_TOP + 100.0), Vector2(6000, 200))
	_player = TestArena.player(_root, Vector2(0, FLOOR_TOP - 300.0))
	await wait_frames(3)
	# Fall until we are within the buffer window of the floor, then press.
	while _player.position.y < FLOOR_TOP - 60.0:
		await wait_frames(1)
	_hold("jump")
	await wait_frames(1)
	_release("jump")
	var apex: float = await _apex_over(45)
	assert_lt(apex, FLOOR_TOP - 20.0, "the buffered jump was dropped on landing")


# --- Dash -------------------------------------------------------------------
#
# `Input.action_press` lands its edge on the *next* physics frame, and the test
# coroutine and the player both run inside that frame in an order GUT does not
# promise. So every dash test drives the button and then watches the state
# across frames rather than asserting one frame after the press — and asserts
# the dash actually fired before asserting anything about how it ends, so a
# dash that silently never starts fails instead of passing.

## Taps dash and reports how many physics frames the Dash state lasted.
## 0 means it never fired.
func _tap_dash_and_count_frames() -> int:
	Input.action_press("dash")
	var dash_frames: int = 0
	var seen: bool = false
	for _i: int in 60:
		await wait_frames(1)
		if _player.state_name() == &"Dash":
			seen = true
			dash_frames += 1
		elif seen:
			break
	Input.action_release("dash")
	return dash_frames


func test_dash_reaches_dash_speed() -> void:
	await _standing_start()
	Input.action_press("dash")
	await wait_frames(2)
	Input.action_release("dash")
	assert_eq(_player.state_name(), &"Dash", "dash never fired")
	assert_almost_eq(absf(_player.velocity.x), _config.dash_speed(), 1.0)


func test_dash_lasts_its_configured_duration() -> void:
	await _standing_start()
	var frames: int = await _tap_dash_and_count_frames()
	assert_gt(frames, 0, "dash never fired")
	assert_almost_eq(float(frames), _config.dash_duration * 60.0, 2.0)


func test_dash_suspends_gravity() -> void:
	TestArena.solid(_root, Vector2(0, FLOOR_TOP + 100.0), Vector2(6000, 200))
	_player = TestArena.player(_root, Vector2(0, FLOOR_TOP - 1200.0))
	await wait_frames(3)
	Input.action_press("dash")
	await wait_frames(2)
	Input.action_release("dash")
	assert_eq(_player.state_name(), &"Dash", "air dash never fired")
	assert_almost_eq(_player.velocity.y, 0.0, 0.001,
		"a dash should hang, not keep falling")


func test_dash_goes_the_way_the_player_faces() -> void:
	await _standing_start()
	_hold("move_left")
	await wait_frames(20)
	_release("move_left")
	Input.action_press("dash")
	await wait_frames(2)
	Input.action_release("dash")
	assert_eq(_player.state_name(), &"Dash", "dash never fired")
	assert_lt(_player.velocity.x, 0.0, "dash went the wrong way")


func test_dash_ends_and_bleeds_off_to_run_speed() -> void:
	await _standing_start()
	var frames: int = await _tap_dash_and_count_frames()
	assert_gt(frames, 0, "dash never fired")
	assert_ne(_player.state_name(), &"Dash")
	assert_lte(absf(_player.velocity.x), _config.run_speed + 1.0,
		"dash should bleed off to run speed, not keep dash speed")


func test_dash_respects_its_cooldown() -> void:
	await _standing_start()
	var first: int = await _tap_dash_and_count_frames()
	assert_gt(first, 0, "the first dash never fired")
	# Ask again immediately: the cooldown has not run down yet.
	var second: int = await _tap_dash_and_count_frames()
	assert_eq(second, 0, "dash fired while on cooldown")


func test_dash_is_available_again_after_the_cooldown() -> void:
	await _standing_start()
	assert_gt(await _tap_dash_and_count_frames(), 0, "the first dash never fired")
	await wait_frames(int(_config.dash_cooldown * 60.0) + 4)
	assert_gt(await _tap_dash_and_count_frames(), 0, "dash never came back off cooldown")


func test_air_dash_is_limited_to_one_per_airtime() -> void:
	if not _config.can_dash_in_air:
		pass_test("air dash is disabled in the shipped config")
		return
	# A long drop, so the whole test happens without touching the floor.
	TestArena.solid(_root, Vector2(0, FLOOR_TOP + 100.0), Vector2(6000, 200))
	_player = TestArena.player(_root, Vector2(0, FLOOR_TOP - 4000.0))
	await wait_frames(3)
	assert_gt(await _tap_dash_and_count_frames(), 0, "the first air dash never fired")
	await wait_frames(int(_config.dash_cooldown * 60.0) + 4)
	assert_false(_player.is_on_floor(), "test needs the player still airborne")
	assert_eq(await _tap_dash_and_count_frames(), 0,
		"a second air dash fired without landing first")


func test_landing_refunds_the_air_dash() -> void:
	if not _config.can_dash_in_air:
		pass_test("air dash is disabled in the shipped config")
		return
	TestArena.solid(_root, Vector2(0, FLOOR_TOP + 100.0), Vector2(6000, 200))
	_player = TestArena.player(_root, Vector2(0, FLOOR_TOP - 600.0))
	await wait_frames(3)
	assert_gt(await _tap_dash_and_count_frames(), 0, "the air dash never fired")
	await wait_until(func() -> bool: return _player.is_on_floor(), 5.0)
	assert_true(_player.is_on_floor(), "player never landed")
	await wait_frames(int(_config.dash_cooldown * 60.0) + 4)
	assert_gt(await _tap_dash_and_count_frames(), 0, "landing did not refund the dash")


# --- Wall slide and wall jump ----------------------------------------------

## A wall on the right at x = 100, player falling beside it.
func _wall_start() -> void:
	TestArena.solid(_root, Vector2(0, FLOOR_TOP + 100.0), Vector2(6000, 200))
	TestArena.solid(_root, Vector2(200, FLOOR_TOP - 500.0), Vector2(200, 900))
	_player = TestArena.player(_root, Vector2(40, FLOOR_TOP - 700.0))
	await wait_frames(3)


func test_wall_slide_caps_fall_speed() -> void:
	await _wall_start()
	_hold("move_right")
	await wait_frames(30)
	assert_eq(_player.state_name(), &"WallSlide", "player did not grab the wall")
	assert_almost_eq(_player.velocity.y, _config.wall_slide_speed, 1.0)


func test_wall_slide_needs_input_into_the_wall() -> void:
	await _wall_start()
	# Drift into the wall without holding toward it.
	_player.velocity.x = 400.0
	await wait_frames(20)
	assert_ne(_player.state_name(), &"WallSlide",
		"brushing a wall should not grab it")


func test_wall_jump_pushes_away_from_the_wall() -> void:
	await _wall_start()
	_hold("move_right")
	await wait_frames(30)
	assert_eq(_player.state_name(), &"WallSlide")
	var y_before: float = _player.position.y
	_hold("jump")
	await wait_frames(2)
	assert_lt(_player.velocity.x, 0.0, "wall jump should kick away from the wall")
	assert_lt(_player.velocity.y, 0.0, "wall jump should carry upward")
	assert_eq(_player.facing, -1, "player should face away from the wall")
	await wait_frames(10)
	assert_lt(_player.position.y, y_before, "wall jump gained no height")


func test_wall_stick_holds_briefly_after_releasing() -> void:
	await _wall_start()
	_hold("move_right")
	await wait_frames(30)
	assert_eq(_player.state_name(), &"WallSlide")
	_release("move_right")
	await wait_frames(2)
	assert_eq(_player.state_name(), &"WallSlide",
		"letting go for two frames should not drop the player off the wall")
	await wait_frames(int(_config.wall_stick_time * 60.0) + 4)
	assert_eq(_player.state_name(), &"Air", "the stick timer never expired")
