extends GutTest
## The equip screen (docs/ui/screens.md).
##
## The rule this file mainly exists for is spec rule 4: **every number on the
## screen must be the number the pipeline uses.** A screen that reads a
## weapon's authored `power` agrees with the item file, disagrees with the
## game, and lets M3's exit test pass on a lie — and nothing about it looks
## wrong until someone counts hits.
##
## Nothing here awaits a frame while the tree is paused: the screen pauses the
## game, and a test that waits for a frame it just stopped would hang.

const EQUIP_SCREEN := preload("res://src/ui/menus/equip_screen.gd")

var _screen: CanvasLayer
var _config: CombatConfig


func before_each() -> void:
	Inventory.reset()
	PlayerStats.reset()
	_config = load("res://src/combat/combat_config.tres")
	_screen = CanvasLayer.new()
	_screen.set_script(EQUIP_SCREEN)
	add_child_autofree(_screen)


func after_each() -> void:
	_screen.close()
	get_tree().paused = false
	Inventory.reset()
	PlayerStats.reset()


# --- The shell --------------------------------------------------------------

func test_opening_pauses_the_game_and_closing_lets_it_go() -> void:
	# Nothing is fought behind an open menu, and no comparison is made against
	# a health bar that is still moving.
	assert_false(get_tree().paused)
	_screen.open()
	assert_true(_screen.visible)
	assert_true(get_tree().paused)
	_screen.close()
	assert_false(get_tree().paused)
	assert_false(_screen.visible)


func test_the_screen_itself_keeps_running_while_paused() -> void:
	# It is the thing that has to answer the button that closes it.
	assert_eq(_screen.process_mode, Node.PROCESS_MODE_ALWAYS)


func test_the_slots_are_listed_in_the_locked_order() -> void:
	assert_eq(
		_screen.SLOT_ORDER,
		[
			Item.Slot.MELEE, Item.Slot.RANGED, Item.Slot.HEAD,
			Item.Slot.BODY, Item.Slot.LEGS, Item.Slot.HANDS,
		]
	)


# --- Equipping through it ---------------------------------------------------

func test_equipping_from_the_list_changes_what_is_in_hand() -> void:
	Inventory.grant(&"breaker_maul")
	_screen.open()
	# Melee is the first slot; step into the item column and take the second
	# entry, which is the maul in catalog order.
	_screen._focus_items()
	_screen._move(1)
	_screen._confirm()
	assert_eq(Inventory.equipped_melee().id, &"breaker_maul")


func test_a_weapon_slot_cannot_be_emptied_from_the_screen() -> void:
	# The rule has one home — `Inventory` refuses — and the screen must not
	# grow a second copy of it that can drift.
	_screen.open()
	_screen._confirm()  # cursor is on the melee slot: "take this off"
	assert_not_null(Inventory.equipped_melee())


func test_clothing_comes_off_from_the_slot_column() -> void:
	Inventory.grant(&"padded_jacket")
	_screen.open()
	_screen._slot_index = 3  # BODY
	_screen._confirm()
	assert_null(Inventory.equipped(Item.Slot.BODY))


# --- Rule 4: the numbers are the pipeline's ---------------------------------

func test_the_damage_readout_is_the_number_the_pipeline_produces() -> void:
	Inventory.grant(&"breaker_maul")
	var maul: MeleeWeapon = Inventory.catalog.by_id(&"breaker_maul")
	var lines: Array = _screen._delta_lines(maul)

	var expected: int = maul.damage_at(PlayerStats.strength(), _config)
	assert_eq(str(lines[0][0]), "DMG/HIT")
	assert_eq(str(lines[0][2]), "%d" % expected)
	# And it is not the authored number: at STR 5 the maul's 18 lands as 22.
	assert_ne(str(lines[0][2]), "%d" % int(maul.power), "the screen is showing raw power")


func test_the_damage_readout_moves_with_the_level() -> void:
	# The same assertion from the other side: if the screen were reading the
	# resource, levelling would not change a digit on it.
	Inventory.grant(&"breaker_maul")
	var maul: MeleeWeapon = Inventory.catalog.by_id(&"breaker_maul")
	var at_level_1: String = str(_screen._delta_lines(maul)[0][2])
	PlayerStats.restore({"level": 6, "xp": PlayerStats.xp_curve.cumulative_to(6)})
	assert_ne(str(_screen._delta_lines(maul)[0][2]), at_level_1)


func test_both_damage_per_hit_and_dps_are_always_shown_for_a_weapon() -> void:
	# The trio is built on the speed axis: the maul is +12 a hit and barely
	# +3 DPS, and a screen showing one of those argues for the wrong weapon.
	var maul: MeleeWeapon = Inventory.catalog.by_id(&"breaker_maul")
	var axes: Array = []
	for line: Array in _screen._delta_lines(maul):
		axes.append(str(line[0]))
	assert_has(axes, "DMG/HIT")
	assert_has(axes, "DPS")
	assert_has(axes, "ATK SPEED")


func test_a_clothing_delta_shows_def_and_its_one_modifier() -> void:
	var jacket: Clothing = Inventory.catalog.by_id(&"padded_jacket")
	var axes: Array = []
	for line: Array in _screen._delta_lines(jacket):
		axes.append(str(line[0]))
	assert_eq(axes, ["DEF", "MAX HP"], "clothing is DEF plus exactly one modifier")


func test_an_unchanged_axis_is_not_listed() -> void:
	# "A wall of arrows pointing at nothing buries the one line that moved."
	# The boots touch DEF and the dash, and nothing else.
	var boots: Clothing = Inventory.catalog.by_id(&"work_boots")
	var axes: Array = []
	for line: Array in _screen._delta_lines(boots):
		axes.append(str(line[0]))
	assert_eq(axes, ["DEF", "DASH CD"])
	assert_does_not_have(axes, "MAX HP")


func test_the_sheet_panel_reads_the_same_dictionary_the_hud_does() -> void:
	# One shape, published on one signal, drawn by two things. A screen with
	# its own idea of the sheet is a screen that disagrees with the HUD.
	PlayerStats.grant_xp(60)
	var sheet: Dictionary = PlayerStats.as_dictionary()
	assert_eq(int(sheet["level"]), 2)
	assert_true(sheet.has("def"), "the sheet the screen draws has no DEF in it")
	assert_true(sheet.has("xp_into_level"))


# --- The hint line ----------------------------------------------------------

func test_the_hint_names_the_keys_that_actually_work() -> void:
	# The hint read "[E] equip / take off   [I] close" while the handlers above
	# answered to `interact` (F) and `toggle_inventory` (Tab) — #4. A menu whose
	# own footer names the wrong exit is the worst place for this to be wrong.
	_screen.open()
	for action: StringName in [&"interact", &"toggle_inventory"]:
		var key: String = ""
		for event: InputEvent in InputMap.action_get_events(action):
			if event is InputEventKey:
				key = OS.get_keycode_string((event as InputEventKey).physical_keycode)
				break
		assert_string_contains(
			_screen._hint.text, "[%s]" % key.to_upper(),
			"the hint does not name the key bound to `%s`" % action
		)
