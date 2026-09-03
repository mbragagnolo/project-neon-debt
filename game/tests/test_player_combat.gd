extends GutTest
## Behavioural tests for the M2 verbs, driven through real input and real
## physics — the same reasoning as the M1 movement tests.
##
## What is protected here is not "the code calls activate()" but the rules a
## regression would make invisible until someone plays: one swing hits once,
## a hit refills ammo and a whiff does not, the i-frame window actually gates
## contact damage, and a flinch moves a body less far than a stagger.

const FLOOR_TOP := 600.0
## Inside the wrench's reach (box centred 52px ahead, 72px wide → 16..88).
const IN_REACH := 80.0
const OUT_OF_REACH := 600.0

var _config: CombatConfig
var _wrench: MeleeWeapon
var _root: Node2D
var _player: Player


func before_each() -> void:
	TestArena.release_all_input()
	Hitstop.cancel()
	_config = load("res://src/combat/combat_config.tres")
	_wrench = load("res://src/combat/weapons/wrench.tres")
	_root = Node2D.new()
	add_child_autofree(_root)


func after_each() -> void:
	TestArena.release_all_input()
	# Combat freezes the engine; a stranded time_scale would take the rest of
	# the suite down with it.
	Hitstop.cancel()
	Engine.time_scale = 1.0


func _arena() -> void:
	TestArena.solid(_root, Vector2(0, FLOOR_TOP + 100.0), Vector2(6000, 200))
	_player = TestArena.player(_root, Vector2(0, FLOOR_TOP))
	await wait_frames(3)


## Physics steps, safe to call while hitstop holds the engine at zero.
func _settle(frames: int) -> void:
	for _i: int in frames:
		await get_tree().physics_frame


func _tap(action: String) -> void:
	Input.action_press(action)
	await get_tree().physics_frame
	Input.action_release(action)


# --- Step 2: one swing, one hit ---------------------------------------------

func test_a_single_swing_hits_a_target_only_once() -> void:
	await _arena()
	var dummy := TestArena.dummy(_root, Vector2(IN_REACH, FLOOR_TOP))
	await _settle(3)

	await _tap("attack_melee")
	await _settle(30)

	# The box is armed for several frames and swept every one of them. Without
	# the per-swing target set this would read 40 - 8×N.
	assert_eq(dummy.health.hp, 40 - int(_wrench.power), "one swing dealt more than one hit")


func test_a_second_swing_hits_the_same_target_again() -> void:
	await _arena()
	var dummy := TestArena.dummy(_root, Vector2(IN_REACH, FLOOR_TOP))
	await _settle(3)

	await _tap("attack_melee")
	await _settle(80)  # past the wrench's 1.0s cooldown
	await _tap("attack_melee")
	await _settle(30)

	# The target set is scoped to the swing, not to the target: re-arming is a
	# genuinely new attack.
	assert_eq(dummy.health.hp, 40 - int(_wrench.power) * 2)


# --- Step 10: the melee→ammo interlock --------------------------------------

func test_a_landed_melee_hit_refills_ammo() -> void:
	await _arena()
	var dummy := TestArena.dummy(_root, Vector2(IN_REACH, FLOOR_TOP))
	await _settle(3)

	_player.spend_ammo(3)
	var before: int = _player.ammo

	await _tap("attack_melee")
	await _settle(30)

	assert_gt(dummy.health.hp, 0, "the dummy should have survived to prove the hit landed")
	assert_eq(_player.ammo, before + _wrench.ammo_on_hit)


func test_a_whiffed_swing_refills_nothing() -> void:
	await _arena()
	TestArena.dummy(_root, Vector2(OUT_OF_REACH, FLOOR_TOP))
	await _settle(3)

	_player.spend_ammo(3)
	var before: int = _player.ammo

	await _tap("attack_melee")
	await _settle(30)

	# Refunding a whiff would remove the only pressure the loop has.
	assert_eq(_player.ammo, before)


func test_ammo_does_not_bank_past_the_cap() -> void:
	await _arena()
	var dummy := TestArena.dummy(_root, Vector2(IN_REACH, FLOOR_TOP))
	await _settle(3)

	assert_eq(_player.ammo, _player.max_ammo, "precondition: starts full")
	await _tap("attack_melee")
	await _settle(30)

	assert_gt(dummy.health.hp, 0)
	# Meleeing at full ammo should feel like the wrong choice, not like saving up.
	assert_eq(_player.ammo, _player.max_ammo)


# --- Ranged -----------------------------------------------------------------

func test_firing_spends_ammo() -> void:
	await _arena()
	var before: int = _player.ammo

	await _tap("attack_ranged")
	await _settle(3)

	assert_eq(_player.ammo, before - 1)


func test_an_empty_pool_refuses_to_fire() -> void:
	await _arena()
	_player.spend_ammo(_player.max_ammo)
	assert_eq(_player.ammo, 0, "precondition")

	await _tap("attack_ranged")
	await _settle(3)

	assert_eq(_player.ammo, 0)
	assert_false(_player.can_fire_ranged())


func test_a_shot_damages_a_target_it_reaches() -> void:
	await _arena()
	var dummy := TestArena.dummy(_root, Vector2(500.0, FLOOR_TOP))
	await _settle(3)

	await _tap("attack_ranged")
	await _settle(40)

	var zipgun: RangedWeapon = load("res://src/combat/weapons/zipgun.tres")
	assert_eq(dummy.health.hp, 40 - int(zipgun.power))


## Two hurtboxes can land in one shot's overlap list on a single frame — two
## Scavs crowding the same spot is all it takes in a real fight. The shot ends
## on its first resolved contact, so the second target is swept against a box
## whose attack is already gone; the sweep has to notice.
func test_a_shot_into_two_overlapping_targets_hits_one_and_ends_there() -> void:
	await _arena()
	var first := TestArena.dummy(_root, Vector2(500.0, FLOOR_TOP))
	var second := TestArena.dummy(_root, Vector2(500.0, FLOOR_TOP))
	await _settle(3)

	await _tap("attack_ranged")
	await _settle(40)

	# Two assertions in one: no pierce (exactly one of the pair is hurt), and
	# no error on the landing frame — GUT fails a test on an unexpected script
	# error, which is the symptom itself.
	var hurt: int = 0
	for dummy: TrainingDummy in [first, second] as Array[TrainingDummy]:
		if dummy.health.hp < 40:
			hurt += 1
	assert_eq(hurt, 1, "the shot should stop at the first target it resolves")


# --- Eight-way aim ----------------------------------------------------------

func test_neutral_aim_follows_facing() -> void:
	await _arena()
	assert_eq(_player.aim_direction(), Vector2(1.0, 0.0))
	_player.set_facing(-1)
	assert_eq(_player.aim_direction(), Vector2(-1.0, 0.0))


func test_holding_up_aims_straight_up() -> void:
	await _arena()
	# The Watcher drone is a vertical threat, so this is the feel constraint
	# items.md exported for M2.
	Input.action_press("move_up")
	await _settle(2)
	assert_eq(_player.aim_direction(), Vector2(0.0, -1.0))


func test_up_and_forward_aims_diagonally() -> void:
	await _arena()
	Input.action_press("move_up")
	Input.action_press("move_right")
	await _settle(2)

	var aim: Vector2 = _player.aim_direction()
	assert_almost_eq(aim.x, aim.y * -1.0, 0.001, "should be a true 45 degrees")
	assert_almost_eq(aim.length(), 1.0, 0.001, "should be normalised")


func test_aiming_down_is_ignored_on_the_ground() -> void:
	await _arena()
	Input.action_press("move_down")
	await _settle(2)
	# Downward on a floor would just hit the floor, so it is ignored rather
	# than wasted.
	assert_eq(_player.aim_direction(), Vector2(1.0, 0.0))


# --- Contact damage and i-frames --------------------------------------------

func test_contact_damage_is_gated_by_the_iframe_window() -> void:
	await _arena()
	# Standing inside the dummy: contact is a continuous condition, so without
	# i-frames this would tick every single physics frame.
	TestArena.dummy(_root, Vector2(0.0, FLOOR_TOP), 40, 0, 1, true)
	await _settle(20)

	var expected: int = int(6.0 * _config.contact_damage_mult)
	assert_eq(
		_player.health.hp,
		_player.health.max_hp - expected,
		"contact damage ignored the i-frame window"
	)
	assert_true(_player.health.is_invulnerable())


func test_contact_damage_resumes_once_the_window_closes() -> void:
	await _arena()
	TestArena.dummy(_root, Vector2(0.0, FLOOR_TOP), 40, 0, 1, true)
	await _settle(20)

	var after_first: int = _player.health.hp
	# The window is 0.7s ≈ 42 physics frames; 70 clears it comfortably.
	await _settle(70)

	assert_lt(_player.health.hp, after_first, "the window never reopened")


# --- Step 9: knockback ------------------------------------------------------

## Resolves one hit straight through the hurtbox and reports the impulse it
## produced, before friction or the dummy's walk-back can touch it.
func _knockback_from(dummy: TrainingDummy, power: float, knockback: float) -> float:
	var hurtbox: Hurtbox = dummy.get_node("Hurtbox")
	var attack := Attack.make(
		null, dummy.global_position - Vector2(100.0, 0.0), power, knockback
	)
	dummy.velocity = Vector2.ZERO
	hurtbox.receive(attack)
	return dummy.velocity.x


func test_a_flinch_is_pushed_less_far_than_a_stagger() -> void:
	await _arena()
	var staggers := TestArena.dummy(_root, Vector2(400.0, FLOOR_TOP), 40, 0, 1)
	var flinches := TestArena.dummy(_root, Vector2(800.0, FLOOR_TOP), 40, 0, 12)
	await _settle(3)

	var full: float = _knockback_from(staggers, 8.0, 280.0)
	var partial: float = _knockback_from(flinches, 8.0, 280.0)

	# This is the only way `stagger_threshold` is visible without any UI: the
	# Riot unit shrugging off a wrench has to *look* like shrugging it off.
	assert_almost_eq(full, 280.0, 1.0)
	assert_almost_eq(partial, 280.0 * _config.flinch_knockback_mult, 1.0)


func test_knockback_pushes_away_from_the_attacker_and_stays_horizontal() -> void:
	await _arena()
	var dummy := TestArena.dummy(_root, Vector2(400.0, FLOOR_TOP))
	await _settle(3)

	var pushed: float = _knockback_from(dummy, 8.0, 280.0)
	assert_gt(pushed, 0.0, "hit from the left, so it must travel right")
	# Never radial: upward knockback would pop bodies into pits, and upward is
	# where this game's platforming lives.
	assert_eq(dummy.velocity.y, 0.0)


# --- The swing tell ---------------------------------------------------------

## The tell is found rather than exposed: the player does not need a public
## accessor just so a test can look at it.
func _swing_tell() -> ColorRect:
	for child: Node in _player.melee_hitbox.get_children():
		if child is ColorRect:
			return child as ColorRect
	return null


func test_the_swing_is_invisible_until_it_swings() -> void:
	await _arena()
	var tell := _swing_tell()
	assert_not_null(tell, "melee has no visual tell at all")
	assert_false(tell.visible)


func test_the_tell_is_exactly_the_size_of_the_hitbox() -> void:
	await _arena()
	await _tap("attack_melee")
	await _settle(2)

	# In a tuning lab the tell has to *be* the truth. A swing arc drawn bigger
	# than its hitbox teaches a reach the player does not have, and every whiff
	# after that reads as the game dropping inputs.
	assert_eq(_swing_tell().size, _wrench.hitbox_size)


func test_the_tell_appears_on_the_swing_and_clears_when_it_ends() -> void:
	await _arena()
	await _tap("attack_melee")
	await _settle(2)
	assert_true(_swing_tell().visible, "nothing was drawn for the swing")

	# commit_time is 0.16s ~ 10 physics frames; 40 clears it comfortably.
	await _settle(40)
	assert_false(_swing_tell().visible, "the tell outlived the swing")
	assert_eq(_player.state_name(), &"Idle")


func test_the_tell_mirrors_with_facing() -> void:
	await _arena()
	Input.action_press("move_left")
	await _settle(4)
	await _tap("attack_melee")
	await _settle(2)

	# The box is placed by facing, and the tell is its child, so it cannot
	# drift away from what it is drawing.
	assert_lt(_player.melee_hitbox.position.x, 0.0)
	assert_eq(_player.facing, -1)
