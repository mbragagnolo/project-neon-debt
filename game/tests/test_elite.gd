extends GutTest
## The Elite Scav (docs/characters/enemies.md): same silhouette, same
## moveset, faster, and no overcommit — the tutorial answer stops working.

var _elite: EnemyConfig
var _scav: EnemyConfig
var _wrench: MeleeWeapon


func before_each() -> void:
	_elite = load("res://src/enemies/scav/elite_scav.tres")
	_scav = load("res://src/enemies/scav/scav.tres")
	_wrench = load("res://src/combat/weapons/wrench.tres")


func test_it_is_the_scav_scene_with_another_resource() -> void:
	# "An enemy is a resource, not a subclass" (src/enemies/README.md).
	var scav_scene: Node = autofree(load("res://src/enemies/scav/scav.tscn").instantiate())
	var elite_scene: Node = autofree(load("res://src/enemies/scav/elite_scav.tscn").instantiate())
	assert_eq(elite_scene.get_script(), scav_scene.get_script())
	var scav_states: Array = []
	for state: Node in scav_scene.get_node("StateMachine").get_children():
		scav_states.append(state.name)
	var elite_states: Array = []
	for state: Node in elite_scene.get_node("StateMachine").get_children():
		elite_states.append(state.name)
	assert_eq(elite_states, scav_states, "the moveset drifted")


func test_the_overcommit_is_gone() -> void:
	# The Scav's invariant, inverted: recovery is shorter than a swing, so
	# bait-and-punish is no longer a plan.
	assert_lt(_elite.recover_time, _wrench.commit_time, "the Elite can still be punished like a Scav")
	assert_gt(_scav.recover_time, _wrench.commit_time, "precondition: the Scav still can be")


func test_it_is_faster_everywhere() -> void:
	assert_gt(_elite.chase_speed, _scav.chase_speed)
	assert_gt(_elite.lunge_speed, _scav.lunge_speed)
	assert_lt(_elite.windup_time, _scav.windup_time)
	assert_lt(_elite.lunge_cooldown, _scav.lunge_cooldown)


func test_it_still_telegraphs() -> void:
	# Faster, not unfair: a lunge with no windup teaches nothing.
	assert_gte(_elite.windup_time, 0.3)


func test_melee_still_cannot_stunlock_it() -> void:
	# The wrench meets its threshold, so the wrench's cooldown is the bound.
	var combat: CombatConfig = load("res://src/combat/combat_config.tres")
	var wrench_hit: int = Damage.final_damage(_wrench.damage_at(PlayerStats.strength(), combat), _elite.defense)
	assert_gte(wrench_hit, _elite.stagger_threshold, "precondition: the wrench staggers it")
	assert_lt(_elite.stagger_time, _wrench.cooldown())


func test_it_rewards_like_a_miniboss() -> void:
	assert_gte(_elite.xp_reward, _scav.xp_reward * 4)
	assert_gte(_elite.credit_reward, _scav.credit_reward * 4)


func test_it_takes_the_def_pass() -> void:
	assert_eq(_elite.defense, 2)
	assert_eq(_elite.stagger_threshold, 8)


func test_the_sump_guard_stays_dead() -> void:
	# A miniboss that respawns on every re-entry is a toll, not a wall.
	var den: Node = autofree(load("res://rooms/stacks/defaulter_den.tscn").instantiate())
	var elite: Encounter = den.get_node_or_null("Elite") as Encounter
	assert_not_null(elite, "the sump has no Elite encounter — regenerate")
	if elite != null:
		assert_ne(String(elite.persist_flag), "", "the Elite comes back")
		assert_eq(elite.respawn_delay, 0.0)
