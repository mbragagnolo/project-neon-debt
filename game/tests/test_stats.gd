extends GutTest
## The sheet, the level-up moment and the wallet
## (docs/rpg/stats-and-curves.md, starting values).
##
## These run against the real `PlayerStats` autoload rather than a fresh
## instance, because half of what is worth protecting is the wiring: that a
## dead Scav actually pays out, that a level-up actually announces itself. Both
## ends reset the sheet, so a test that raises the player to level 6 cannot
## quietly re-tune the combat tests that run after it.

var _stat_curve: StatCurve


func before_each() -> void:
	PlayerStats.reset()
	Inventory.reset()
	_stat_curve = load("res://src/rpg/stat_curve.tres")


func after_each() -> void:
	PlayerStats.reset()
	Inventory.reset()


## Raise the level without going through the XP path, for the tests that are
## about the curve rather than about levelling.
func _at_level(level: int) -> void:
	PlayerStats.restore({"level": level, "xp": PlayerStats.xp_curve.cumulative_to(level)})


# --- The sheet --------------------------------------------------------------

func test_a_fresh_sheet_matches_the_locked_starting_values() -> void:
	assert_eq(PlayerStats.level, 1)
	assert_eq(PlayerStats.base_max_hp(), 40, "three big mistakes, not ten")
	assert_eq(PlayerStats.base_max_ram(), 12, "three Firewall casts")
	assert_eq(PlayerStats.strength(), 5)
	assert_eq(PlayerStats.dexterity(), 5)
	assert_eq(PlayerStats.intelligence(), 5)


func test_level_six_matches_the_locked_end_of_the_slice() -> void:
	_at_level(6)
	assert_eq(PlayerStats.base_max_hp(), 65)
	assert_eq(PlayerStats.base_max_ram(), 22)
	assert_eq(PlayerStats.strength(), 20)


func test_the_attack_stats_rise_in_lockstep() -> void:
	# Locked: the verbs stay balanced by default and only weapons and clothing
	# differentiate them. V2's independent builds are what break this, on
	# purpose, and they should have to edit the curve resource to do it.
	for level: int in range(1, 10):
		_at_level(level)
		assert_eq(PlayerStats.strength(), PlayerStats.dexterity(), "level %d" % level)
		assert_eq(PlayerStats.strength(), PlayerStats.intelligence(), "level %d" % level)


func test_no_level_ever_grants_def() -> void:
	# "DEF comes from gear only" is the load-bearing rule behind clothing's
	# monopoly on survivability — grinding makes you hit harder, never tank
	# better. It is kept by the curve having nowhere to type the number, so
	# that is what gets asserted rather than a value.
	for property: Dictionary in _stat_curve.get_property_list():
		assert_false(
			String(property["name"]).to_lower().contains("def"),
			"StatCurve grew a DEF field: %s" % property["name"]
		)


func test_the_slice_moves_the_multiplier_less_than_gear_does() -> void:
	# The thesis, as a number: six levels are worth ~+36% damage, swapping the
	# wrench for the maul is worth ~+125%. If a re-tune ever inverts this, the
	# game has quietly become one where grinding beats exploring.
	var config: CombatConfig = load("res://src/combat/combat_config.tres")
	_at_level(1)
	var level_1: float = Damage.stat_multiplier(
		PlayerStats.strength(), config.stat_max_bonus, config.stat_half_point
	)
	_at_level(6)
	var level_6: float = Damage.stat_multiplier(
		PlayerStats.strength(), config.stat_max_bonus, config.stat_half_point
	)
	var from_levels: float = level_6 / level_1
	var wrench: Weapon = load("res://src/combat/weapons/wrench.tres")
	var maul: Weapon = load("res://src/combat/weapons/breaker_maul.tres")
	var from_gear: float = maul.power / wrench.power
	assert_lt(from_levels, 1.6, "six levels are worth more than +60% damage")
	assert_gt(from_gear, from_levels * 1.5, "gear no longer out-differentiates levels")


# --- Levelling --------------------------------------------------------------

func test_hitting_the_threshold_exactly_levels_up() -> void:
	PlayerStats.grant_xp(59)
	assert_eq(PlayerStats.level, 1, "one XP short")
	PlayerStats.grant_xp(1)
	assert_eq(PlayerStats.level, 2)


func test_xp_is_lifetime_and_the_bar_reads_the_remainder() -> void:
	PlayerStats.grant_xp(75)
	assert_eq(PlayerStats.xp, 75, "XP is never spent")
	assert_eq(PlayerStats.level, 2)
	assert_eq(PlayerStats.xp_into_level(), 15)
	assert_eq(PlayerStats.xp_for_level(), 90)


func test_one_signal_per_level_even_from_a_single_payout() -> void:
	# A boss worth two levels should feel like two level-ups. Whoever draws the
	# flourish should not have to work out that it happened twice.
	var levels: Array = []
	Events.level_gained.connect(func(new_level: int) -> void: levels.append(new_level))
	PlayerStats.grant_xp(200)
	assert_eq(levels, [2, 3])


func test_a_dead_enemy_pays_xp_and_credits() -> void:
	Events.enemy_died.emit(null, 10, 5)
	assert_eq(PlayerStats.xp, 10)
	assert_eq(PlayerStats.credits, 5)


func test_the_sheet_is_published_after_a_level_up_not_before() -> void:
	# The HUD redraws off `stats_changed`, so publishing mid-level-up would
	# paint the old max HP over the new one.
	var published: Array = []
	Events.stats_changed.connect(func(sheet: Dictionary) -> void: published.append(sheet))
	PlayerStats.grant_xp(60)
	assert_eq(published.size(), 1)
	assert_eq(int(published[0]["level"]), 2)
	assert_eq(int(published[0]["max_hp"]), 45)


# --- Credits ----------------------------------------------------------------

func test_spending_more_than_you_have_spends_nothing() -> void:
	PlayerStats.grant_credits(30)
	assert_false(PlayerStats.spend_credits(31))
	assert_eq(PlayerStats.credits, 30)
	assert_true(PlayerStats.spend_credits(30))
	assert_eq(PlayerStats.credits, 0)


# --- Serialization ----------------------------------------------------------

func test_snapshot_restore_round_trip() -> void:
	PlayerStats.grant_xp(400)
	PlayerStats.grant_credits(120)
	var snapshot: Dictionary = PlayerStats.snapshot()
	PlayerStats.reset()
	PlayerStats.restore(snapshot)
	assert_eq(PlayerStats.level, 4)
	assert_eq(PlayerStats.xp, 400)
	assert_eq(PlayerStats.credits, 120)


func test_restoring_from_nothing_is_a_fresh_sheet() -> void:
	# This is the path a version-1 save takes through a build that has a stat
	# sheet: the key is simply absent, and absent must mean level 1 rather than
	# level 0 or a crash.
	PlayerStats.grant_xp(400)
	PlayerStats.restore({})
	assert_eq(PlayerStats.level, 1)
	assert_eq(PlayerStats.xp, 0)


# --- The effective sheet ----------------------------------------------------
#
# The layer items.md asked M3 to force into existence. Each of these is one
# modifier with exactly one read-site, and each has the same failure mode: the
# number is right in the item file, right on the equip screen, and never
# reaches the thing it is supposed to bend.

func test_the_jacket_is_the_only_thing_that_moves_max_hp() -> void:
	assert_eq(PlayerStats.effective_max_hp(), 40)
	Inventory.grant(&"work_boots")
	assert_eq(PlayerStats.effective_max_hp(), 40, "boots are not a jacket")
	Inventory.grant(&"padded_jacket")
	assert_eq(PlayerStats.effective_max_hp(), 50)


func test_def_is_gear_and_only_gear_at_every_level() -> void:
	# The rule clothing's whole monopoly on survivability rests on. Levelling
	# to the end of the slice must not add a single point.
	_at_level(6)
	assert_eq(PlayerStats.effective_defense(), 0, "a level granted DEF")
	Inventory.grant(&"padded_jacket")
	assert_eq(PlayerStats.effective_defense(), 2)


func test_the_boots_bend_the_dash_cooldown_without_touching_the_config() -> void:
	# The controller must read through here rather than off `MovementConfig`,
	# and the config must stay the single source of the base number — a
	# modifier that edits the tuning resource is a modifier that survives being
	# unequipped.
	var movement: MovementConfig = load("res://src/player/movement_config.tres")
	var base: float = movement.dash_cooldown
	assert_almost_eq(PlayerStats.effective_dash_cooldown(base), base, 0.0001)
	Inventory.grant(&"work_boots")
	assert_almost_eq(PlayerStats.effective_dash_cooldown(base), base * 0.85, 0.0001)
	assert_almost_eq(movement.dash_cooldown, base, 0.0001, "the boots edited the config")


func test_the_hardhat_raises_the_interlock_payout() -> void:
	# The melee-to-energy refill stays the weapon's number bent by equipment,
	# never a constant in the pipeline — which is what lets V2 switch the
	# intertwined kit off by zeroing a field on three items.
	var wrench: MeleeWeapon = load("res://src/combat/weapons/wrench.tres")
	assert_eq(PlayerStats.effective_ammo_on_hit(wrench), wrench.ammo_on_hit)
	Inventory.grant(&"scavved_hardhat")
	assert_eq(PlayerStats.effective_ammo_on_hit(wrench), wrench.ammo_on_hit + 2)


func test_the_gloves_bend_the_regen_rate_that_m4_will_tick() -> void:
	Inventory.grant(&"linesman_gloves")
	assert_almost_eq(PlayerStats.effective_ram_regen(2.0), 2.5, 0.0001)


func test_equipping_republishes_the_sheet() -> void:
	# Gear changes the sheet as surely as a level does, and everything that
	# draws the sheet listens to one signal.
	var published: Array = []
	Events.stats_changed.connect(func(sheet: Dictionary) -> void: published.append(sheet))
	Inventory.grant(&"padded_jacket")
	assert_gt(published.size(), 0, "equipping published nothing")
	var latest: Dictionary = published[published.size() - 1]
	assert_eq(int(latest["max_hp"]), 50)
	assert_eq(int(latest["def"]), 2)


func test_the_sheet_rides_along_in_the_game_state_snapshot() -> void:
	# PlayerStats registers itself; GameState never learns what a level is.
	PlayerStats.grant_xp(60)
	var save: Dictionary = GameState.snapshot()
	assert_true(save.has("stats"), "the stat sheet is missing from the save")
	assert_eq(int((save["stats"] as Dictionary)["level"]), 2)
	assert_eq(int(save["version"]), 2)
