extends GutTest
## The M4 hacks lab.
##
## Same job as the other gym tests: the gym is the room Marcos actually plays,
## so what gets checked is the set of quiet breakages that would waste a
## session — a station whose tags fell off, a program nobody can download, a
## door with nothing behind it.

const GYM_PATH := "res://rooms/hack_gym.tscn"

var _gym: Node


func before_each() -> void:
	_gym = autofree(load(GYM_PATH).instantiate())


func test_the_hack_gym_is_the_main_scene() -> void:
	# The main scene tracks the active milestone: pressing play should always
	# land on the thing currently being judged by feel.
	assert_eq(ProjectSettings.get_setting("application/run/main_scene"), GYM_PATH)


func test_it_instances_with_a_player_a_hud_the_equip_screen_and_the_grants() -> void:
	assert_is(_gym, Room)
	assert_eq(_gym.room_id, &"hack_gym")
	assert_is(_gym.get_node_or_null("Player"), Player)
	assert_not_null(_gym.get_node_or_null("DebugHud"), "no HUD - nothing shows RAM")
	assert_not_null(_gym.get_node_or_null("EquipScreen"), "no way to equip the maul")
	# The quickslot belongs to the Cyberdeck; the gym must hand it out or the
	# cycle keys teach nothing.
	assert_is(_gym.get_node_or_null("GymGrants"), GymGrants)


func test_both_found_programs_can_be_downloaded_here() -> void:
	var programs: Array = []
	for pickup: Node in _gym.get_node("Pickups").get_children():
		if int(pickup.kind) == Pickup.Kind.HACK:
			programs.append(pickup.hack_id)
	assert_has(programs, &"overload")
	assert_has(programs, &"breach")
	assert_does_not_have(programs, &"firewall", "firewall is factory-installed")


func test_the_shielded_dummy_faces_the_approach_and_carries_the_shield() -> void:
	var shielded: TrainingDummy = _gym.get_node("Dummies/Shielded")
	assert_has(shielded.tags, Health.TAG_IMMUNE_RANGED_FRONTAL)
	assert_eq(shielded.facing, -1, "the player comes from the left; the shield must face them")
	assert_gte(shielded.stagger_threshold, 12, "Overload's interrupt is not demonstrable")
	assert_gt(shielded.defense, 0, "hacks bypass shields, never DEF - nothing to feel here")


func test_the_breach_stations_are_mechanical_and_the_scavs_are_not() -> void:
	for dummy_name: String in ["Sentry", "Turret"]:
		var dummy: TrainingDummy = _gym.get_node("Dummies/%s" % dummy_name)
		assert_has(dummy.tags, Health.TAG_MECHANICAL, dummy_name)
		assert_true(dummy.hurts_on_contact, "%s is harmless, so the stun buys nothing" % dummy_name)
	var scav: EnemyConfig = load("res://src/enemies/scav/scav.tres")
	assert_does_not_have(scav.tags, Health.TAG_MECHANICAL, "a Scav answering Breach breaks the lesson")


func test_the_maul_waits_behind_the_breach_door() -> void:
	# items.md placement: the experienced ability gate pays out the
	# armour-cracker. The chest must be on the far side of the slab.
	var door: BreachDoor = _gym.get_node("Geometry/MaulDoor")
	var maul: Node = null
	for pickup: Node in _gym.get_node("Pickups").get_children():
		if pickup.item_id == &"breaker_maul":
			maul = pickup
	assert_not_null(maul, "no maul in the gym")
	assert_gt((maul as Node2D).position.x, door.position.x, "the maul is on the free side of the door")
	assert_ne(String(door.door_id), "", "the door has no id - opening it will not persist")


func test_the_fight_has_scavs_and_a_machine() -> void:
	var arena: Node = _gym.get_node_or_null("ScavArena")
	assert_not_null(arena, "no fight - nothing to use three verbs in")
	assert_eq(arena.get_child_count(), 3, "the three-Scav exit test")
	var turret: TrainingDummy = _gym.get_node("Dummies/Turret")
	assert_gt(turret.position.x, 4060.0, "the turret is outside the arena")


func test_the_wall_labels_name_the_keys_that_actually_work() -> void:
	# The lesson of #4: every prompt is built from the bindings.
	var cast_key: String = InputPrompt.key(&"hack_cast").to_upper()
	var found := false
	for child: Node in _gym.get_node("Labels").get_children():
		if child is Label and "CAST" in (child as Label).text and cast_key in (child as Label).text:
			found = true
	assert_true(found, "no label names the cast key")
