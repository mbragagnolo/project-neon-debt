extends GutTest
## The ten items, held to the tables in docs/rpg/items.md.
##
## Same contract shape as `test_damage_pipeline.gd`'s reference-table test:
## what is protected here is not "the resource loads" but "the numbers in the
## resource are the numbers the design locked". Items are the one place in the
## game where balance is pure data, which means a typo in a `.tres` is silent
## — nothing crashes, the maul is just quietly worse than the wrench forever.

const CATALOG_PATH := "res://src/rpg/items/catalog.tres"

var _catalog: ItemCatalog


func before_each() -> void:
	_catalog = load(CATALOG_PATH)


func _item(item_id: StringName) -> Item:
	var item: Item = _catalog.by_id(item_id)
	assert_not_null(item, "no item with id '%s'" % item_id)
	return item


## DPS ignoring DEF. Deliberately computed at stat 0: the stat multiplier is
## uniform across weapons, so it cancels out of every comparison below, and
## leaving it out makes these assertions independent of the level curve.
func _dps(weapon: Weapon, defense: int = 0) -> float:
	return float(Damage.final_damage(weapon.power, defense)) * weapon.attack_speed


# --- The budget -------------------------------------------------------------

func test_the_slice_ships_exactly_ten_items() -> void:
	# DESIGN.md §2: 3 melee + 3 ranged + 4 clothing. The budget is the point —
	# an eleventh item is a design decision, not a content addition.
	assert_eq(_catalog.items.size(), 10)
	assert_eq(_catalog.in_slot(Item.Slot.MELEE).size(), 3)
	assert_eq(_catalog.in_slot(Item.Slot.RANGED).size(), 3)


func test_every_clothing_slot_holds_exactly_one_piece() -> void:
	# "Clothing in V1 is progression, not choice" (items.md): four pieces, four
	# slots, never a competing option inside the ten-item budget.
	for slot: Item.Slot in [Item.Slot.HEAD, Item.Slot.BODY, Item.Slot.LEGS, Item.Slot.HANDS]:
		assert_eq(_catalog.in_slot(slot).size(), 1, "slot %s" % Item.slot_name(slot))


func test_ids_are_unique_and_present() -> void:
	# Ids are save-file keys (README conventions). A duplicate or an empty one
	# is a load-time gear swap nobody asked for.
	var seen: Dictionary = {}
	for item: Item in _catalog.items:
		assert_ne(String(item.id), "", "'%s' has no id" % item.display_name)
		assert_false(seen.has(item.id), "duplicate id '%s'" % item.id)
		seen[item.id] = true


func test_the_starting_kit_is_the_wrench_and_the_zipgun() -> void:
	# DESIGN.md §2. Everything else is found, and item placement depends on it.
	var ids: Array = []
	for item: Item in _catalog.starting_items:
		ids.append(item.id)
	assert_eq(ids, [&"pipe_wrench", &"zipgun"])


func test_weapons_pin_their_own_slot() -> void:
	for item: Item in _catalog.items:
		if item is MeleeWeapon:
			assert_eq(item.slot, Item.Slot.MELEE, String(item.id))
		elif item is RangedWeapon:
			assert_eq(item.slot, Item.Slot.RANGED, String(item.id))
		else:
			assert_true(item.is_clothing(), "%s is neither weapon nor clothing" % item.id)


# --- The melee trio ---------------------------------------------------------

func test_melee_numbers_match_the_locked_table() -> void:
	var cases: Dictionary = {
		&"pipe_wrench": [8.0, 1.6],
		&"utility_blade": [5.0, 2.9],
		&"breaker_maul": [18.0, 0.8],
	}
	for item_id: StringName in cases:
		var weapon: MeleeWeapon = _item(item_id)
		assert_almost_eq(weapon.power, float(cases[item_id][0]), 0.001, String(item_id))
		assert_almost_eq(weapon.attack_speed, float(cases[item_id][1]), 0.001, String(item_id))


func test_the_found_melee_weapons_are_sidegrades_not_upgrades() -> void:
	# items.md structure rule: the trio trades speed against per-hit damage and
	# the found pair carry ~+12% total budget over the starter. Both halves are
	# asserted, because either alone permits the failure the rule is about —
	# a "sidegrade" that is strictly better, or an "upgrade" worth nothing.
	var wrench: float = _dps(_item(&"pipe_wrench"))
	for found: StringName in [&"utility_blade", &"breaker_maul"]:
		var edge: float = _dps(_item(found)) / wrench
		assert_between(edge, 1.05, 1.25, "%s DPS edge over the wrench" % found)


func test_the_heavy_weapon_wins_through_armour() -> void:
	# The flat-DEF heavy-hit bias (stats-and-curves.md) is the whole reason all
	# three weapons stay live. At DEF 5 — the top of the slice's range — the
	# order has to invert against the DEF-0 order above.
	var wrench: float = _dps(_item(&"pipe_wrench"), 5)
	var blade: float = _dps(_item(&"utility_blade"), 5)
	var maul: float = _dps(_item(&"breaker_maul"), 5)
	assert_gt(maul, wrench, "the maul must out-damage the wrench through armour")
	assert_gt(wrench, blade, "flat DEF must eat the light weapon")


func test_no_swing_commits_longer_than_the_design_budget() -> void:
	# DESIGN.md §3.2 budgets ~0.2s of anim lock, and the tail after
	# `active_time` is recovery the player can be punished during.
	for weapon: Item in _catalog.in_slot(Item.Slot.MELEE):
		var melee: MeleeWeapon = weapon
		assert_lte(melee.commit_time, 0.2, String(melee.id))
		assert_lt(melee.active_time, melee.commit_time, "%s has no recovery" % melee.id)


func test_every_melee_weapon_feeds_the_interlock() -> void:
	# The melee-to-ammo refill is the mechanical spine of the intertwined kit
	# (DESIGN.md §3.2). A weapon that does not pay into it is a weapon that
	# quietly opts its user out of ranged.
	for weapon: Item in _catalog.in_slot(Item.Slot.MELEE):
		assert_gt((weapon as MeleeWeapon).ammo_on_hit, 0, String(weapon.id))


# --- The ranged trio --------------------------------------------------------

func test_ranged_numbers_match_the_locked_table() -> void:
	var cases: Dictionary = {
		&"zipgun": [6.0, 1.5, 1],
		&"nailgun": [3.0, 4.0, 1],
		&"rivet_gun": [15.0, 0.6, 3],
	}
	for item_id: StringName in cases:
		var weapon: RangedWeapon = _item(item_id)
		assert_almost_eq(weapon.power, float(cases[item_id][0]), 0.001, String(item_id))
		assert_almost_eq(weapon.attack_speed, float(cases[item_id][1]), 0.001, String(item_id))
		assert_eq(weapon.energy_per_shot, int(cases[item_id][2]), String(item_id))


func test_the_nailgun_is_the_hungriest_per_point_of_damage() -> void:
	# Its locked identity: best DPS, worst damage-per-energy, so its users
	# close to melee *more* and the regen rhythm stays central. Equal cost per
	# shot is the mechanism — give it a cheaper shot and that inverts.
	var per_energy: Dictionary = {}
	for weapon: Item in _catalog.in_slot(Item.Slot.RANGED):
		var ranged: RangedWeapon = weapon
		per_energy[ranged.id] = ranged.power / float(ranged.energy_per_shot)
	assert_lt(float(per_energy[&"nailgun"]), float(per_energy[&"zipgun"]))
	assert_lt(float(per_energy[&"nailgun"]), float(per_energy[&"rivet_gun"]))


func test_the_rivet_gun_buys_the_most_damage_per_energy_through_armour() -> void:
	# The ranged trio's second sidegrade axis is damage-per-energy, and like
	# the melee trio it is flat DEF that makes the axis mean something: against
	# a bare target the cheap zipgun is the efficient one, against DEF 5 the
	# expensive slug is. Same bias, same reason all six weapons stay live.
	var per_energy: Dictionary = {}
	for weapon: Item in _catalog.in_slot(Item.Slot.RANGED):
		var ranged: RangedWeapon = weapon
		per_energy[ranged.id] = (
			float(Damage.final_damage(ranged.power, 5)) / float(ranged.energy_per_shot)
		)
	assert_gt(float(per_energy[&"rivet_gun"]), float(per_energy[&"zipgun"]))
	assert_gt(float(per_energy[&"rivet_gun"]), float(per_energy[&"nailgun"]))


func test_only_the_rivet_gun_arcs() -> void:
	# V1 simplicity: straight lines except the rivet's arc (items.md). The
	# exception is what makes it a skill-shot rather than a slow hitscan hose.
	for weapon: Item in _catalog.in_slot(Item.Slot.RANGED):
		var ranged: RangedWeapon = weapon
		if ranged.id == &"rivet_gun":
			assert_gt(ranged.projectile_gravity, 0.0)
		else:
			assert_eq(ranged.projectile_gravity, 0.0, String(ranged.id))


func test_every_ranged_weapon_can_still_reach_a_drone_overhead() -> void:
	# items.md's feel constraint for the vertical threat: fired straight up, a
	# shot must clear the movement envelope by a wide margin. The rivet gun's
	# arc is the one that can quietly fail this, which is why the test exists.
	var max_jump_height: float = 290.0
	for weapon: Item in _catalog.in_slot(Item.Slot.RANGED):
		var ranged: RangedWeapon = weapon
		var reach: float = ranged.projectile_speed * ranged.projectile_lifetime
		if ranged.projectile_gravity > 0.0:
			# Apex of a shot fired straight up: v squared over 2g.
			var apex: float = (
				ranged.projectile_speed * ranged.projectile_speed
				/ (2.0 * ranged.projectile_gravity)
			)
			reach = minf(reach, apex)
		assert_gt(reach, max_jump_height * 1.5, "%s cannot shoot upward" % ranged.id)


# --- Clothing ---------------------------------------------------------------

func test_clothing_def_matches_the_locked_table() -> void:
	var cases: Dictionary = {
		&"padded_jacket": 2,
		&"work_boots": 1,
		&"linesman_gloves": 1,
		&"scavved_hardhat": 1,
	}
	var total: int = 0
	for item_id: StringName in cases:
		var piece: Clothing = _item(item_id)
		assert_eq(piece.defense, int(cases[item_id]), String(item_id))
		total += piece.defense
	# Full-set DEF 5: a light hit drops from ~6 to ~1-2, a heavy from ~12 to
	# ~7. Felt, never trivializing — and the ceiling every encounter in the
	# district gets tuned under.
	assert_eq(total, 5, "the full set must total DEF 5")


func test_each_piece_carries_exactly_one_modifier() -> void:
	# "The pool contains exactly the modifiers shipped items use" — four, one
	# per piece. A second modifier on a piece is how a modifier *system* grows
	# out of four engine hooks without anyone deciding to build one.
	for item: Item in _catalog.items:
		if item is Clothing:
			assert_eq((item as Clothing).modifier_count(), 1, String(item.id))


func test_weapons_carry_no_modifiers() -> void:
	# Locked: a weapon's personality lives in damage, speed, energy cost and
	# projectile behaviour. Four more engine hooks would buy flavour the
	# sidegrades already deliver.
	for item: Item in _catalog.items:
		if not item.is_clothing():
			assert_false(item is Clothing, "%s is a weapon carrying modifiers" % item.id)


func test_the_hardhat_ships_its_juiced_quest_roll() -> void:
	# Placement makes the hardhat the quest reward, and "uniqueness is a juiced
	# value, not a new modifier" — so the only hardhat in the slice is the +2.
	assert_eq((_item(&"scavved_hardhat") as Clothing).melee_energy_bonus, 2)
