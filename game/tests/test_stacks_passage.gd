extends GutTest
## The critical path, walked by the real controller (docs/level-design/stacks.md).
##
## test_stacks.gd holds the district to its promises as a graph of doors and
## declared gates; it cannot see a block inside a room. These put the actual
## player in the actual room scene at a point on the critical path and drive
## it across. Three rooms shipped in M5 with passes that did not exist for an
## 88px body: a two-tile block under a three-tile ceiling (mezz_east), a
## floor piece with one tile of air under it (west_stair), a water tower
## whose stem was solid from deck to tank (roof_span). Every room-level test
## passed. Found by the level-designer solver (prototype/level_designer).

const TILE := RoomSpec.TILE

var _root: Node2D


func before_each() -> void:
	TestArena.release_all_input()
	GameState.reset()
	_root = Node2D.new()
	add_child_autofree(_root)


func after_each() -> void:
	TestArena.release_all_input()
	GameState.reset()


## Drops the real player at `feet` (in tiles) in the room's scene, holds
## `direction` for `frames` physics frames, tapping jump if asked, and
## returns the farthest point reached: x in the direction held, y downward.
func _drive(room_id: StringName, feet: Vector2, direction: String, jumping: bool, frames: int = 240) -> Vector2:
	var room: Node = (load(World.room_path(room_id)) as PackedScene).instantiate()
	_root.add_child(room)
	var player: Player = TestArena.player(room, feet * TILE)
	await wait_physics_frames(3)
	var far: Vector2 = player.position
	Input.action_press(direction)
	for i: int in frames:
		if jumping and i % 40 == 5:
			Input.action_press("jump")
		if jumping and i % 40 == 25:
			Input.action_release("jump")
		await get_tree().physics_frame
		if direction == "move_right":
			far.x = maxf(far.x, player.position.x)
		else:
			far.x = minf(far.x, player.position.x)
		far.y = maxf(far.y, player.position.y)
	TestArena.release_all_input()
	return far / TILE


func test_the_hub_east_door_leads_past_the_block_in_mezz_east() -> void:
	# From the Mezz's door, on the floor, holding right and jumping: the
	# block at x10..11 must be crossed, or nothing east of the hub exists.
	var far: Vector2 = await _drive(&"mezz_east", Vector2(9.5, 17.0), "move_right", true)
	assert_gte(far.x, 13.0, "the player stopped at x %.1f tiles; the block at x10..11 is not passable" % far.x)


func test_the_west_stair_descends_past_the_alcove_floor() -> void:
	# On the platform under the alcove's floor piece (row 37), walking left
	# off its end must drop to the next platform (row 39), not bump the head.
	var far: Vector2 = await _drive(&"west_stair", Vector2(20.5, 37.0), "move_left", false)
	# Feet rest a hair above the platform top, hence the margin.
	assert_gte(far.y, 38.9, "the player never got below row %.2f; the floor piece on row 35 blocks the way down" % far.y)


func test_the_roof_crosses_under_the_water_tower() -> void:
	# East of the tower, walking west: the stem at x42..45 must let the
	# player through, since the only other way over is the tease.
	var far: Vector2 = await _drive(&"roof_span", Vector2(50.5, 17.0), "move_left", false)
	assert_lte(far.x, 38.0, "the player stopped at x %.1f tiles; the water tower's stem splits the roof" % far.x)


## The climb policy the controller wants: jump from the floor to get between
## the walls, then from a wall slide kick off and hold toward the other wall.
## Returns the highest feet row reached (tiles; smaller is higher).
func _climb(room_id: StringName, feet: Vector2, frames: int = 420) -> float:
	var room: Node = (load(World.room_path(room_id)) as PackedScene).instantiate()
	_root.add_child(room)
	var player: Player = TestArena.player(room, feet * TILE)
	await wait_physics_frames(3)
	var top: float = player.position.y
	var dir: String = "move_right"
	var since_jump: int = 99
	var flip_at: int = -1
	Input.action_press(dir)
	for _i: int in frames:
		since_jump += 1
		if player.is_on_floor() and since_jump > 30:
			Input.action_press("jump")
			since_jump = 0
		elif player.state_name() == &"WallSlide" and since_jump > 10:
			Input.action_press("jump")
			since_jump = 0
			flip_at = 8
		if since_jump == 6:
			Input.action_release("jump")
		if flip_at >= 0 and since_jump == flip_at:
			Input.action_release(dir)
			dir = "move_left" if dir == "move_right" else "move_right"
			Input.action_press(dir)
			flip_at = -1
		await get_tree().physics_frame
		top = minf(top, player.position.y)
	TestArena.release_all_input()
	return top / TILE


func test_the_tunnel_climbs_back_to_the_stair_with_the_hook() -> void:
	# The Gut before Breach: a player who dropped in must be able to leave
	# the way they came. The tunnel's shaft to gut_stair used to start seven
	# rows above the floor with nothing to reach it from; now its walls come
	# down to two tiles above the floor and the Hook climbs it.
	GameState.grant_ability(GameState.ABILITY_MAG_HOOK)
	var top: float = await _climb(&"service_tunnel", Vector2(57.5, 17.0))
	assert_lte(top, 0.5, "the highest the player got was row %.2f; the shaft to gut_stair cannot be climbed from the tunnel floor" % top)
