extends GutTest
## Smoke test for the M0 exit criterion: the project's main scene instances,
## announces itself on the bus and records itself in GameState.

const ROOM_PATH := "res://rooms/test_room.tscn"


func test_main_scene_setting_points_at_the_test_room() -> void:
	assert_eq(ProjectSettings.get_setting("application/run/main_scene"), ROOM_PATH)


func test_test_room_instances() -> void:
	var room: Node = autofree(load(ROOM_PATH).instantiate())
	assert_not_null(room)
	assert_is(room, Room)
	assert_eq(room.room_id, &"test_room")


func test_test_room_has_geometry_and_a_spawn_point() -> void:
	var room: Node = autofree(load(ROOM_PATH).instantiate())
	assert_not_null(room.get_node_or_null("PlayerSpawn"), "rooms need a spawn marker")
	assert_not_null(room.get_node_or_null("Camera2D"))
	var geometry: Node = room.get_node_or_null("Geometry")
	assert_not_null(geometry)
	assert_gt(geometry.get_child_count(), 0, "the greybox room has no solids")


func test_room_solids_are_on_the_world_collision_layer() -> void:
	var room: Node = autofree(load(ROOM_PATH).instantiate())
	var world_layer: int = 1 << 0
	for solid: Node in room.get_node("Geometry").get_children():
		assert_is(solid, StaticBody2D)
		assert_eq(
			(solid as StaticBody2D).collision_layer, world_layer,
			"'%s' is not on the 'world' layer" % solid.name
		)


func test_entering_a_room_announces_it_and_records_the_visit() -> void:
	watch_signals(Events)
	var room: Node = load(ROOM_PATH).instantiate()
	add_child_autofree(room)
	assert_signal_emitted_with_parameters(Events, "room_entered", [&"test_room"])
	assert_true(GameState.has_visited(&"test_room"))
	GameState.reset()
