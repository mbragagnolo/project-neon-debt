extends GutTest
## The Riot unit (docs/characters/enemies.md).
##
## The lesson is *heavy hits and hacks*: shots ping off the front, light hits
## only flinch it, and the answers are behind it, the maul, or a program.

const FLOOR_TOP := 600.0
const RIOT := preload("res://src/enemies/riot/riot.tscn")

var _config: EnemyConfig
var _combat: CombatConfig
var _root: Node2D
var _player: Player
var _riot: Enemy


func before_each() -> void:
	TestArena.release_all_input()
	Hitstop.cancel()
	GameState.reset()
	PlayerStats.reset()
	Inventory.reset()
	_config = load("res://src/enemies/riot/riot.tres")
	_combat = load("res://src/combat/combat_config.tres")
	_root = Node2D.new()
	add_child_autofree(_root)


func after_each() -> void:
	TestArena.release_all_input()
	Hitstop.cancel()
	Engine.time_scale = 1.0
	GameState.reset()
	PlayerStats.reset()


func _arena(riot_x: float = 900.0) -> void:
	TestArena.solid(_root, Vector2(0, FLOOR_TOP + 100.0), Vector2(12000, 200))
	_player = TestArena.player(_root, Vector2(0, FLOOR_TOP))
	_riot = RIOT.instantiate()
	_riot.position = Vector2(riot_x, FLOOR_TOP)
	_root.add_child(_riot)
	await wait_frames(3)


func _settle(frames: int) -> void:
	for _i: int in frames:
		await get_tree().physics_frame


func _weapon_hit(path: String, stat: int) -> int:
	var weapon: Weapon = load(path)
	return Damage.final_damage(weapon.damage_at(stat, _combat), _config.defense)


# --- The stat block --------------------------------------------------------------

func test_the_locked_block() -> void:
	assert_eq(_config.max_hp, 35)
	assert_eq(_config.defense, 3, "the DEF pass: the first armoured enemy")
	assert_eq(_config.stagger_threshold, 12)
	assert_has(_config.tags, Health.TAG_MECHANICAL)
	assert_has(_config.tags, Health.TAG_IMMUNE_RANGED_FRONTAL)


func test_it_pays_three_scavs_in_credits() -> void:
	var scav: EnemyConfig = load("res://src/enemies/scav/scav.tres")
	assert_eq(_config.credit_reward, scav.credit_reward * 3)


# --- The shield ------------------------------------------------------------------------

func test_shots_ping_off_the_front_and_land_from_behind() -> void:
	await _arena()
	_riot.set_facing(-1)  # toward the player, on the left
	var hurtbox: Hurtbox = _riot.get_node("Hurtbox")
	var frontal := Attack.make(null, _riot.global_position - Vector2(200, 0), 6.0, 90.0)
	frontal.is_ranged = true
	var result: DamageResult = hurtbox.receive(frontal)
	assert_false(result.landed, "a frontal shot leaked through the shield")
	assert_eq(result.rejection, DamageResult.Rejection.IMMUNE, "rejected, not ground to the floor")

	var rear := Attack.make(null, _riot.global_position + Vector2(200, 0), 6.0, 90.0)
	rear.is_ranged = true
	assert_true(hurtbox.receive(rear).landed, "a shot from behind was refused")


func test_the_player_can_get_behind_it() -> void:
	# Enemies are not solid to the player: dash through, jump over. Contact
	# damage is the price, and i-frames are what make it a price not a wall.
	await _arena()
	assert_eq(_player.collision_mask & 16, 0, "the player collides with enemy bodies")


# --- Light and heavy ---------------------------------------------------------------------

func test_the_wrench_only_flinches_it_and_the_maul_staggers() -> void:
	var stat: int = PlayerStats.strength()
	var wrench: int = _weapon_hit("res://src/combat/weapons/wrench.tres", stat)
	var maul: int = _weapon_hit("res://src/combat/weapons/breaker_maul.tres", stat)
	assert_lt(wrench, _config.stagger_threshold, "the wrench interrupts the Riot unit — the lesson is gone")
	assert_gte(maul, _config.stagger_threshold, "the maul does not interrupt it — nothing does")
	assert_gt(wrench, 1, "the wrench should chip, not floor")


func test_the_blade_is_the_wrong_tool_here() -> void:
	# Flat DEF taxes fast weak hits hardest (stats-and-curves.md). The blade
	# lands near the floor: the armour lesson, felt.
	var blade: int = _weapon_hit("res://src/combat/weapons/utility_blade.tres", PlayerStats.strength())
	assert_lte(blade, 4)


func test_overload_ignores_the_shield_and_interrupts() -> void:
	await _arena()
	_riot.set_facing(-1)
	var overload: Hack = HackKit.hack_by_id(&"overload")
	var attack := Attack.make(null, _riot.global_position - Vector2(200, 0), overload.power, overload.knockback)
	attack.stat = PlayerStats.intelligence()
	attack.is_hack = true
	watch_signals(_riot.health)
	var result: DamageResult = (_riot.get_node("Hurtbox") as Hurtbox).receive(attack)
	assert_true(result.landed, "the shield stopped a hack")
	assert_true(result.staggered, "Overload's 15 should meet a threshold of 12 through DEF 3")
	assert_signal_emitted(_riot.health, "staggered")


func test_breach_stuns_it_and_disarms_the_contact() -> void:
	await _arena()
	assert_true(_riot.stun(1.5))
	assert_eq(_riot.state_name(), &"Stunned")
	assert_false(_riot.contact_hitbox.is_active())


# --- Behaviour ---------------------------------------------------------------------------

func test_it_advances_slowly() -> void:
	var scav: EnemyConfig = load("res://src/enemies/scav/scav.tres")
	assert_lt(_config.chase_speed, scav.chase_speed * 0.6, "a shield wall does not run")


func test_it_telegraphs_a_bash_and_recovers() -> void:
	await _arena()
	_player.global_position = Vector2(_riot.global_position.x - 130.0, FLOOR_TOP)
	var seen: Array[StringName] = []
	for _i: int in 400:
		var state: StringName = _riot.state_name()
		if seen.is_empty() or seen[-1] != state:
			seen.append(state)
		await get_tree().physics_frame
		if seen.has(&"Recover"):
			break
	assert_has(seen, &"Windup", "bashed with no telegraph")
	assert_has(seen, &"Lunge")
	assert_has(seen, &"Recover")
	assert_gte(_config.windup_time, 0.5, "a heavy's tell should be slower than a Scav's")
