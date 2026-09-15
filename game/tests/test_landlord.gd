extends GutTest
## The Landlord (docs/characters/boss-landlord.md).
##
## "A wall worth climbing" is a set of numbers before it is a fight: the
## light hits bounce, the heavy hits and Overload interrupt, half health
## changes the fight, and his death ends the slice. Those are asserted here;
## whether he takes three attempts or eight is Marcos's to feel.

const FLOOR_TOP := 600.0
const LANDLORD := preload("res://src/enemies/boss_landlord/landlord.tscn")

var _config: EnemyConfig
var _combat: CombatConfig
var _root: Node2D
var _player: Player
var _boss: Landlord


func before_each() -> void:
	TestArena.release_all_input()
	Hitstop.cancel()
	GameState.reset()
	PlayerStats.reset()
	Inventory.reset()
	_config = load("res://src/enemies/boss_landlord/landlord.tres")
	_combat = load("res://src/combat/combat_config.tres")
	_root = Node2D.new()
	add_child_autofree(_root)


func after_each() -> void:
	TestArena.release_all_input()
	Hitstop.cancel()
	Engine.time_scale = 1.0
	GameState.reset()
	PlayerStats.reset()


func _arena(boss_x: float = 700.0) -> void:
	TestArena.solid(_root, Vector2(0, FLOOR_TOP + 100.0), Vector2(12000, 200))
	_player = TestArena.player(_root, Vector2(0, FLOOR_TOP))
	_boss = LANDLORD.instantiate()
	_boss.position = Vector2(boss_x, FLOOR_TOP)
	_root.add_child(_boss)
	await wait_frames(3)


func _settle(frames: int) -> void:
	for _i: int in frames:
		await get_tree().physics_frame


## The sheet a player who did the district carries (level 5).
func _at_level_five() -> void:
	PlayerStats.restore({"level": 5, "xp": PlayerStats.xp_curve.cumulative_to(5)})


func _hit_for(path: String, stat: int) -> int:
	var weapon: Weapon = load(path)
	return Damage.final_damage(weapon.damage_at(stat, _combat), _config.defense)


func _hurt(amount: float) -> DamageResult:
	var attack := Attack.make(null, _boss.global_position - Vector2(200, 0), amount, 0.0)
	attack.scales_with_stat = false
	return (_boss.get_node("Hurtbox") as Hurtbox).receive(attack)


# --- The numbers -----------------------------------------------------------------------

func test_the_block_is_low_hundreds_with_armour() -> void:
	assert_between(_config.max_hp, 150, 400, "boss HP is low hundreds, never four digits")
	assert_eq(_config.defense, 5, "the DEF pass: the most armoured thing in the slice, at the top of the locked range since 2026-09-15")
	assert_eq(_config.stagger_threshold, 16)
	assert_eq(_config.xp_reward, 200)


func test_light_hits_chip_and_heavy_hits_interrupt_at_the_level_he_is_met() -> void:
	_at_level_five()
	var str_stat: int = PlayerStats.strength()
	var dex_stat: int = PlayerStats.dexterity()
	var wrench: int = _hit_for("res://src/combat/weapons/wrench.tres", str_stat)
	var blade: int = _hit_for("res://src/combat/weapons/utility_blade.tres", str_stat)
	var maul: int = _hit_for("res://src/combat/weapons/breaker_maul.tres", str_stat)
	var rivet: int = _hit_for("res://src/combat/weapons/rivet_gun.tres", dex_stat)
	assert_gt(wrench, 1, "the wrench should still hurt him")
	assert_lt(wrench, _config.stagger_threshold, "the wrench interrupts the boss — swapping weapons buys nothing")
	assert_lt(blade, _config.stagger_threshold)
	assert_gte(maul, _config.stagger_threshold, "the maul does not interrupt him")
	assert_gte(rivet, _config.stagger_threshold, "the rivet gun does not interrupt him")


func test_overload_interrupts_him_at_the_level_he_is_met() -> void:
	_at_level_five()
	var overload: Hack = HackKit.hack_by_id(&"overload")
	var raw: float = overload.power * Damage.stat_multiplier(PlayerStats.intelligence(), _combat.stat_max_bonus, _combat.stat_half_point)
	assert_gte(Damage.final_damage(raw, _config.defense), _config.stagger_threshold)


func test_he_is_not_a_machine_but_his_support_is() -> void:
	# Breach has a job in the fight because of the drones, not because of him.
	assert_does_not_have(_config.tags, Health.TAG_MECHANICAL)
	var drone: EnemyConfig = load("res://src/enemies/drone/drone.tres")
	assert_has(drone.tags, Health.TAG_MECHANICAL)


func test_every_attack_has_a_readable_tell() -> void:
	await _arena()
	assert_gte(_config.windup_time, 0.45, "the baton's tell")
	assert_gte(_boss.slam_windup, 0.6, "the slam's tell")
	assert_gte(_config.fire_windup, 0.7, "the beam's tell")
	assert_gt(_config.recover_time, 0.5, "no punish window after a swing")


# --- Picking ---------------------------------------------------------------------------------

func test_he_picks_the_baton_up_close_and_the_slam_at_range() -> void:
	await _arena()
	_player.global_position = Vector2(_boss.global_position.x - 150.0, FLOOR_TOP)
	assert_eq(_boss.pick_attack(), &"Windup")
	_player.global_position = Vector2(_boss.global_position.x - 500.0, FLOOR_TOP)
	assert_eq(_boss.pick_attack(), &"SlamWindup")


func test_the_beam_is_phase_two_only() -> void:
	await _arena()
	_player.global_position = Vector2(_boss.global_position.x - 600.0, FLOOR_TOP)
	assert_ne(_boss.pick_attack(), &"BeamWindup", "the beam showed up in phase one")
	_boss.phase = 2
	assert_eq(_boss.pick_attack(), &"BeamWindup")


func test_the_slam_sends_a_wave_each_way_along_the_floor() -> void:
	await _arena()
	_boss.slam()
	await _settle(2)
	var waves: Array = []
	for child: Node in _root.get_children():
		if child is Projectile:
			waves.append(child)
	assert_eq(waves.size(), 2)
	if waves.size() == 2:
		assert_lt((waves[0] as Projectile).velocity.x * (waves[1] as Projectile).velocity.x, 0.0, "both waves went the same way")
		assert_eq((waves[0] as Projectile).velocity.y, 0.0, "a floor wave should stay on the floor")


func test_the_beam_draws_its_line_then_fires() -> void:
	await _arena()
	_boss.phase = 2
	_boss._state_machine.transition_to(&"BeamWindup")
	await _settle(2)
	var lines: int = 0
	for child: Node in _boss.get_children():
		if child is Line2D:
			lines += 1
	assert_eq(lines, 1, "no tell for the beam")
	await _settle(int(_config.fire_windup * 60.0) + 6)
	var shots: int = 0
	for child: Node in _root.get_children():
		if child is Projectile:
			shots += 1
	assert_eq(shots, 1, "the tell ended with no beam")
	assert_gte(_config.projectile_speed, 800.0, "the beam is meant to be fast — the tell is the warning")


# --- Phases ---------------------------------------------------------------------------------

func test_half_health_starts_phase_two_with_drones() -> void:
	await _arena()
	watch_signals(Events)
	_hurt(float(_config.max_hp) * 0.5 + _config.defense + 1.0)
	assert_eq(_boss.phase, 2)
	assert_eq(_boss.state_name(), &"PhaseShift")
	assert_true(_boss.health.is_invulnerable(), "the shift is not a free hit window")
	assert_signal_emitted_with_parameters(Events, "boss_phase_changed", [2])
	await _settle(int(_boss.phase_shift_time * 60.0) + 6)
	assert_ne(_boss.state_name(), &"PhaseShift", "the shift never ended")
	var drones: int = 0
	for child: Node in _root.get_children():
		if child is Enemy and child != _boss:
			drones += 1
	assert_eq(drones, _boss.drones_on_phase_two, "support did not arrive")


func test_phase_two_is_faster() -> void:
	await _arena()
	var before: float = _boss.approach_speed()
	_boss.phase = 2
	assert_gt(_boss.approach_speed(), before)
	assert_lt(_boss.phase2_cooldown_mult, 1.0)


# --- Death ---------------------------------------------------------------------------------------

func test_his_death_pays_out_and_ends_the_slice() -> void:
	await _arena()
	watch_signals(Events)
	for _i: int in 6:
		_hurt(200.0)
		_boss.health.clear_iframes()
		await _settle(2)
	assert_eq(_boss.state_name(), &"Dead")
	assert_signal_emitted(Events, "boss_defeated")
	assert_true(GameState.has_flag(&"boss.landlord_defeated"))
	assert_signal_emitted(Events, "enemy_died")
	assert_eq(get_signal_parameters(Events, "enemy_died")[1], 200, "the boss pays 200 XP")


func test_the_arena_seals_while_he_lives_and_opens_when_he_dies() -> void:
	# A Room with one Door, the boss under it.
	var room := Node2D.new()
	room.set_script(load("res://src/world/room.gd"))
	room.set("room_id", &"test_arena")
	room.set("announces_on_ready", false)
	_root.add_child(room)
	var doors := Node2D.new()
	doors.name = "Doors"
	room.add_child(doors)
	var door := Door.new()
	door.name = "1"
	door.door_id = &"1"
	door.position = Vector2(30, FLOOR_TOP - 90)
	doors.add_child(door)
	TestArena.solid(room, Vector2(0, FLOOR_TOP + 100.0), Vector2(12000, 200))
	_player = TestArena.player(room, Vector2(300, FLOOR_TOP))
	_boss = LANDLORD.instantiate()
	_boss.position = Vector2(900, FLOOR_TOP)
	room.add_child(_boss)
	await wait_frames(3)
	assert_true(door.is_locked(), "the arena did not seal")

	for _i: int in 6:
		_hurt(200.0)
		_boss.health.clear_iframes()
		await _settle(2)
	assert_false(door.is_locked(), "the arena stayed sealed after his death")


func test_the_arena_has_platforms_for_the_slam() -> void:
	var spec: RoomSpec = RoomSpec.load_file("res://tools/stacks/collections.room")
	assert_gte(spec.rects_of("=").size(), 2, "the slam needs ledges to jump to")
	assert_eq(spec.positions_of("B").size(), 1)
	var boss_room: Node = autofree(load("res://rooms/stacks/collections.tscn").instantiate())
	var encounter: Encounter = boss_room.get_node_or_null("Boss") as Encounter
	assert_not_null(encounter, "no boss encounter in the arena — regenerate")
	if encounter != null:
		assert_ne(String(encounter.persist_flag), "", "a boss that comes back")
