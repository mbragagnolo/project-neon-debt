extends GutTest
## Ownership, the six slots, and the four modifier reads
## (docs/rpg/items.md, docs/ui/screens.md rule 6).
##
## Runs against the real `Inventory` autoload and resets at both ends, so a
## test that dresses the player in the full set cannot re-tune the combat tests
## that follow it.

func before_each() -> void:
	Inventory.reset()


func after_each() -> void:
	Inventory.reset()


# --- The starting kit -------------------------------------------------------

func test_a_fresh_run_starts_with_the_wrench_and_the_zipgun_in_hand() -> void:
	# DESIGN.md §2. Owned *and* equipped: the player never opens a menu to arm
	# themselves for the first fight.
	assert_true(Inventory.owns(&"pipe_wrench"))
	assert_true(Inventory.owns(&"zipgun"))
	assert_eq(Inventory.equipped_melee().id, &"pipe_wrench")
	assert_eq(Inventory.equipped_ranged().id, &"zipgun")
	assert_eq(Inventory.owned_items().size(), 2, "the slice hands out nothing else at the start")


func test_every_clothing_slot_starts_empty() -> void:
	# The first DEF in the game is the work boots, mid-path (items.md
	# placement). Starting dressed would delete that beat.
	for slot: Item.Slot in [Item.Slot.HEAD, Item.Slot.BODY, Item.Slot.LEGS, Item.Slot.HANDS]:
		assert_null(Inventory.equipped(slot), Item.slot_name(slot))
	assert_eq(Inventory.total_defense(), 0)


# --- Picking things up ------------------------------------------------------

func test_found_clothing_goes_straight_on() -> void:
	# Clothing is progression, not choice — one piece per slot in the whole
	# slice, so making the player equip the only jacket in the game is a menu
	# chore with no decision in it.
	Inventory.grant(&"padded_jacket")
	assert_eq(Inventory.equipped(Item.Slot.BODY).id, &"padded_jacket")


func test_a_found_weapon_never_displaces_what_is_in_hand() -> void:
	# The trio are sidegrades. Which one is right is exactly the decision the
	# equip screen exists for, so a chest must not make it for you.
	Inventory.grant(&"breaker_maul")
	assert_true(Inventory.owns(&"breaker_maul"))
	assert_eq(Inventory.equipped_melee().id, &"pipe_wrench")


func test_granting_the_same_item_twice_changes_nothing() -> void:
	# A chest that somehow fires twice has to be harmless.
	assert_false(Inventory.grant(&"pipe_wrench"), "already owned")
	assert_true(Inventory.grant(&"nailgun"))
	assert_false(Inventory.grant(&"nailgun"))
	assert_eq(Inventory.owned_items().size(), 3)


func test_a_pickup_announces_itself() -> void:
	var picked: Array = []
	Events.item_picked_up.connect(func(item_id: StringName) -> void: picked.append(item_id))
	Inventory.grant(&"work_boots")
	assert_eq(picked, [&"work_boots"])


# --- Equipping --------------------------------------------------------------

func test_equipping_something_you_do_not_own_fails() -> void:
	assert_false(Inventory.equip(&"rivet_gun"))
	assert_eq(Inventory.equipped_ranged().id, &"zipgun")


func test_swapping_a_weapon_reports_both_halves() -> void:
	# The HUD and the equip screen both redraw off these, and an unequip
	# without a matching equip is how a slot ends up drawn empty while full.
	Inventory.grant(&"breaker_maul")
	var events: Array = []
	Events.item_unequipped.connect(
		func(_slot: StringName, item_id: StringName) -> void: events.append([&"off", item_id])
	)
	Events.item_equipped.connect(
		func(_slot: StringName, item_id: StringName) -> void: events.append([&"on", item_id])
	)
	Inventory.equip(&"breaker_maul")
	assert_eq(events, [[&"off", &"pipe_wrench"], [&"on", &"breaker_maul"]])


func test_a_weapon_slot_can_never_be_emptied() -> void:
	# An empty weapon slot is a state with no legitimate way in and one obvious
	# way to soft-brick a fight (docs/ui/screens.md, rule 6).
	assert_false(Inventory.unequip(Item.Slot.MELEE))
	assert_false(Inventory.unequip(Item.Slot.RANGED))
	assert_not_null(Inventory.equipped_melee())


func test_clothing_comes_off_freely() -> void:
	# Nothing to protect, and a DEF-0 run is a legitimate thing to try.
	Inventory.grant(&"padded_jacket")
	assert_true(Inventory.unequip(Item.Slot.BODY))
	assert_null(Inventory.equipped(Item.Slot.BODY))
	assert_true(Inventory.owns(&"padded_jacket"), "taking it off is not losing it")


# --- The four modifier reads ------------------------------------------------

func test_def_comes_from_worn_clothing_only() -> void:
	Inventory.grant(&"padded_jacket")
	Inventory.grant(&"work_boots")
	assert_eq(Inventory.total_defense(), 3)
	Inventory.unequip(Item.Slot.BODY)
	assert_eq(Inventory.total_defense(), 1, "owning a jacket is not wearing one")


func test_the_full_set_totals_the_locked_five() -> void:
	for item_id: StringName in [
		&"padded_jacket", &"work_boots", &"linesman_gloves", &"scavved_hardhat"
	]:
		Inventory.grant(item_id)
	assert_eq(Inventory.total_defense(), 5)
	assert_eq(Inventory.max_hp_bonus(), 10)
	assert_almost_eq(Inventory.dash_cooldown_mult(), 0.85, 0.001)
	assert_almost_eq(Inventory.ram_regen_mult(), 1.25, 0.001)
	assert_eq(Inventory.melee_energy_bonus(), 2)


func test_each_modifier_reads_its_own_slot_and_no_other() -> void:
	# Four hooks, four slots. A modifier that answers from the wrong slot is
	# invisible until someone wonders why the boots do nothing.
	Inventory.grant(&"scavved_hardhat")
	assert_eq(Inventory.melee_energy_bonus(), 2)
	assert_eq(Inventory.max_hp_bonus(), 0, "the hardhat is not a jacket")
	assert_almost_eq(Inventory.dash_cooldown_mult(), 1.0, 0.001)
	assert_almost_eq(Inventory.ram_regen_mult(), 1.0, 0.001)


# --- Serialization ----------------------------------------------------------

func test_snapshot_restore_round_trip() -> void:
	Inventory.grant(&"breaker_maul")
	Inventory.grant(&"work_boots")
	Inventory.equip(&"breaker_maul")
	var snapshot: Dictionary = Inventory.snapshot()

	Inventory.reset()
	assert_eq(Inventory.equipped_melee().id, &"pipe_wrench", "reset put the starter back")

	Inventory.restore(snapshot)
	assert_true(Inventory.owns(&"breaker_maul"))
	assert_eq(Inventory.equipped_melee().id, &"breaker_maul")
	assert_eq(Inventory.equipped(Item.Slot.LEGS).id, &"work_boots")
	assert_eq(Inventory.snapshot(), snapshot)


func test_a_save_naming_an_item_the_catalog_lost_still_loads() -> void:
	# Items are stored as ids and resolved through the catalog, so a cut item
	# is a warning and a missing entry rather than a save file that refuses to
	# open.
	Inventory.restore({"owned": ["pipe_wrench", "chainsaw_of_infinity"], "equipped": {}})
	assert_true(Inventory.owns(&"pipe_wrench"))
	assert_false(Inventory.owns(&"chainsaw_of_infinity"))


func test_the_loadout_rides_along_in_the_game_state_snapshot() -> void:
	Inventory.grant(&"nailgun")
	var save: Dictionary = GameState.snapshot()
	assert_true(save.has("inventory"), "the loadout is missing from the save")
	var owned: PackedStringArray = (save["inventory"] as Dictionary)["owned"]
	assert_true(owned.has("nailgun"))
