extends GutTest
## The M3 gear-and-levels lab.
##
## Same job as `test_combat_gym.gd`: the gym is the thing Marcos actually
## plays, so what gets checked here is the set of quiet breakages that would
## waste a tuning session — a chest that lost its item, a wall dummy whose DEF
## reverted, a comparison station that no longer differs in only one number.

const GYM_PATH := "res://rooms/rpg_gym.tscn"

var _gym: Node


func before_each() -> void:
	_gym = autofree(load(GYM_PATH).instantiate())


func test_the_rpg_gym_is_the_main_scene() -> void:
	# The main scene tracks the active milestone: M1 shipped the movement gym
	# here, M2 the hit-feel lab, M3 this. Pressing play should always land on
	# the thing currently being judged by feel.
	assert_eq(ProjectSettings.get_setting("application/run/main_scene"), GYM_PATH)


func test_it_instances_with_a_player_a_hud_and_the_equip_screen() -> void:
	assert_is(_gym, Room)
	assert_eq(_gym.room_id, &"rpg_gym")
	assert_is(_gym.get_node_or_null("Player"), Player)
	# "HUD shows it" is half of M3's exit test, and the screen is the other
	# half. A gym missing either cannot answer the question it exists for.
	assert_not_null(_gym.get_node_or_null("DebugHud"), "no HUD - nothing shows the sheet")
	assert_not_null(_gym.get_node_or_null("EquipScreen"), "no way to equip anything")


# --- The armoury ------------------------------------------------------------

func test_every_found_item_in_the_slice_is_in_a_chest() -> void:
	# The contract that keeps the gym honest as the item list changes: an
	# eleventh item is a design decision, and this fails until the lab can
	# actually put it in someone's hands.
	var catalog: ItemCatalog = load("res://src/rpg/items/catalog.tres")
	var starting: Array = []
	for item: Item in catalog.starting_items:
		starting.append(item.id)

	var in_chests: Array = []
	for pickup: Node in _gym.get_node("Pickups").get_children():
		in_chests.append(pickup.item_id)

	for item: Item in catalog.items:
		if starting.has(item.id):
			assert_false(in_chests.has(item.id), "%s is the starting kit" % item.id)
		else:
			assert_true(in_chests.has(item.id), "%s is in no chest" % item.id)


func test_every_chest_has_its_own_save_flag() -> void:
	# Two chests sharing a pickup_id means looting one closes both, which reads
	# as an item that vanished.
	var seen: Dictionary = {}
	for pickup: Node in _gym.get_node("Pickups").get_children():
		var id: StringName = pickup.pickup_id
		assert_ne(String(id), "", "%s has no pickup_id" % pickup.name)
		assert_false(seen.has(id), "duplicate pickup_id '%s'" % id)
		seen[id] = true


# --- The wall ---------------------------------------------------------------

func test_the_wall_dummies_differ_in_def_and_nothing_else() -> void:
	# The whole station is a controlled comparison. If the three differ in HP
	# or stagger too, the damage numbers stop being attributable to armour and
	# the station teaches nothing.
	var dummies: Node = _gym.get_node("Dummies")
	var expected_def: Dictionary = {"ArmourNone": 0, "ArmourLight": 2, "ArmourHeavy": 5}
	for dummy_name: String in expected_def:
		var dummy: TrainingDummy = dummies.get_node(dummy_name)
		assert_eq(dummy.defense, int(expected_def[dummy_name]), dummy_name)
		assert_eq(dummy.max_hp, 200, "%s has a different HP pool" % dummy_name)
		assert_eq(dummy.stagger_threshold, 9999, "%s can be knocked away" % dummy_name)


func test_the_armoured_dummies_span_the_locked_def_range() -> void:
	# 0 to 5 is the range the whole district is authored inside
	# (docs/rpg/stats-and-curves.md). A wall that stopped at 2 would leave the
	# maul's entire reason for existing untestable.
	var dummies: Node = _gym.get_node("Dummies")
	assert_eq(dummies.get_node("ArmourHeavy").defense, 5)


func test_the_maul_out_damages_the_blade_on_the_heavy_dummy() -> void:
	# The comparison the station is built to make, asserted at the numbers the
	# gym actually ships. If this inverts, the wall is teaching the opposite of
	# what items.md claims and a tuning session would chase the wrong number.
	var config: CombatConfig = load("res://src/combat/combat_config.tres")
	var catalog: ItemCatalog = load("res://src/rpg/items/catalog.tres")
	var heavy: TrainingDummy = _gym.get_node("Dummies/ArmourHeavy")
	var stat: int = PlayerStats.strength()

	var maul: MeleeWeapon = catalog.by_id(&"breaker_maul")
	var blade: MeleeWeapon = catalog.by_id(&"utility_blade")
	var maul_hit: int = Damage.final_damage(maul.damage_at(stat, config), heavy.defense)
	var blade_hit: int = Damage.final_damage(blade.damage_at(stat, config), heavy.defense)
	assert_gt(maul_hit, blade_hit * 4, "the heavy-hit bias is not visible on this dummy")


# --- The range and the pen --------------------------------------------------

func test_the_high_target_is_out_of_jump_reach() -> void:
	# Same guard the M2 gym has: if it can be reached on foot, aiming up stops
	# being exercised and the rivet gun's arc never gets felt against a
	# vertical target.
	var movement: MovementConfig = load("res://src/player/movement_config.tres")
	var high: TrainingDummy = _gym.get_node("Dummies/HighTarget")
	var ground: TrainingDummy = _gym.get_node("Dummies/ArmourNone")
	assert_gt(ground.position.y - high.position.y, movement.jump_height)


func test_the_far_target_is_far_enough_for_the_drop_to_show() -> void:
	# The rivet gun's arc is the one thing in the room that needs distance to
	# be legible at all: fired flat, it has to fall visibly before it arrives.
	var catalog: ItemCatalog = load("res://src/rpg/items/catalog.tres")
	var rivet: RangedWeapon = catalog.by_id(&"rivet_gun")
	var far_target: TrainingDummy = _gym.get_node("Dummies/FarTarget")
	var firing_line: TrainingDummy = _gym.get_node("Dummies/ArmourHeavy")

	var distance: float = far_target.position.x - firing_line.position.x
	var flight: float = distance / rivet.projectile_speed
	var drop: float = 0.5 * rivet.projectile_gravity * flight * flight
	assert_gt(drop, 60.0, "the rivet gun's drop is invisible at this range")


func test_the_pen_holds_enough_scavs_to_level_up_on() -> void:
	# 60 XP is level 2 and a Scav is worth 10, so the pen has to be worth
	# clearing twice rather than twelve times.
	var pen: Node = _gym.get_node_or_null("ScavPen")
	assert_not_null(pen, "no Scavs - nothing pays XP")
	assert_eq(pen.get_child_count(), 3, "three spawn markers, two clears to level 2")


# --- The wall of instructions -----------------------------------------------

## Does `text` name `key` as a word of its own? The gym writes its keys two
## ways — "[F] TAKE" on the armoury wall, "TAKE  F" in the corner legend — so
## matching a bare substring would pass on the F in "FEEL".
func _names_key(text: String, key: String) -> bool:
	var pattern := "(^|[^A-Za-z0-9])%s([^A-Za-z0-9]|$)" % key.to_upper()
	return RegEx.create_from_string(pattern).search(text.to_upper()) != null


func test_the_wall_labels_name_the_keys_that_actually_work() -> void:
	# The gym is the room Marcos actually plays, and for the whole of M3 both of
	# its instruction labels told him to press E and I while the bound keys were
	# F and Tab (#4). Every label that mentions the loadout is checked, because
	# the second one was written in a different format and a grep for "[I]"
	# walked straight past it.
	var keys: Dictionary = {}
	for action: StringName in [&"interact", &"toggle_inventory"]:
		for event: InputEvent in InputMap.action_get_events(action):
			if event is InputEventKey:
				keys[action] = OS.get_keycode_string((event as InputEventKey).physical_keycode)
				break
		assert_true(keys.has(action), "`%s` lost its keyboard binding" % action)

	var checked: int = 0
	for child: Node in _gym.get_node("Labels").get_children():
		if not (child is Label) or not ("LOADOUT" in (child as Label).text):
			continue
		checked += 1
		var text: String = (child as Label).text
		for action: StringName in keys:
			assert_true(
				_names_key(text, String(keys[action])),
				"'%s' does not name the key bound to `%s`" % [text, action]
			)
	assert_eq(checked, 2, "the gym stopped saying how to open the loadout")
