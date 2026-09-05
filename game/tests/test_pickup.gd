extends GutTest
## Items waiting in the world (docs/rpg/items.md, placement).
##
## What is worth protecting is not "the chest gives you the thing" but the two
## states around it: a looted chest stays looted across a room re-entry, and a
## chest that somehow fires twice cannot mint a second maul.

const PICKUP := preload("res://src/world/pickup.tscn")


func before_each() -> void:
	Inventory.reset()
	GameState.reset()


func after_each() -> void:
	Inventory.reset()
	GameState.reset()


func _pickup(item_id: StringName, pickup_id: StringName = &"test_chest") -> Pickup:
	var pickup: Pickup = PICKUP.instantiate()
	pickup.item_id = item_id
	pickup.pickup_id = pickup_id
	add_child_autofree(pickup)
	return pickup


func test_taking_it_grants_the_item() -> void:
	var pickup: Pickup = _pickup(&"breaker_maul")
	assert_false(Inventory.owns(&"breaker_maul"))
	pickup.take()
	assert_true(Inventory.owns(&"breaker_maul"))


func test_taking_it_marks_the_chest_looted_for_good() -> void:
	# The flag is the whole persistence story: the inventory already knows what
	# it owns, so what has to survive a save is that this chest is empty.
	var pickup: Pickup = _pickup(&"work_boots", &"stacks_04_chest")
	pickup.take()
	assert_true(GameState.has_flag(&"pickup.stacks_04_chest"))


func test_a_looted_chest_does_not_come_back() -> void:
	GameState.set_flag(&"pickup.stacks_04_chest")
	var pickup: Pickup = _pickup(&"work_boots", &"stacks_04_chest")
	await get_tree().process_frame
	assert_false(
		is_instance_valid(pickup),
		"a looted chest re-appeared when the room did"
	)


func test_taking_it_twice_mints_nothing() -> void:
	var pickup: Pickup = _pickup(&"nailgun")
	pickup.take()
	pickup.take()
	assert_eq(Inventory.owned_in_slot(Item.Slot.RANGED).size(), 2, "zipgun and one nailgun")


func test_the_prompt_only_shows_with_the_player_standing_in_it() -> void:
	# `interact` is polled while in range, so the prompt and the ability to
	# take are the same state. A prompt that lies about that is a chest players
	# report as broken.
	var pickup: Pickup = _pickup(&"padded_jacket")
	pickup.global_position = Vector2.ZERO
	var prompt: Label = pickup.get_node("Prompt")
	assert_false(prompt.visible, "the prompt showed with nobody there")

	var body := CharacterBody2D.new()
	body.collision_layer = 2  # player
	body.collision_mask = 0
	body.add_to_group(&"player")
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(48, 88)
	shape.shape = rect
	body.add_child(shape)
	add_child_autofree(body)
	body.global_position = Vector2.ZERO

	await get_tree().physics_frame
	await get_tree().physics_frame
	assert_true(prompt.visible, "the player is standing in it and it said nothing")


func test_the_prompt_names_the_key_that_actually_takes_it() -> void:
	# The prompt said "[E] take" for the whole of M3 while `interact` was bound
	# to F (#4). E fires `hack_next`, which nothing reads until M4, so pressing
	# the advertised key did nothing at all and logged nothing either.
	var pickup: Pickup = _pickup(&"work_boots")
	var prompt: Label = pickup.get_node("Prompt")
	var key: String = ""
	for event: InputEvent in InputMap.action_get_events(&"interact"):
		if event is InputEventKey:
			key = OS.get_keycode_string((event as InputEventKey).physical_keycode)
			break
	assert_ne(key, "", "`interact` lost its keyboard binding")
	assert_string_contains(
		prompt.text, "[%s]" % key.to_upper(),
		"the prompt does not name the key bound to `interact`"
	)
