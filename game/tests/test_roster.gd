extends GutTest
## The roster as a whole (docs/characters/enemies.md, the DEF pass; docs/rpg/
## stats-and-curves.md, the XP curve re-solved against the placed district).

const CONFIGS: Dictionary = {
	"e": "res://src/enemies/scav/scav.tres",
	"d": "res://src/enemies/drone/drone.tres",
	"r": "res://src/enemies/riot/riot.tres",
	"E": "res://src/enemies/scav/elite_scav.tres",
	"B": "res://src/enemies/boss_landlord/landlord.tres",
}
const SCENES: Dictionary = {
	"e": "res://src/enemies/scav/scav.tscn",
	"d": "res://src/enemies/drone/drone.tscn",
	"r": "res://src/enemies/riot/riot.tscn",
	"E": "res://src/enemies/scav/elite_scav.tscn",
	"B": "res://src/enemies/boss_landlord/landlord.tscn",
}

var _configs: Dictionary = {}
var _combat: CombatConfig


func before_all() -> void:
	for kind: String in CONFIGS:
		_configs[kind] = load(CONFIGS[kind])
	_combat = load("res://src/combat/combat_config.tres")


func test_the_def_pass_is_the_locked_one() -> void:
	# Set last, after the weapons were tuned (stats-and-curves.md). 0 to 5
	# across the slice; the Scav and the drone die to being reached, armour
	# is the Riot unit's lesson, the boss is the top of the range.
	var expected: Dictionary = {"e": 0, "d": 0, "r": 3, "E": 2, "B": 5}
	for kind: String in expected:
		var config: EnemyConfig = _configs[kind]
		assert_eq(config.defense, int(expected[kind]), config.display_name)
		assert_between(config.defense, 0, 5, "%s is outside the locked range" % config.display_name)


func test_rewards_keep_the_locked_ratios() -> void:
	var scav: EnemyConfig = _configs["e"]
	assert_eq((_configs["d"] as EnemyConfig).xp_reward, 14)
	assert_eq((_configs["r"] as EnemyConfig).xp_reward, 22)
	assert_eq((_configs["E"] as EnemyConfig).xp_reward, 45)
	assert_eq((_configs["B"] as EnemyConfig).xp_reward, 200)
	assert_eq((_configs["r"] as EnemyConfig).credit_reward, scav.credit_reward * 3)
	assert_gte((_configs["E"] as EnemyConfig).credit_reward, scav.credit_reward * 4)


func test_the_district_holds_the_xp_the_curve_was_solved_against() -> void:
	# The premise stats-and-curves.md recorded, now measured: every enemy
	# letter in every room spec, times its authored reward. `assumed_district_xp`
	# is the curve's recorded premise; if the two drift apart, re-solve `base`.
	var total: int = 0
	var counts: Dictionary = {}
	for spec: RoomSpec in RoomSpec.load_all("res://tools/stacks"):
		for kind: String in CONFIGS:
			var n: int = spec.positions_of(kind).size()
			counts[kind] = int(counts.get(kind, 0)) + n
			total += n * (_configs[kind] as EnemyConfig).xp_reward
	var curve: XPCurve = load("res://src/rpg/xp_curve.tres")
	assert_almost_eq(total, curve.assumed_district_xp, curve.assumed_district_xp * 0.03,
		"the district holds %d XP (%s); the curve assumes %d" % [total, str(counts), curve.assumed_district_xp])


func test_every_enemy_scene_mirrors_its_config_onto_health() -> void:
	for kind: String in SCENES:
		var enemy: Node = autofree((load(SCENES[kind]) as PackedScene).instantiate())
		add_child(enemy)
		var config: EnemyConfig = _configs[kind]
		var health: Health = enemy.get_node("Health")
		assert_eq(health.max_hp, config.max_hp, config.display_name)
		assert_eq(health.defense, config.defense, config.display_name)
		assert_eq(health.stagger_threshold, config.stagger_threshold, config.display_name)
		assert_eq(health.tags, config.tags, config.display_name)
		remove_child(enemy)


func test_contact_is_half_power_for_everyone() -> void:
	for kind: String in CONFIGS:
		var config: EnemyConfig = _configs[kind]
		assert_almost_eq(config.contact_power(_combat.contact_damage_mult), config.attack_power * 0.5, 0.001, config.display_name)


func test_nobody_can_be_stunlocked_by_the_fastest_weapon_that_staggers_them() -> void:
	# The Scav's invariant, generalised: an enemy's stagger must end before
	# the fastest weapon *that meets its threshold* can swing again. Measured
	# at level 5, the sheet the later enemies are met with.
	var weapons: Array[String] = [
		"res://src/combat/weapons/utility_blade.tres",
		"res://src/combat/weapons/wrench.tres",
		"res://src/combat/weapons/breaker_maul.tres",
	]
	var stat: int = PlayerStats.stat_curve.attack_stat_at(5)
	for kind: String in CONFIGS:
		var config: EnemyConfig = _configs[kind]
		var fastest_cooldown: float = INF
		for path: String in weapons:
			var weapon: MeleeWeapon = load(path)
			var hit: int = Damage.final_damage(weapon.damage_at(stat, _combat), config.defense)
			if hit >= config.stagger_threshold:
				fastest_cooldown = minf(fastest_cooldown, weapon.cooldown())
		if fastest_cooldown == INF:
			continue
		assert_lt(config.stagger_time, fastest_cooldown,
			"%s staggers for %.2fs, longer than the %.2fs cooldown of the fastest weapon that staggers it" % [config.display_name, config.stagger_time, fastest_cooldown])


func test_the_heavy_hitstop_tier_is_reachable_now() -> void:
	# damage-pipeline.md deferred closing `hitstop_heavy_threshold` until a
	# weapon reached it. The maul does, against every DEF in the slice.
	var maul: MeleeWeapon = load("res://src/combat/weapons/breaker_maul.tres")
	var stat: int = PlayerStats.stat_curve.attack_stat_at(3)
	for kind: String in CONFIGS:
		var config: EnemyConfig = _configs[kind]
		var hit: int = Damage.final_damage(maul.damage_at(stat, _combat), config.defense)
		assert_gte(hit, _combat.hitstop_heavy_threshold, "the maul lands light on %s" % config.display_name)
	var wrench: MeleeWeapon = load("res://src/combat/weapons/wrench.tres")
	assert_lt(Damage.final_damage(wrench.damage_at(stat, _combat), 0), _combat.hitstop_heavy_threshold, "the wrench should stay light")
