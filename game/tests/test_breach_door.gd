extends GutTest
## The Breach gate (docs/combat/hacks.md rule 2; DESIGN.md §3.4 grammar).
##
## The rule with teeth: the door checks that you *own* the program, never the
## meter. A player arriving at a gate on an empty pool must never be stuck.

const DOOR := preload("res://src/world/breach_door.tscn")
const FLOOR_TOP := 600.0

var _root: Node2D


func before_each() -> void:
	TestArena.release_all_input()
	GameState.reset()
	PlayerStats.reset()
	Inventory.reset()
	_root = Node2D.new()
	add_child_autofree(_root)


func after_each() -> void:
	TestArena.release_all_input()
	GameState.reset()


func _select(kit: HackKit, hack_id: StringName) -> void:
	for _i: int in 4:
		if kit.selected() != null and kit.selected().id == hack_id:
			return
		kit.select_next()


func _door(door_id: StringName = &"test_door", at: Vector2 = Vector2(400.0, FLOOR_TOP)) -> BreachDoor:
	var door: BreachDoor = DOOR.instantiate()
	door.door_id = door_id
	door.position = at
	_root.add_child(door)
	return door


func test_it_is_solid_and_sealed_until_opened() -> void:
	var door := _door()
	await wait_frames(2)
	assert_false(door.is_open())
	assert_eq(door.collision_layer, 1, "not on the world layer — nothing stops at it")
	assert_false((door.get_node("CollisionShape2D") as CollisionShape2D).disabled)


func test_the_terminal_refuses_without_the_program() -> void:
	var door := _door()
	await wait_frames(2)
	watch_signals(Events)
	door.interact()
	assert_false(door.is_open())
	assert_false(GameState.has_flag(&"door.test_door"))
	assert_signal_not_emitted(Events, "door_opened")


func test_the_terminal_opens_it_for_free_once_the_program_is_owned() -> void:
	# No player, no RAM, no cast — ownership is the only check.
	HackKit.grant(&"breach")
	var door := _door()
	await wait_frames(2)
	watch_signals(Events)
	door.interact()
	assert_true(door.is_open())
	assert_true(GameState.has_flag(&"door.test_door"), "opening did not persist")
	assert_signal_emitted_with_parameters(Events, "door_opened", [&"test_door"])
	await wait_frames(2)
	assert_true((door.get_node("CollisionShape2D") as CollisionShape2D).disabled, "open but still solid")


func test_an_opened_door_stays_open_when_the_room_is_re_entered() -> void:
	GameState.set_flag(&"door.test_door")
	var door := _door()
	await wait_frames(2)
	assert_true(door.is_open())
	assert_true((door.get_node("CollisionShape2D") as CollisionShape2D).disabled)


func test_opening_twice_reports_once() -> void:
	HackKit.grant(&"breach")
	var door := _door()
	await wait_frames(2)
	assert_true(door.breach())
	assert_false(door.breach())


func test_a_breach_pulse_in_reach_opens_it_and_costs_the_cast() -> void:
	TestArena.solid(_root, Vector2(0, FLOOR_TOP + 100.0), Vector2(6000, 200))
	var player := TestArena.player(_root, Vector2(0, FLOOR_TOP))
	var door := _door(&"test_door", Vector2(250.0, FLOOR_TOP))
	HackKit.grant(&"breach")
	GameState.grant_ability(GameState.ABILITY_CYBERDECK)
	await wait_frames(3)

	var kit: HackKit = player.hacks
	_select(kit, &"breach")
	assert_eq(kit.selected().id, &"breach", "precondition")
	assert_true(kit.try_cast())
	assert_true(door.is_open(), "the pulse did not reach the door")
	assert_eq(player.ram, 12 - 2, "a combat cast costs normally")


func test_a_pulse_out_of_reach_leaves_it_sealed() -> void:
	TestArena.solid(_root, Vector2(0, FLOOR_TOP + 100.0), Vector2(6000, 200))
	var player := TestArena.player(_root, Vector2(0, FLOOR_TOP))
	var breach: Hack = HackKit.hack_by_id(&"breach")
	var door := _door(&"test_door", Vector2(breach.radius + 200.0, FLOOR_TOP))
	HackKit.grant(&"breach")
	GameState.grant_ability(GameState.ABILITY_CYBERDECK)
	await wait_frames(3)

	var kit: HackKit = player.hacks
	_select(kit, &"breach")
	assert_eq(kit.selected().id, &"breach", "precondition")
	kit.try_cast()
	assert_false(door.is_open())


func test_the_prompt_names_the_key_that_actually_breaches() -> void:
	HackKit.grant(&"breach")
	var door := _door()
	await wait_frames(2)
	door._refresh_prompt()
	var prompt: Label = door.get_node("Prompt")
	assert_string_contains(prompt.text, InputPrompt.label(&"interact"))
