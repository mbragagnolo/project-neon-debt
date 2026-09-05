extends GutTest
## The district at runtime (src/world/world.gd).
##
## Travel through a door, arrival that does not bounce, death back to the
## last terminal, the terminal itself, and a pickup taken in a real room.
## Driven through the real scene with the real player, because the failure
## modes here — a door that fires twice, a respawn into the wrong room — are
## not visible from a unit test of any single node.

const WORLD := preload("res://rooms/world.tscn")

var _world: World
var _player: Player


func before_each() -> void:
	TestArena.release_all_input()
	Hitstop.cancel()
	GameState.reset()
	PlayerStats.reset()
	Inventory.reset()
	Quests.reset()
	SaveLoad.delete_slot(0)
	_world = WORLD.instantiate()
	add_child_autofree(_world)
	_player = _world.player
	await _settled()


func after_each() -> void:
	TestArena.release_all_input()
	get_tree().paused = false
	Hitstop.cancel()
	Engine.time_scale = 1.0
	SaveLoad.delete_slot(0)
	GameState.reset()
	PlayerStats.reset()
	Inventory.reset()
	Quests.reset()


## Waits until the world is not mid-travel and the player is free.
func _settled(seconds: float = 4.0) -> void:
	await wait_until(func() -> bool: return _world.current_room != null and not _world._travelling and not _player.frozen, seconds)


func _settle(frames: int) -> void:
	for _i: int in frames:
		await get_tree().physics_frame


func test_a_fresh_run_wakes_up_in_the_flat() -> void:
	assert_eq(_world.current_room_id, World.START_ROOM)
	assert_false(_player.frozen, "the player is still frozen after the fade")
	var spawn: Node2D = _world.current_room.get_node("PlayerSpawn")
	assert_almost_eq(_player.global_position.x, spawn.global_position.x, 2.0)
	assert_true(GameState.has_visited(World.START_ROOM))


func test_the_room_is_the_only_child_of_the_host() -> void:
	assert_eq(_world.get_node("RoomHost").get_child_count(), 1)
	assert_null(_world.current_room.get_node_or_null("Player"), "district rooms must not carry a player")


func test_walking_into_a_door_swaps_rooms_and_arrives_inside() -> void:
	Input.action_press("move_right")
	await wait_until(func() -> bool: return _world.current_room_id == &"hall_14", 8.0)
	Input.action_release("move_right")
	assert_eq(_world.current_room_id, &"hall_14", "never reached the hall")
	await _settled()
	assert_eq(_world.get_node("RoomHost").get_child_count(), 1, "the old room was not freed")
	# Arrived through the hall's left door, standing just inside it.
	var door: Door = _world.current_room.get_node("Doors/1")
	assert_almost_eq(_player.global_position.x, door.spawn_point.x, 2.0)
	assert_eq(_player.facing, 1, "should face into the room")
	assert_true(GameState.has_visited(&"hall_14"))


func test_arriving_through_a_door_does_not_bounce_straight_back() -> void:
	await _world.travel(&"hall_14", &"1")
	await _settled()
	await _settle(40)
	assert_eq(_world.current_room_id, &"hall_14", "the arrival door fired again")


func test_leaving_back_out_through_the_arrival_door_works() -> void:
	await _world.travel(&"hall_14", &"1")
	await _settled()
	Input.action_press("move_left")
	await wait_until(func() -> bool: return _world.current_room_id == &"unit_14c", 6.0)
	Input.action_release("move_left")
	assert_eq(_world.current_room_id, &"unit_14c", "could not walk back out")


func test_the_camera_clamps_to_the_room() -> void:
	await _world.travel(&"hall_13", &"1")
	await _settled()
	assert_eq(_player.camera.limit_right, 3840, "a two-cell room is 3840 wide")
	assert_eq(_player.camera.limit_bottom, 1080)


func test_death_without_a_terminal_returns_to_the_flat_with_everything() -> void:
	await _world.travel(&"hall_14", &"1")
	await _settled()
	Inventory.grant(&"work_boots")
	_player.health.apply_damage(9999, Attack.make(null, Vector2.ZERO, 9999.0))
	await wait_until(func() -> bool: return _world.current_room_id == World.START_ROOM and not _world._travelling, 6.0)
	assert_eq(_world.current_room_id, World.START_ROOM)
	assert_eq(_player.health.hp, _player.health.max_hp, "not healed on respawn")
	assert_true(Inventory.owns(&"work_boots"), "death took the boots (the slice default keeps everything)")


func test_the_terminal_saves_heals_and_becomes_the_respawn_point() -> void:
	await _world.travel(&"hall_13", &"1")
	await _settled()
	var terminal: SavePoint = _first_in_room(&"save_points") as SavePoint
	assert_not_null(terminal, "hall_13 has no terminal")
	_player.health.apply_damage(10, Attack.make(null, Vector2.ZERO, 10.0))
	_player.spend_ram(5)
	_player.spend_ammo(3)
	terminal.activate()
	assert_true(SaveLoad.has_save(0), "nothing was written")
	assert_eq(GameState.current_save_point, &"hall_13")
	assert_eq(_player.health.hp, _player.health.max_hp)
	assert_eq(_player.ram, _player.max_ram, "RAM not restored")
	assert_eq(_player.ammo, _player.max_ammo, "ammo not restored")

	await _world.travel(&"hall_14", &"1")
	await _settled()
	_player.health.apply_damage(9999, Attack.make(null, Vector2.ZERO, 9999.0))
	await wait_until(func() -> bool: return _world.current_room_id == &"hall_13" and not _world._travelling, 6.0)
	assert_eq(_world.current_room_id, &"hall_13", "did not respawn at the terminal's room")
	# The room was re-instanced; find its terminal again.
	var again: SavePoint = _first_in_room(&"save_points") as SavePoint
	assert_not_null(again)
	if again != null:
		assert_almost_eq(_player.global_position.x, again.global_position.x, 4.0, "not standing at the terminal")


func test_a_pickup_in_a_real_room_grants_and_stays_taken() -> void:
	await _world.travel(&"maintenance_closet", &"1")
	await _settled()
	var pickup: Pickup = _first_in_room_of_type(Pickup) as Pickup
	assert_not_null(pickup, "the closet has no pickup")
	assert_eq(pickup.kind, Pickup.Kind.ABILITY)
	pickup.take()
	assert_true(GameState.has_ability(GameState.ABILITY_MAG_HOOK), "the Hook was not granted")
	assert_true(_player.can_wall_jump())
	await _world.travel(&"hall_13", &"2")
	await _settled()
	await _world.travel(&"maintenance_closet", &"1")
	await _settled()
	assert_null(_first_in_room_of_type(Pickup), "the Hook grew back")


func test_the_gut_bulkhead_stays_shut_without_the_program() -> void:
	await _world.travel(&"gut_lift", &"1")
	await _settled()
	var door: BreachDoor = _first_in_room_of_type(BreachDoor) as BreachDoor
	assert_not_null(door, "the lift has no bulkhead")
	door.interact()
	assert_false(door.is_open())
	HackKit.grant(&"breach")
	door.interact()
	assert_true(door.is_open())


func test_rooms_announce_themselves_once_the_player_is_in_them() -> void:
	watch_signals(Events)
	await _world.travel(&"hall_14", &"1")
	await _settled()
	assert_signal_emitted_with_parameters(Events, "room_entered", [&"hall_14"])


func _first_in_room(group: StringName) -> Node:
	for node: Node in get_tree().get_nodes_in_group(group):
		if _world.current_room.is_ancestor_of(node):
			return node
	return null


func _first_in_room_of_type(type: Variant) -> Node:
	return _find_type(_world.current_room, type)


func _find_type(node: Node, type: Variant) -> Node:
	for child: Node in node.get_children():
		if is_instance_of(child, type):
			return child
		var found: Node = _find_type(child, type)
		if found != null:
			return found
	return null
