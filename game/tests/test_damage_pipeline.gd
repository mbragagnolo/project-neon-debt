extends GutTest
## The eleven-step pipeline's decisions (docs/combat/damage-pipeline.md).
##
## These are deliberately scene-free: steps 3–8 are pure arithmetic and pure
## rejections, and the whole point of writing the order down was that it can be
## answered without running a fight. What is protected here is not "the code
## calls final_damage()" — it is "DEF applies before the floor, and immunity
## applies before DEF", which are the two orderings the spec calls
## load-bearing.

var _config: CombatConfig


func before_each() -> void:
	_config = load("res://src/combat/combat_config.tres")


func _health(max_hp: int, defense: int, stagger_threshold: int = 1) -> Health:
	var health := Health.new()
	health.max_hp = max_hp
	health.defense = defense
	health.stagger_threshold = stagger_threshold
	# Added to the tree so `_ready` runs and hp is sized; a Health that never
	# readied reports hp 0, which reads as dead and would pass tests for the
	# wrong reason.
	add_child_autofree(health)
	return health


func _attack(power: float, knockback: float = 0.0) -> Attack:
	return Attack.make(null, Vector2.ZERO, power, knockback)


# --- Step 4: the stat multiplier ---------------------------------------------

## The reference table in docs/rpg/stats-and-curves.md is the contract. If
## these move, every enemy stat block in the game silently rebalances.
func test_stat_multiplier_matches_the_locked_reference_table() -> void:
	var cases: Dictionary = {0: 1.00, 10: 1.40, 20: 1.67, 30: 1.86, 40: 2.00, 99: 2.42}
	for stat: int in cases:
		var actual: float = Damage.stat_multiplier(stat, 2.0, 40.0)
		assert_almost_eq(actual, float(cases[stat]), 0.005, "stat %d" % stat)


func test_stat_multiplier_saturates_below_the_asymptote() -> void:
	# max_bonus 2.0 means the curve approaches ×3.0 and never reaches it. This
	# is the property that lets slice-tuned enemy HP survive V2's manual
	# allocation without a rebalance.
	assert_lt(Damage.stat_multiplier(100000, 2.0, 40.0), 3.0)


func test_enemies_skip_the_stat_multiplier_entirely() -> void:
	# Flat attack_power: what an encounter author types is what it hits for.
	var attack := _attack(6.0)
	attack.scales_with_stat = false
	attack.stat = 99
	assert_eq(Damage.raw_damage(attack, _config), 6.0)


# --- Step 6: DEF and the floor ----------------------------------------------

func test_defense_is_subtracted_flat() -> void:
	assert_eq(Damage.final_damage(8.0, 5), 3)


func test_damage_floors_at_one_however_large_the_defense() -> void:
	# Every landed hit does something. DEF can never make a target unhittable
	# with the "wrong" verb, and chip-killing a tank stays legitimate.
	assert_eq(Damage.final_damage(6.0, 20), 1)
	assert_eq(Damage.final_damage(1.0, 999), 1)


func test_flat_defense_taxes_light_hits_harder_than_heavy_ones() -> void:
	# The heavy-hit bias is kept as texture, not fixed (stats-and-curves.md):
	# it is what pushes players toward heavy hits and hacks against armour,
	# which is the Riot unit's entire job description.
	var light_loss: float = 1.0 - float(Damage.final_damage(6.0, 4)) / 6.0
	var heavy_loss: float = 1.0 - float(Damage.final_damage(20.0, 4)) / 20.0
	assert_gt(light_loss, heavy_loss)


# --- Step 5 before step 6: immunity is a rejection, not a reduction ----------

func test_positional_immunity_rejects_rather_than_reducing_to_the_floor() -> void:
	var health := _health(40, 0)
	health.tags = [Health.TAG_IMMUNE_RANGED_FRONTAL]
	var attack := _attack(6.0)
	attack.is_ranged = true

	var result: DamageResult = Damage.resolve(attack, health, _config)

	# The distinction this test exists for: a shielded hit must produce *no*
	# damage, not the floor of 1. Reduced-to-1 would leak chip damage through
	# a shield and make the tag read as a lie.
	assert_false(result.landed)
	assert_eq(result.damage, 0)
	assert_eq(result.rejection, DamageResult.Rejection.IMMUNE)


func test_melee_ignores_ranged_immunity() -> void:
	var health := _health(40, 0)
	health.tags = [Health.TAG_IMMUNE_RANGED_FRONTAL]
	var result: DamageResult = Damage.resolve(_attack(8.0), health, _config)
	assert_true(result.landed)
	assert_eq(result.damage, 8)


# --- Step 3: dead and invulnerable targets ----------------------------------

func test_invulnerable_targets_are_rejected() -> void:
	var health := _health(40, 0)
	health.grant_iframes(1.0)
	var result: DamageResult = Damage.resolve(_attack(8.0), health, _config)
	assert_false(result.landed)
	assert_eq(result.rejection, DamageResult.Rejection.INVULNERABLE)


func test_dead_targets_are_rejected() -> void:
	var health := _health(40, 0)
	health.apply_damage(40, _attack(40.0))
	assert_true(health.is_dead())
	var result: DamageResult = Damage.resolve(_attack(8.0), health, _config)
	assert_false(result.landed)
	assert_eq(result.rejection, DamageResult.Rejection.INVULNERABLE)


# --- Step 8: stagger --------------------------------------------------------

func test_stagger_needs_a_single_hit_at_or_above_the_threshold() -> void:
	var heavy := _health(40, 0, 12)
	assert_false(Damage.resolve(_attack(8.0), heavy, _config).staggered, "wrench flinches")
	assert_true(Damage.resolve(_attack(18.0), heavy, _config).staggered, "maul staggers")


func test_contact_damage_never_staggers() -> void:
	var health := _health(40, 0, 1)
	var attack := _attack(20.0)
	attack.is_contact = true
	var result: DamageResult = Damage.resolve(attack, health, _config)
	assert_true(result.landed)
	assert_false(result.staggered, "brushing a body is not a hit anyone landed")


# --- Hitstop tiers ----------------------------------------------------------

func test_floor_one_hits_get_no_hitstop() -> void:
	# A freeze reporting an impact the health bar disagrees with is a lie, and
	# silence teaches "wrong tool" faster than a number does.
	assert_eq(_config.hitstop_frames_for(1), 0)


func test_hitstop_tiers_split_at_the_heavy_threshold() -> void:
	var threshold: int = _config.hitstop_heavy_threshold
	assert_eq(_config.hitstop_frames_for(threshold - 1), _config.hitstop_light_frames)
	assert_eq(_config.hitstop_frames_for(threshold), _config.hitstop_heavy_frames)
	assert_gt(_config.hitstop_heavy_frames, _config.hitstop_light_frames)


# --- The trio's numbers, as authored ----------------------------------------

func test_the_starting_weapons_hit_for_their_authored_numbers() -> void:
	# Guards the wiring between items.md and the .tres files: at stat 0 against
	# DEF 0, a weapon must do exactly what the design doc says it does.
	var wrench: MeleeWeapon = load("res://src/combat/weapons/wrench.tres")
	var zipgun: RangedWeapon = load("res://src/combat/weapons/zipgun.tres")
	var health := _health(40, 0)

	assert_eq(Damage.resolve(_attack(wrench.power), health, _config).damage, 8)
	assert_eq(Damage.resolve(_attack(zipgun.power), health, _config).damage, 6)


## Pins the *relationship*, not the number. `attack_speed` is the tuning lever
## the whole armour-balance argument rests on, so it moves every playtest — a
## test that hardcodes it would fail on every session that did its job.
func test_attack_speed_is_the_authority_on_cooldown() -> void:
	var weapons: Array[Weapon] = [
		load("res://src/combat/weapons/wrench.tres"),
		load("res://src/combat/weapons/zipgun.tres"),
	]
	for weapon: Weapon in weapons:
		assert_gt(weapon.attack_speed, 0.0, "%s cannot be swung" % weapon.display_name)
		assert_almost_eq(weapon.cooldown(), 1.0 / weapon.attack_speed, 0.0001)


func test_a_swing_finishes_before_the_next_one_is_allowed() -> void:
	# The guard rail on tuning melee speed upward: once the cooldown drops
	# under the commit time, a second swing becomes legal while the first is
	# still locking the player, and the state machine starts eating presses.
	var wrench: MeleeWeapon = load("res://src/combat/weapons/wrench.tres")
	assert_lte(
		wrench.commit_time,
		wrench.cooldown(),
		"attack_speed has outrun commit_time — swings would overlap"
	)


func test_the_swing_commits_for_no_longer_than_the_design_budget() -> void:
	# DESIGN.md §3.2 budgets ~0.2s max of anim lock. Longer than that stops
	# reading as commitment and starts reading as input lag.
	var wrench: MeleeWeapon = load("res://src/combat/weapons/wrench.tres")
	assert_lte(wrench.commit_time, 0.2)
	assert_lt(wrench.active_time, wrench.commit_time, "the tail must be punishable recovery")
