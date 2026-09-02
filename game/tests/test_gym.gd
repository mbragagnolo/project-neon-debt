extends GutTest
## The gym is the M1 deliverable Marcos plays, so the things that would waste a
## playtest — a missing player, a camera that will not follow, geometry that
## does not collide — are checked here.

const GYM_PATH := "res://rooms/gym.tscn"


func test_gym_is_the_main_scene() -> void:
	assert_eq(ProjectSettings.get_setting("application/run/main_scene"), GYM_PATH)


func test_gym_instances_with_a_player_in_it() -> void:
	var gym: Node = autofree(load(GYM_PATH).instantiate())
	assert_is(gym, Room)
	assert_eq(gym.room_id, &"gym")
	var player: Node = gym.get_node_or_null("Player")
	assert_not_null(player, "the gym needs a player to be playable")
	assert_is(player, Player)


func test_player_has_a_movement_config() -> void:
	var gym: Node = autofree(load(GYM_PATH).instantiate())
	var player: Player = gym.get_node("Player")
	assert_not_null(player.config, "the player has no MovementConfig")
	assert_is(player.config, MovementConfig)


func test_gym_declares_camera_limits_because_it_is_bigger_than_a_screen() -> void:
	var gym: Room = autofree(load(GYM_PATH).instantiate())
	assert_ne(gym.camera_limits.size, Vector2i.ZERO,
		"a room larger than one screen must bound the camera")
	assert_gt(gym.camera_limits.size.x, 1920)


func test_gym_solids_are_on_the_world_layer() -> void:
	var gym: Node = autofree(load(GYM_PATH).instantiate())
	for solid: Node in gym.get_node("Geometry").get_children():
		assert_is(solid, StaticBody2D)
		assert_eq((solid as StaticBody2D).collision_layer, 1 << 0,
			"'%s' is not on the 'world' layer" % solid.name)


func test_no_room_writes_nodes_inside_an_instanced_subscene() -> void:
	# A generator that re-owns an instanced sub-scene's internals makes pack()
	# write those nodes out again *as nodes of the outer scene*. Godot merges
	# them back by name on load, so the tree looks right and the game plays
	# fine — but the duplicated subtree leaks at exit. The only place the
	# defect is visible is the scene text, so that is where it gets checked.
	for room_path: String in ["res://rooms/gym.tscn", "res://rooms/test_room.tscn"]:
		var offenders: PackedStringArray = _nodes_declared_inside_an_instance(room_path)
		assert_eq(offenders, PackedStringArray(),
			"%s declares nodes inside an instanced sub-scene: %s" % [room_path, offenders])


## Node paths in `scene_path` that are declared with their own `type=` while
## living under a node that is itself an instanced scene.
func _nodes_declared_inside_an_instance(scene_path: String) -> PackedStringArray:
	var file := FileAccess.open(scene_path, FileAccess.READ)
	assert_not_null(file, "could not read %s" % scene_path)
	if file == null:
		return PackedStringArray()

	var instance_roots := PackedStringArray()
	var offenders := PackedStringArray()
	var header := RegEx.create_from_string(
		'^\\[node name="(?<name>[^"]+)"(?<attrs>[^\\]]*)\\]'
	)

	while not file.eof_reached():
		var found := header.search(file.get_line())
		if found == null:
			continue
		var node_name: String = found.get_string("name")
		var attrs: String = found.get_string("attrs")
		var parent: String = _attr(attrs, "parent")
		var path: String = node_name if parent in ["", "."] else "%s/%s" % [parent, node_name]

		for root: String in instance_roots:
			if parent == root or parent.begins_with(root + "/"):
				if attrs.contains(' type="'):
					offenders.append(path)
		if attrs.contains(" instance=ExtResource"):
			instance_roots.append(path)

	file.close()
	return offenders


func _attr(attrs: String, key: String) -> String:
	var found := RegEx.create_from_string('%s="(?<value>[^"]*)"' % key).search(attrs)
	return "" if found == null else found.get_string("value")
