extends GutTest
## The hack kit (docs/combat/hacks.md), driven through real input and real
## physics like the M2 verbs.
##
## What is protected is the set of locked rules a plausible retune can break
## silently: RAM is the limiter and the 1s cooldown is shared, Firewall halves
## after DEF and before the floor, Overload ignores shields but not DEF and
## picks the nearest target, Breach moves machines and nothing else, and the
## quickslot belongs to the Cyberdeck.

const FLOOR_TOP := 600.0

var _root: Node2D
var _player: Player
var _kit: HackKit
var _catalog: HackCatalog
var _config: HackConfig
var _combat: CombatConfig


func before_each() -> void:
	TestArena.release_all_input()
	Hitstop.cancel()
	GameState.reset()
	PlayerStats.reset()
	Inventory.reset()
	_catalog = load("res://src/combat/hacks/catalog.tres")
	_config = load("res://src/combat/hacks/hack_config.tres")
	_combat = load("res://src/combat/combat_config.tres")
	_root = Node2D.new()
	add_child_autofree(_root)


func after_each() -> void:
	TestArena.release_all_input()
	Hitstop.cancel()
	Engine.time_scale = 1.0
	GameState.reset()
	PlayerStats.reset()
	Inventory.reset()


func _arena() -> void:
	TestArena.solid(_root, Vector2(0, FLOOR_TOP + 100.0), Vector2(6000, 200))
	_player = TestArena.player(_root, Vector2(0, FLOOR_TOP))
	_kit = _player.hacks
	await wait_frames(3)


func _settle(frames: int) -> void:
	for _i: int in frames:
		await get_tree().physics_frame


func _tap(action: String) -> void:
	Input.action_press(action)
	await get_tree().physics_frame
	Input.action_release(action)


## Every program plus the deck, the state the district reaches by its midpoint.
func _own_everything() -> void:
	HackKit.grant(&"overload")
	HackKit.grant(&"breach")
	GameState.grant_ability(GameState.ABILITY_CYBERDECK)


func _select(hack_id: StringName) -> void:
	for _i: int in 4:
		if _kit.selected() != null and _kit.selected().id == hack_id:
			return
		_kit.select_next()
	fail_test("could not select %s" % hack_id)


func _hack(hack_id: StringName) -> Hack:
	return _catalog.by_id(hack_id)


## What Overload lands for against `defense` at the sheet the player carries.
func _overload_hit(defense: int) -> int:
	var raw: float = _hack(&"overload").power * Damage.stat_multiplier(
		PlayerStats.intelligence(), _combat.stat_max_bonus, _combat.stat_half_point
	)
	return Damage.final_damage(raw, defense)


# --- The catalog: what hacks.md locked ------------------------------------

func test_the_three_programs_in_acquisition_order() -> void:
	assert_eq(_catalog.ids(), [&"firewall", &"overload", &"breach"] as Array[StringName])


func test_the_locked_costs() -> void:
	assert_eq(_hack(&"firewall").ram_cost, 4)
	assert_eq(_hack(&"overload").ram_cost, 3)
	assert_eq(_hack(&"breach").ram_cost, 2)


func test_one_shape_each_defense_damage_control() -> void:
	assert_eq(_hack(&"firewall").effect, Hack.Effect.GUARD)
	assert_eq(_hack(&"overload").effect, Hack.Effect.BURST)
	assert_eq(_hack(&"breach").effect, Hack.Effect.PULSE)


func test_a_full_starting_pool_is_three_firewall_casts() -> void:
	# The pool-sizing rule: RAM 12 at level 1, Firewall 4 (stats-and-curves.md).
	var curve: StatCurve = load("res://src/rpg/stat_curve.tres")
	assert_eq(curve.ram_at(1) / _hack(&"firewall").ram_cost, 3)


func test_overload_meets_the_riot_units_stagger_threshold() -> void:
	# 15 ≥ 12 is the free synergy hacks.md points at: Overload *interrupts* the
	# Riot unit. A retune that drops it under 12 deletes that without a log
	# line.
	assert_gte(int(_hack(&"overload").power), 12)


# --- Ownership ----------------------------------------------------------------

func test_firewall_is_factory_installed_and_the_rest_are_not() -> void:
	assert_true(_hack(&"firewall").is_factory_installed())
	assert_false(_hack(&"overload").is_factory_installed())
	assert_false(_hack(&"breach").is_factory_installed())


func test_a_fresh_run_owns_firewall_and_only_firewall() -> void:
	await _arena()
	assert_eq(_kit.owned_hacks().size(), 1)
	assert_eq(_kit.selected().id, &"firewall")


func test_a_program_is_granted_once_and_lives_in_the_save() -> void:
	assert_true(HackKit.grant(&"overload"))
	assert_false(HackKit.grant(&"overload"), "granted twice")
	assert_true(GameState.has_flag(&"hack.overload"))
	assert_true(HackKit.is_owned_id(&"overload"))

	# A flag is how it is saved: through the same snapshot doors use.
	var snapshot: Dictionary = GameState.snapshot()
	GameState.reset()
	assert_false(HackKit.is_owned_id(&"overload"), "the reset did not take")
	GameState.restore(snapshot)
	assert_true(HackKit.is_owned_id(&"overload"), "the program did not survive a save")


func test_firewall_cannot_be_granted_because_it_cannot_be_lacked() -> void:
	assert_false(HackKit.grant(&"firewall"))


# --- The quickslot belongs to the Cyberdeck -----------------------------------

func test_cycling_without_the_deck_is_refused_and_says_so() -> void:
	await _arena()
	HackKit.grant(&"overload")
	watch_signals(Events)
	_kit.select_next()
	assert_eq(_kit.selected().id, &"firewall", "cycled without a deck")
	assert_signal_emitted_with_parameters(Events, "hack_failed", [&"firewall", &"no_deck"])


func test_the_deck_unlocks_cycling_in_acquisition_order_and_wraps() -> void:
	await _arena()
	_own_everything()
	assert_eq(_kit.selected().id, &"firewall")
	_kit.select_next()
	assert_eq(_kit.selected().id, &"overload")
	_kit.select_next()
	assert_eq(_kit.selected().id, &"breach")
	_kit.select_next()
	assert_eq(_kit.selected().id, &"firewall", "did not wrap")
	_kit.select_prev()
	assert_eq(_kit.selected().id, &"breach", "did not wrap backwards")


func test_the_cycle_keys_reach_the_kit() -> void:
	await _arena()
	_own_everything()
	await _tap("hack_next")
	await _settle(2)
	assert_eq(_kit.selected().id, &"overload")
	await _tap("hack_prev")
	await _settle(2)
	assert_eq(_kit.selected().id, &"firewall")


# --- RAM is the limiter, the cooldown is the rate cap -------------------------

func test_ram_starts_full_at_the_sheets_ceiling() -> void:
	await _arena()
	assert_eq(_player.max_ram, PlayerStats.effective_max_ram())
	assert_eq(_player.ram, _player.max_ram)
	assert_eq(_player.max_ram, 12, "the locked level-1 pool")


func test_casting_spends_the_cost_and_announces_it() -> void:
	await _arena()
	watch_signals(Events)
	await _tap("hack_cast")
	await _settle(2)
	assert_eq(_player.ram, 12 - _hack(&"firewall").ram_cost)
	assert_signal_emitted_with_parameters(Events, "hack_cast", [&"firewall", 4])


func test_an_empty_pool_refuses_and_spends_nothing() -> void:
	await _arena()
	_player.spend_ram(_player.max_ram)
	watch_signals(Events)
	assert_false(_kit.try_cast())
	assert_eq(_player.ram, 0)
	assert_signal_emitted_with_parameters(Events, "hack_failed", [&"firewall", &"ram"])


func test_the_cooldown_is_shared_across_programs() -> void:
	# One global cooldown, no per-hack cooldowns (hacks.md rule 1). Firewall
	# then Breach back to back must be refused for the cooldown, not the pool.
	await _arena()
	_own_everything()
	assert_true(_kit.try_cast(), "firewall did not cast")
	_select(&"breach")
	assert_eq(_kit.cast_blocker(_kit.selected()), HackKit.Failure.COOLDOWN)
	assert_false(_kit.try_cast())
	assert_eq(_player.ram, 12 - 4, "a refused cast spent RAM")

	await _settle(int(_config.global_cooldown * Engine.physics_ticks_per_second) + 3)
	assert_true(_kit.try_cast(), "the cooldown never released")
	assert_eq(_player.ram, 12 - 4 - 2)


func test_the_rate_cap_is_one_second_and_never_grows_into_rotations() -> void:
	assert_almost_eq(_config.global_cooldown, 1.0, 0.001)


# --- Firewall: GUARD ----------------------------------------------------------

func test_firewall_halves_incoming_damage_after_def_and_then_expires() -> void:
	await _arena()
	assert_true(_kit.try_cast())
	assert_true(_kit.is_guard_active())
	assert_almost_eq(_player.health.guard_mult, 0.5, 0.001)

	# A flat 12 with no DEF: halved is 6.
	_player.hurtbox.receive(Attack.make(null, Vector2(100, FLOOR_TOP), 12.0, 0.0))
	assert_eq(_player.health.hp, _player.health.max_hp - 6)

	_player.health.clear_iframes()
	await _settle(int(_hack(&"firewall").duration * Engine.physics_ticks_per_second) + 5)
	assert_false(_kit.is_guard_active(), "firewall never came down")
	assert_almost_eq(_player.health.guard_mult, 1.0, 0.001)
	_player.hurtbox.receive(Attack.make(null, Vector2(100, FLOOR_TOP), 12.0, 0.0))
	assert_eq(_player.health.hp, _player.health.max_hp - 6 - 12, "still halving after expiry")


func test_the_guard_applies_after_def_and_before_the_floor() -> void:
	# Pipeline step 6, in one function: (raw − DEF) × guard, then the floor.
	assert_eq(Damage.final_damage(10.0, 4, 0.5), 3)
	assert_eq(Damage.final_damage(1.0, 0, 0.5), 1, "the floor still holds under a guard")
	assert_eq(Damage.final_damage(12.0, 0, 1.0), 12)


func test_recasting_firewall_refreshes_rather_than_stacks() -> void:
	await _arena()
	assert_true(_kit.try_cast())
	await _settle(int(_config.global_cooldown * Engine.physics_ticks_per_second) + 3)
	assert_true(_kit.try_cast())
	assert_almost_eq(_player.health.guard_mult, 0.5, 0.001, "stacked below half")
	assert_gt(_kit.guard_remaining(), _hack(&"firewall").duration - 0.1, "did not refresh")


func test_the_guard_is_drawn_while_it_is_up() -> void:
	# A buff the player cannot see is a buff they will not trust enough to
	# cast into a hit.
	await _arena()
	var guard: ColorRect = _player.get_node("Visual/Guard")
	assert_false(guard.visible)
	_kit.try_cast()
	assert_true(guard.visible)


# --- Overload: BURST ----------------------------------------------------------

func test_overload_hits_the_nearest_target_in_reach_and_only_it() -> void:
	await _arena()
	_own_everything()
	var near := TestArena.dummy(_root, Vector2(220.0, FLOOR_TOP))
	var far := TestArena.dummy(_root, Vector2(380.0, FLOOR_TOP))
	await _settle(3)

	_select(&"overload")
	assert_true(_kit.try_cast())
	assert_eq(near.health.hp, 40 - _overload_hit(0), "the nearest was not hit for the INT-scaled number")
	assert_eq(far.health.hp, 40, "the further target was hit too")
	assert_eq(_player.ram, 12 - 3)


func test_overload_scales_with_int_through_the_locked_curve() -> void:
	# Base 15 at INT 5 is ×1.22 → 18. Not 15: hacks enter at step 4 with INT
	# in the stat role, exactly like STR and DEX.
	assert_eq(_overload_hit(0), 18)
	assert_ne(_overload_hit(0), int(_hack(&"overload").power))


func test_overload_ignores_the_shield_and_respects_def() -> void:
	await _arena()
	_own_everything()
	# Facing the player: every shot from here is frontal.
	var shielded := TestArena.dummy(_root, Vector2(300.0, FLOOR_TOP), 60, 5, 12)
	shielded.facing = -1
	shielded.health.tags = [Health.TAG_IMMUNE_RANGED_FRONTAL]
	await _settle(3)

	await _tap("attack_ranged")
	await _settle(30)
	assert_eq(shielded.health.hp, 60, "the shield leaked a shot")

	_select(&"overload")
	assert_true(_kit.try_cast())
	# Through DEF 5 — hacks bypass positional immunity, never DEF.
	assert_eq(shielded.health.hp, 60 - _overload_hit(5))


func test_overload_interrupts_a_heavy_target() -> void:
	await _arena()
	_own_everything()
	var heavy := TestArena.dummy(_root, Vector2(300.0, FLOOR_TOP), 60, 0, 12)
	await _settle(3)
	watch_signals(heavy.health)

	_select(&"overload")
	_kit.try_cast()
	assert_signal_emitted(heavy.health, "staggered", "15 should meet a threshold of 12")


func test_overload_with_nothing_in_reach_refuses_and_costs_nothing() -> void:
	await _arena()
	_own_everything()
	TestArena.dummy(_root, Vector2(_hack(&"overload").radius + 200.0, FLOOR_TOP))
	await _settle(3)
	watch_signals(Events)

	_select(&"overload")
	assert_false(_kit.try_cast())
	assert_eq(_player.ram, 12, "a fizzle spent RAM")
	assert_signal_emitted_with_parameters(Events, "hack_failed", [&"overload", &"no_target"])


func test_overload_pushes_the_target_away_from_the_caster() -> void:
	await _arena()
	_own_everything()
	var dummy := TestArena.dummy(_root, Vector2(300.0, FLOOR_TOP))
	await _settle(3)
	_select(&"overload")
	_kit.try_cast()
	assert_gt(dummy.velocity.x, 0.0, "the player is on the left; it must travel right")


# --- Breach: PULSE ------------------------------------------------------------

func test_breach_stuns_machines_and_not_humans() -> void:
	await _arena()
	_own_everything()
	var machine := TestArena.dummy(_root, Vector2(200.0, FLOOR_TOP), 40, 0, 1, true)
	machine.health.tags = [Health.TAG_MECHANICAL]
	var scav := TestArena.scav(_root, Vector2(300.0, FLOOR_TOP))
	await _settle(3)

	_select(&"breach")
	assert_true(_kit.try_cast())
	assert_true(machine.is_stunned(), "the machine shrugged")
	assert_false(scav.is_stunned(), "a human answered a handshake")
	assert_ne(scav.state_name(), &"Stunned")
	assert_eq(_player.ram, 12 - 2)


func test_a_stunned_machine_stops_hurting_on_contact_until_the_stun_ends() -> void:
	await _arena()
	_own_everything()
	var machine := TestArena.dummy(_root, Vector2(200.0, FLOOR_TOP), 40, 0, 1, true)
	machine.health.tags = [Health.TAG_MECHANICAL]
	await _settle(3)
	var contact: Hitbox = machine.get_node("ContactHitbox")
	assert_true(contact.is_active(), "precondition: armed")

	_select(&"breach")
	_kit.try_cast()
	assert_false(contact.is_active(), "still dangerous to touch while stunned")

	await _settle(int(_hack(&"breach").duration * Engine.physics_ticks_per_second) + 5)
	assert_false(machine.is_stunned(), "the stun never ended")
	assert_true(contact.is_active(), "contact did not re-arm")


func test_a_stunned_enemy_stays_stunned_when_hit() -> void:
	# Breach → walk in → swing freely is the loop. A stun that ends on the
	# first punch teaches the player not to bother casting it.
	await _arena()
	var scav := TestArena.scav(_root, Vector2(2000.0, FLOOR_TOP))
	await _settle(3)
	scav.health.tags = [Health.TAG_MECHANICAL]
	assert_true(scav.stun(1.5))
	assert_eq(scav.state_name(), &"Stunned")

	scav.get_node("Hurtbox").receive(Attack.make(null, Vector2(1900, FLOOR_TOP), 8.0, 280.0))
	await _settle(2)
	assert_eq(scav.state_name(), &"Stunned", "one hit spent the whole stun")
	assert_lt(scav.health.hp, scav.config.max_hp, "the hit did not land")


func test_a_human_enemy_refuses_a_stun() -> void:
	await _arena()
	var scav := TestArena.scav(_root, Vector2(2000.0, FLOOR_TOP))
	await _settle(3)
	assert_false(scav.stun(1.5))
	assert_ne(scav.state_name(), &"Stunned")


# --- RAM regen ----------------------------------------------------------------

func test_ram_trickles_back_and_the_gloves_speed_it_up() -> void:
	await _arena()
	_player.spend_ram(12)
	# Driven directly with a large delta: at 0.4/s, ten seconds of real frames
	# is a slow test for a fact about arithmetic.
	_kit._tick_regen(10.0)
	assert_eq(_player.ram, int(_config.ram_regen_per_second * 10.0))

	_player.spend_ram(12)
	Inventory.grant(&"linesman_gloves")
	_kit._tick_regen(10.0)
	assert_eq(_player.ram, int(_config.ram_regen_per_second * 1.25 * 10.0), "the gloves did nothing")


func test_regen_clamps_at_the_ceiling() -> void:
	await _arena()
	_kit._tick_regen(100.0)
	assert_eq(_player.ram, _player.max_ram)


func test_a_level_up_raises_the_ceiling_but_does_not_refill_ram() -> void:
	# Level-up is a full *heal*; the full RAM restore is a save terminal's
	# job, so the pool has a real cost curve between terminals.
	await _arena()
	_player.spend_ram(12)
	PlayerStats.grant_xp(60)
	await _settle(2)
	assert_eq(PlayerStats.level, 2, "precondition")
	assert_eq(_player.max_ram, 14)
	assert_eq(_player.ram, 0, "a level-up refilled RAM")
	assert_eq(_player.health.hp, _player.health.max_hp, "the full heal is still owed")


# --- No state -----------------------------------------------------------------

func test_a_cast_is_legal_mid_air() -> void:
	await _arena()
	Input.action_press("jump")
	await _settle(6)
	Input.action_release("jump")
	assert_eq(_player.state_name(), &"Air", "precondition")
	await _tap("hack_cast")
	await _settle(2)
	assert_eq(_player.ram, 12 - 4, "firewall is a reaction, not a plan")
