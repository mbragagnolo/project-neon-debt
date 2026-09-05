extends GutTest
## Possession gates and the movement envelope (DESIGN.md §3.1, §3.4).
##
## Two things are protected. First, that the gated moves are actually gated:
## a player without the Mag-Hook cannot wall jump, and without the Sidewinder
## cannot air dash — the whole district's promise rests on that. Second, that
## the analytic envelope agrees with real physics, so a gate test that trusts
## the arithmetic is trusting something checked against the controller.

const FLOOR_TOP := 600.0

var _config: MovementConfig
var _envelope: MovementEnvelope
var _root: Node2D
var _player: Player


func before_each() -> void:
	TestArena.release_all_input()
	GameState.reset()
	_config = load("res://src/player/movement_config.tres")
	_envelope = MovementEnvelope.new(_config)
	_root = Node2D.new()
	add_child_autofree(_root)


func after_each() -> void:
	TestArena.release_all_input()
	GameState.reset()


func _settle(frames: int) -> void:
	for _i: int in frames:
		await get_tree().physics_frame


## Runs until the player lands or `max_frames` pass; returns the landing x.
func _run_until_landed(max_frames: int = 240) -> float:
	for _i: int in max_frames:
		await get_tree().physics_frame
		if _player.is_on_floor():
			return _player.position.x
	return _player.position.x


# --- Possession ---------------------------------------------------------------

## A wall on the right, player sliding down it.
func _sliding_on_a_wall() -> void:
	TestArena.solid(_root, Vector2(0, FLOOR_TOP + 100.0), Vector2(6000, 200))
	TestArena.solid(_root, Vector2(200, FLOOR_TOP - 500.0), Vector2(200, 900))
	_player = TestArena.player(_root, Vector2(40, FLOOR_TOP - 700.0))
	await wait_frames(3)
	Input.action_press("move_right")
	await _settle(30)
	assert_eq(_player.state_name(), &"WallSlide", "precondition: sliding")


func test_wall_slide_works_from_the_start() -> void:
	# Teaches that walls are interactive before the Hook makes them useful.
	await _sliding_on_a_wall()
	assert_false(GameState.has_ability(GameState.ABILITY_MAG_HOOK))


func test_without_the_mag_hook_there_is_no_wall_jump() -> void:
	await _sliding_on_a_wall()
	var y_before: float = _player.position.y
	Input.action_press("jump")
	await _settle(12)
	assert_gte(_player.position.y, y_before - 2.0, "wall jumped without the Mag-Hook")
	assert_gte(_player.velocity.x, -1.0, "kicked off the wall without the Mag-Hook")


func test_the_mag_hook_grants_the_wall_jump() -> void:
	GameState.grant_ability(GameState.ABILITY_MAG_HOOK)
	await _sliding_on_a_wall()
	var y_before: float = _player.position.y
	Input.action_press("jump")
	await _settle(12)
	assert_lt(_player.position.y, y_before, "the Hook did not grant a wall jump")


func test_without_the_sidewinder_there_is_no_air_dash() -> void:
	TestArena.solid(_root, Vector2(0, FLOOR_TOP + 100.0), Vector2(6000, 200))
	_player = TestArena.player(_root, Vector2(0, FLOOR_TOP - 1500.0))
	await wait_frames(3)
	assert_false(_player.is_on_floor(), "precondition: airborne")
	assert_false(_player.can_dash(), "air dash offered without the Sidewinder")
	Input.action_press("dash")
	await _settle(2)
	assert_ne(_player.state_name(), &"Dash")


func test_the_ground_dash_is_never_gated() -> void:
	TestArena.solid(_root, Vector2(0, FLOOR_TOP + 100.0), Vector2(6000, 200))
	_player = TestArena.player(_root, Vector2(0, FLOOR_TOP))
	await wait_frames(3)
	assert_true(_player.can_dash(), "the ground dash is start-kit (DESIGN.md §7)")


func test_the_air_dash_does_not_wait_on_the_ground_dash_cooldown() -> void:
	# dash → jump → air dash is a chain, not a timing puzzle. The implant's
	# reach past a dash-jump depends on this.
	GameState.grant_ability(GameState.ABILITY_SIDEWINDER)
	TestArena.solid(_root, Vector2(0, FLOOR_TOP + 100.0), Vector2(6000, 200))
	_player = TestArena.player(_root, Vector2(0, FLOOR_TOP))
	await wait_frames(3)
	Input.action_press("dash")
	Input.action_press("jump")
	await _settle(2)
	Input.action_release("dash")
	await _settle(12)  # dash ends, buffered jump fires
	Input.action_release("jump")
	await _settle(4)
	assert_false(_player.is_on_floor(), "precondition: in the jump")
	assert_true(_player.can_dash(), "the air dash was held hostage by the ground cooldown")


# --- The envelope against real physics --------------------------------------

## 8 tiles: the district's air-dash gate width.
const GATE_GAP := 480.0


func test_the_locked_reach_numbers() -> void:
	# DESIGN.md §3.4 quotes ~290 for a flat jump and 288 for a dash. If the
	# config moves, this moves with it; if the *formula* breaks, this catches it.
	assert_almost_eq(_envelope.flat_jump_distance(), 290.0, 6.0)
	assert_almost_eq(_envelope.dash_distance(), 288.0, 0.01)
	assert_almost_eq(_envelope.jump_air_dash_distance(), 578.0, 6.0)
	assert_almost_eq(_envelope.max_gap(false), 290.0, 6.0)


func test_a_running_jump_lands_where_the_envelope_says() -> void:
	TestArena.solid(_root, Vector2(0, FLOOR_TOP + 100.0), Vector2(6000, 200))
	_player = TestArena.player(_root, Vector2(0, FLOOR_TOP))
	await wait_frames(3)
	Input.action_press("move_right")
	await _settle(20)  # up to speed
	var start_x: float = _player.position.x
	Input.action_press("jump")
	await _settle(2)
	var landed: float = await _run_until_landed()
	var travelled: float = landed - start_x
	# The controller integrates per step, so a real flight lands a few percent
	# past the analytic one. The gate margin (15%) is what absorbs that; this
	# only checks the analysis is in the right neighbourhood.
	assert_almost_eq(travelled, _envelope.flat_jump_distance(), _envelope.flat_jump_distance() * 0.08,
		"the analytic jump is %.0f, the real one %.0f" % [_envelope.flat_jump_distance(), travelled])


func test_a_jump_into_an_air_dash_lands_where_the_envelope_says() -> void:
	GameState.grant_ability(GameState.ABILITY_SIDEWINDER)
	TestArena.solid(_root, Vector2(0, FLOOR_TOP + 100.0), Vector2(6000, 200))
	_player = TestArena.player(_root, Vector2(0, FLOOR_TOP))
	await wait_frames(3)
	Input.action_press("move_right")
	await _settle(20)
	var start_x: float = _player.position.x
	var travelled: float = await _jump_air_dash() - start_x
	assert_almost_eq(travelled, _envelope.jump_air_dash_distance(), _envelope.jump_air_dash_distance() * 0.08,
		"the analytic reach is %.0f, the real one %.0f" % [_envelope.jump_air_dash_distance(), travelled])


## Run-jump, air dash near the apex. Assumes `move_right` is already held.
## Returns the landing x.
func _jump_air_dash() -> float:
	Input.action_press("jump")
	await _settle(int(_config.jump_time_to_apex * 60.0) - 2)
	Input.action_press("dash")
	await _settle(2)
	Input.action_release("dash")
	return await _run_until_landed()


## The starting kit's best attempt at a gap: a dash that runs off the edge,
## mashing jump through it. Assumes the player stands a little before the
## edge at x = 0, so the dash leaves the ground with time left on it.
func _dash_off_the_edge() -> float:
	Input.action_press("move_right")
	Input.action_press("dash")
	await _settle(2)
	Input.action_release("dash")
	for _i: int in 14:
		Input.action_press("jump")
		await get_tree().physics_frame
		Input.action_release("jump")
		await get_tree().physics_frame
	return await _run_until_landed()


## A level gap `gap` px wide starting at x = 0, with a pit floor far below so
## "fell short" is measurable as "landed low".
func _gate_arena(gap: float, start_x: float) -> void:
	TestArena.solid(_root, Vector2(-1000.0, FLOOR_TOP + 100.0), Vector2(2000, 200))
	TestArena.solid(_root, Vector2(gap + 1000.0, FLOOR_TOP + 100.0), Vector2(2000, 200))
	TestArena.solid(_root, Vector2(gap * 0.5, FLOOR_TOP + 900.0), Vector2(gap, 100))
	_player = TestArena.player(_root, Vector2(start_x, FLOOR_TOP))
	await wait_frames(3)


func test_the_gate_width_sits_inside_the_locked_margins() -> void:
	# There must be a band of gap widths that the starting kit cannot cross
	# and the implant can, each by 15%. If tuning closes the band, the
	# district has no honest air-dash gate and this says so.
	var lower: float = _envelope.max_gap(false) * MovementEnvelope.GATE_MARGIN
	var upper: float = _envelope.max_gap(true) / MovementEnvelope.GATE_MARGIN
	assert_lt(lower, upper, "no gap width is both unreachable without and reachable with the Sidewinder")
	assert_true(_envelope.is_valid_air_dash_gate(GATE_GAP), "the district's 8-tile gap is not a valid gate")


func test_a_running_jump_cannot_cross_the_gate() -> void:
	await _gate_arena(GATE_GAP, -600.0)
	Input.action_press("move_right")
	await wait_until(func() -> bool: return _player.position.x >= -10.0, 3.0)
	Input.action_press("jump")
	await _settle(2)
	await _run_until_landed()
	assert_gt(_player.position.y, FLOOR_TOP + 100.0, "a running jump crossed the Sidewinder gate (x=%.0f)" % _player.position.x)


func test_a_dash_off_the_edge_cannot_cross_the_gate_either() -> void:
	# The exploit this guards: dash so the dash leaves the ground, and jump
	# inside the coyote window at its end. `end_dash` forfeits that jump.
	await _gate_arena(GATE_GAP, -150.0)
	await _dash_off_the_edge()
	assert_gt(_player.position.y, FLOOR_TOP + 100.0, "a dash off the edge crossed the Sidewinder gate (x=%.0f)" % _player.position.x)


func test_the_gate_is_crossed_with_the_sidewinder() -> void:
	GameState.grant_ability(GameState.ABILITY_SIDEWINDER)
	await _gate_arena(GATE_GAP, -600.0)
	Input.action_press("move_right")
	await wait_until(func() -> bool: return _player.position.x >= -10.0, 3.0)
	await _jump_air_dash()
	assert_almost_eq(_player.position.y, FLOOR_TOP, 4.0, "the air dash fell into the pit (x=%.0f)" % _player.position.x)
	assert_gte(_player.position.x, GATE_GAP, "landed short at x=%.0f" % _player.position.x)


func test_a_tease_ledge_is_out_of_reach_of_the_whole_kit() -> void:
	# The tease must stay unreachable even with everything — a high single
	# wall, no facing wall to bounce off. Sidewinder holds altitude and the
	# Hook needs a second wall, so a jump's height is the ceiling.
	GameState.grant_ability(GameState.ABILITY_MAG_HOOK)
	GameState.grant_ability(GameState.ABILITY_SIDEWINDER)
	TestArena.solid(_root, Vector2(0, FLOOR_TOP + 100.0), Vector2(6000, 200))
	# A ledge 240px up (4 tiles) on a single wall face to the right.
	TestArena.solid(_root, Vector2(500.0, FLOOR_TOP - 120.0), Vector2(400, 240))
	_player = TestArena.player(_root, Vector2(200.0, FLOOR_TOP))
	await wait_frames(3)
	assert_true(_envelope.is_valid_tease_height(240.0))

	var highest: float = _player.position.y
	Input.action_press("move_right")
	Input.action_press("jump")
	for _i: int in 90:
		await get_tree().physics_frame
		highest = minf(highest, _player.position.y)
		if _i == 20:
			Input.action_press("dash")
		if _i == 22:
			Input.action_release("dash")
	assert_gt(highest, FLOOR_TOP - 240.0, "the tease ledge was reached with the full kit")
