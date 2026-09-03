extends GutTest
## The Scav (docs/characters/enemies.md).
##
## The roster doc is explicit that the teaching role is the anchor and that a
## tuning change which breaks the lesson is wrong even if the numbers look
## better. So most of what is asserted here is the *lesson* — the windup can be
## baited, the recovery can be punished, melee cannot stunlock — rather than
## the mechanics underneath it. Those are the properties a plausible-looking
## tuning session can destroy without breaking anything that throws.

const FLOOR_TOP := 600.0

var _config: EnemyConfig
var _wrench: MeleeWeapon
var _root: Node2D
var _player: Player
var _scav: Enemy


func before_each() -> void:
	TestArena.release_all_input()
	Hitstop.cancel()
	_config = load("res://src/enemies/scav/scav.tres")
	_wrench = load("res://src/combat/weapons/wrench.tres")
	_root = Node2D.new()
	add_child_autofree(_root)


func after_each() -> void:
	TestArena.release_all_input()
	Hitstop.cancel()
	Engine.time_scale = 1.0


## Player on the left, Scav parked to the right of it. Distances are set per
## test by moving the player, which keeps the Scav's `home` fixed.
func _arena(scav_x: float = 900.0) -> void:
	TestArena.solid(_root, Vector2(0, FLOOR_TOP + 100.0), Vector2(12000, 200))
	_player = TestArena.player(_root, Vector2(0, FLOOR_TOP))
	_scav = TestArena.scav(_root, Vector2(scav_x, FLOOR_TOP))
	await wait_frames(3)


func _settle(frames: int) -> void:
	for _i: int in frames:
		await get_tree().physics_frame


func _place_player(at_x: float) -> void:
	_player.global_position = Vector2(at_x, FLOOR_TOP)
	_player.velocity = Vector2.ZERO


## Runs until the Scav reaches `wanted`, or gives up. Returns whether it did.
func _wait_for_state(wanted: StringName, max_frames: int = 240) -> bool:
	for _i: int in max_frames:
		if _scav.state_name() == wanted:
			return true
		await get_tree().physics_frame
	return false


# --- Patrol and aggro -------------------------------------------------------

func test_it_starts_on_patrol() -> void:
	await _arena()
	assert_eq(_scav.state_name(), &"Patrol")


func test_it_stays_inside_its_beat() -> void:
	await _arena(2000.0)  # far enough that the player is never noticed
	var start_x: float = _scav.global_position.x
	await _settle(180)

	# "A short beat" — an enemy that wanders is an enemy that is not where the
	# level designer put it. Some overshoot is fine; a walkabout is not.
	assert_lt(
		absf(_scav.global_position.x - start_x),
		_config.patrol_range * 1.5,
		"the Scav wandered off its beat"
	)
	assert_eq(_scav.state_name(), &"Patrol")


func test_it_notices_the_player_and_closes() -> void:
	await _arena()
	_place_player(_scav.global_position.x - _config.detection_range + 60.0)
	assert_true(await _wait_for_state(&"Chase"), "never aggroed")


func test_it_leashes_back_to_patrol() -> void:
	await _arena()
	_place_player(_scav.global_position.x - 200.0)
	assert_true(await _wait_for_state(&"Chase"))

	# Without a leash the first Scav follows the player through the district.
	_place_player(_scav.global_position.x - _config.give_up_range - 400.0)
	assert_true(await _wait_for_state(&"Patrol"), "never gave up the chase")


# --- The lunge, and the lesson it teaches -----------------------------------

func test_it_telegraphs_before_it_commits() -> void:
	await _arena()
	_place_player(_scav.global_position.x - 120.0)

	# The order is the whole point: it must be readable *before* it is
	# dangerous. A lunge with no windup in front of it teaches nothing.
	assert_true(await _wait_for_state(&"Windup"), "lunged with no telegraph")
	assert_true(await _wait_for_state(&"Lunge"), "telegraphed but never committed")
	assert_true(await _wait_for_state(&"Recover"), "lunged with no recovery")


func test_the_windup_does_not_track_the_player() -> void:
	await _arena()
	_place_player(_scav.global_position.x - 120.0)
	assert_true(await _wait_for_state(&"Windup"))

	var aimed_at: int = _scav.facing
	# Step around it mid-telegraph. If the Scav re-aims, the bait is a lie and
	# the entire spacing lesson collapses into a homing missile with a warning
	# light on it.
	_place_player(_scav.global_position.x + 400.0)
	assert_true(await _wait_for_state(&"Lunge"))

	assert_eq(_scav.facing, aimed_at, "the windup re-aimed at the player")
	assert_eq(signi(int(signf(_scav.velocity.x))), aimed_at, "it lunged the wrong way")


func test_the_recovery_is_long_enough_to_punish() -> void:
	# The overcommit is the reward half of "bait the lunge, step in, punish".
	# If recovery is shorter than a swing takes, there is nothing to punish
	# with and the Scav stops being a tutorial.
	assert_gt(
		_config.recover_time,
		_wrench.commit_time,
		"recovery is shorter than a wrench swing — the punish window is fake"
	)


func test_melee_cannot_stunlock_it() -> void:
	# stagger_time under the fastest weapon cooldown is what keeps the fight a
	# conversation. Above it, the answer to every Scav is to walk into it and
	# hold the melee button.
	assert_lt(
		_config.stagger_time,
		_wrench.cooldown(),
		"a Scav staggers for longer than the wrench takes to swing again"
	)


func test_a_hit_during_the_windup_interrupts_it() -> void:
	await _arena()
	_place_player(_scav.global_position.x - 120.0)
	assert_true(await _wait_for_state(&"Windup"))

	var hurtbox: Hurtbox = _scav.get_node("Hurtbox")
	hurtbox.receive(Attack.make(null, _scav.global_position - Vector2(100, 0), 8.0, 280.0))
	await _settle(2)

	# Baiting the lunge has to produce a visible reward, not just a number.
	assert_eq(_scav.state_name(), &"Stagger")


# --- Stat block -------------------------------------------------------------

func test_it_dies_in_two_or_three_wrench_hits() -> void:
	# docs/characters/enemies.md states this outright, and it is the anchor the
	# whole early-game pace hangs off.
	var per_hit: int = Damage.final_damage(_wrench.power, _config.defense)
	var hits: int = ceili(float(_config.max_hp) / float(per_hit))
	assert_between(hits, 2, 3, "a Scav takes %d wrench hits" % hits)


func test_it_ships_with_no_defense() -> void:
	# Enemy DEF is set last, after weapon numbers exist. M2 shipping a guessed
	# value would mistune the whole trio against it.
	assert_eq(_config.defense, 0)


func test_death_pays_out_once_and_is_terminal() -> void:
	await _arena(2000.0)
	var payouts: Array[int] = []
	Events.enemy_died.connect(func(_e: Node, xp: int) -> void: payouts.append(xp))

	var hurtbox: Hurtbox = _scav.get_node("Hurtbox")
	for _i: int in 4:
		hurtbox.receive(Attack.make(null, Vector2.ZERO, 8.0, 0.0))
		await _settle(2)

	assert_eq(payouts.size(), 1, "rewards paid out more than once")
	assert_eq(payouts[0], _config.xp_reward)
	# Death is terminal: a stray shot landing on a corpse must not walk it back
	# into Stagger and then into Patrol.
	assert_eq(_scav.state_name(), &"Dead")


func test_a_corpse_cannot_be_revived_by_another_hit() -> void:
	await _arena(2000.0)
	var hurtbox: Hurtbox = _scav.get_node("Hurtbox")
	for _i: int in 4:
		hurtbox.receive(Attack.make(null, Vector2.ZERO, 8.0, 0.0))
		await _settle(2)
	assert_eq(_scav.state_name(), &"Dead")

	hurtbox.receive(Attack.make(null, Vector2.ZERO, 8.0, 0.0))
	await _settle(2)
	assert_eq(_scav.state_name(), &"Dead")


# --- Contact versus the lunge -----------------------------------------------

func test_contact_is_armed_the_whole_time_it_is_alive() -> void:
	await _arena(2000.0)
	# An enemy is dangerous to touch for as long as it lives — that is what
	# makes spacing matter always, not only during windups.
	assert_true(_scav.contact_hitbox.is_active())
	assert_false(_scav.attack_hitbox.is_active(), "the attack box is armed outside a lunge")


func test_the_lunge_hits_harder_than_brushing_past() -> void:
	var combat: CombatConfig = load("res://src/combat/combat_config.tres")
	var contact: float = _config.contact_power(combat.contact_damage_mult)
	assert_lt(contact, _config.attack_power)
	assert_almost_eq(contact, _config.attack_power * 0.5, 0.001, "contact is half power")


# --- Knockback travel -------------------------------------------------------

## Peak displacement from one impulse, starting from rest.
##
## Peak rather than final, because the training dummy walks back to its anchor
## once it slows below its return speed — measuring where it ends up conflates
## "how far the hit threw it" with "how far it has already recovered", which
## is not what a player reads.
func _peak_travel(body: Node2D, knockback: float, frames: int) -> float:
	var hurtbox: Hurtbox = body.get_node("Hurtbox")
	body.velocity = Vector2.ZERO
	var start_x: float = body.global_position.x
	hurtbox.receive(
		Attack.make(null, body.global_position - Vector2(200.0, 0.0), 8.0, knockback)
	)
	var peak: float = 0.0
	for _i: int in frames:
		await get_tree().physics_frame
		peak = maxf(peak, absf(body.global_position.x - start_x))
	return peak


func test_a_staggered_scav_is_not_thrown_further_than_the_dummy() -> void:
	await _arena(2000.0)
	var dummy := TestArena.dummy(_root, Vector2(4000.0, FLOOR_TOP), 200, 0, 1)
	await _settle(3)

	var scav_travel: float = await _peak_travel(_scav, _wrench.knockback, 16)
	var dummy_travel: float = await _peak_travel(dummy, _wrench.knockback, 16)

	# The knockback numbers were tuned by feel against the training dummy. A
	# staggered enemy with no friction was the only body in the game that did
	# not decay the impulse: it slid for the whole stagger and read as the
	# weapon being wildly overpowered rather than as the enemy being slippery.
	assert_almost_eq(
		scav_travel,
		dummy_travel,
		18.0,
		"a Scav is thrown %.0fpx where the dummy goes %.0fpx from the same hit"
		% [scav_travel, dummy_travel]
	)
