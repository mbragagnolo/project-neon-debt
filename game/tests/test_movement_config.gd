extends GutTest
## The jump is authored as a shape (height + time to apex) and the physics
## constants are derived from it. If that derivation drifts, M1's tuning loop
## stops meaning what it says, so the maths is pinned here.

const CONFIG_PATH := "res://src/player/movement_config.tres"


func _make_config() -> MovementConfig:
	var config := MovementConfig.new()
	config.jump_height = 100.0
	config.jump_time_to_apex = 0.5
	config.fall_gravity_multiplier = 2.0
	return config


func test_shipped_resource_loads_and_is_a_movement_config() -> void:
	var config: Resource = load(CONFIG_PATH)
	assert_not_null(config, "%s failed to load" % CONFIG_PATH)
	assert_is(config, MovementConfig)


func test_jump_reaches_exactly_the_authored_height() -> void:
	# v² = 2gh  =>  a jump launched at jump_velocity() under rise_gravity()
	# must peak at jump_height and nowhere else.
	var config := _make_config()
	var peak: float = (config.jump_velocity() * config.jump_velocity()) / (2.0 * config.rise_gravity())
	assert_almost_eq(peak, config.jump_height, 0.001)


func test_jump_reaches_the_apex_at_the_authored_time() -> void:
	var config := _make_config()
	var time_to_apex: float = -config.jump_velocity() / config.rise_gravity()
	assert_almost_eq(time_to_apex, config.jump_time_to_apex, 0.001)


func test_jump_velocity_is_negative_because_y_points_down() -> void:
	assert_lt(_make_config().jump_velocity(), 0.0)


func test_falling_is_heavier_than_rising() -> void:
	var config := _make_config()
	assert_almost_eq(config.fall_gravity(), config.rise_gravity() * 2.0, 0.001)
	assert_gt(config.fall_gravity(), config.rise_gravity())


func test_wall_jump_reaches_its_authored_height() -> void:
	var config := _make_config()
	config.wall_jump_height = 50.0
	var peak: float = (config.wall_jump_velocity() * config.wall_jump_velocity()) / (2.0 * config.rise_gravity())
	assert_almost_eq(peak, 50.0, 0.001)


func test_dash_covers_its_authored_distance() -> void:
	var config := MovementConfig.new()
	config.dash_distance = 96.0
	config.dash_duration = 0.16
	assert_almost_eq(config.dash_speed() * config.dash_duration, 96.0, 0.001)


func test_degenerate_timings_do_not_divide_by_zero() -> void:
	var config := MovementConfig.new()
	config.jump_time_to_apex = 0.0
	config.dash_duration = 0.0
	assert_eq(config.rise_gravity(), 0.0)
	assert_eq(config.jump_velocity(), 0.0)
	assert_eq(config.dash_speed(), 0.0)
	assert_eq(config.wall_jump_velocity(), 0.0)


func test_shipped_values_match_the_design_document() -> void:
	# DESIGN.md §3.1 names these two explicitly; they are feel-critical.
	var config: MovementConfig = load(CONFIG_PATH)
	assert_almost_eq(config.coyote_time, 0.1, 0.001, "coyote time (~0.1s)")
	assert_almost_eq(config.jump_buffer_time, 0.15, 0.001, "jump buffer (~0.15s)")
