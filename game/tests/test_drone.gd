extends GutTest
## The Watcher drone (docs/characters/enemies.md).
##
## The lesson is *vertical threat, and the ranged verb*: it holds above
## melee reach, it telegraphs its shot, and Breach drops it out of the air.
## Those are what a plausible retune can break without anything throwing.

const FLOOR_TOP := 600.0
const DRONE := preload("res://src/enemies/drone/drone.tscn")

var _config: EnemyConfig
var _root: Node2D
var _player: Player
var _drone: Enemy


func before_each() -> void:
	TestArena.release_all_input()
	Hitstop.cancel()
	GameState.reset()
	PlayerStats.reset()
	Inventory.reset()
	_config = load("res://src/enemies/drone/drone.tres")
	_root = Node2D.new()
	add_child_autofree(_root)


func after_each() -> void:
	TestArena.release_all_input()
	Hitstop.cancel()
	Engine.time_scale = 1.0
	GameState.reset()


func _arena(drone_at: Vector2 = Vector2(420.0, 360.0)) -> void:
	TestArena.solid(_root, Vector2(0, FLOOR_TOP + 100.0), Vector2(12000, 200))
	_player = TestArena.player(_root, Vector2(0, FLOOR_TOP))
	_drone = DRONE.instantiate()
	_drone.position = drone_at
	_root.add_child(_drone)
	await wait_frames(3)


func _settle(frames: int) -> void:
	for _i: int in frames:
		await get_tree().physics_frame


func _wait_for_state(wanted: StringName, max_frames: int = 300) -> bool:
	for _i: int in max_frames:
		if _drone.state_name() == wanted:
			return true
		await get_tree().physics_frame
	return false


func _projectiles() -> Array:
	var out: Array = []
	for child: Node in _root.get_children():
		if child is Projectile:
			out.append(child)
	return out


# --- The stat block --------------------------------------------------------------

func test_it_is_fragile_and_mechanical() -> void:
	assert_eq(_config.max_hp, 10)
	assert_eq(_config.defense, 0, "the DEF pass leaves the drone at 0 — it dies to being reached")
	assert_has(_config.tags, Health.TAG_MECHANICAL, "Breach must answer it")
	assert_true(_config.flies)
	assert_true(_config.fires)


func test_two_zipgun_shots_kill_it() -> void:
	# The enemy the ranged verb is taught with: the starter pistol handles it.
	var zipgun: RangedWeapon = load("res://src/combat/weapons/zipgun.tres")
	var combat: CombatConfig = load("res://src/combat/combat_config.tres")
	var per_shot: int = Damage.final_damage(zipgun.damage_at(PlayerStats.dexterity(), combat), _config.defense)
	assert_lte(ceili(float(_config.max_hp) / float(per_shot)), 2)


func test_it_pays_about_one_and_a_half_scavs() -> void:
	var scav: EnemyConfig = load("res://src/enemies/scav/scav.tres")
	var ratio: float = float(_config.xp_reward) / float(scav.xp_reward)
	assert_between(ratio, 1.3, 1.6, "XP ratio %.2f" % ratio)


func test_the_shot_is_slow_and_telegraphed() -> void:
	assert_lte(_config.projectile_speed, 400.0, "a dodgeable shot is a slow one")
	assert_gte(_config.fire_windup, 0.4, "the tell has to be readable")


# --- Flight ---------------------------------------------------------------------------

func test_it_hovers_above_melee_reach_when_aware() -> void:
	await _arena()
	assert_true(await _wait_for_state(&"Track"), "never noticed the player")
	await _settle(120)
	var wrench: MeleeWeapon = load("res://src/combat/weapons/wrench.tres")
	var reach_top: float = FLOOR_TOP + wrench.hitbox_offset.y - wrench.hitbox_size.y * 0.5
	assert_lt(_drone.global_position.y, reach_top - 60.0, "hovering inside wrench reach")
	assert_gte(_config.hover_height, 180.0)


func test_it_holds_station_beside_the_player() -> void:
	await _arena()
	assert_true(await _wait_for_state(&"Track"))
	await _settle(150)
	var dx: float = absf(_drone.global_position.x - _player.global_position.x)
	assert_between(dx, _config.hover_standoff - 90.0, _config.hover_standoff + 90.0,
		"standing off by %.0f, wanted ~%.0f" % [dx, _config.hover_standoff])
	var wanted_y: float = FLOOR_TOP - 44.0 - _config.hover_height
	assert_almost_eq(_drone.global_position.y, wanted_y, 70.0)


func test_it_telegraphs_then_fires() -> void:
	await _arena()
	assert_true(await _wait_for_state(&"Aim", 400), "never aimed")
	assert_eq(_projectiles().size(), 0, "fired before the tell ended")
	assert_true(await _wait_for_state(&"Track", 120), "never finished aiming")
	assert_eq(_projectiles().size(), 1, "the tell ended with no shot")
	var shot: Projectile = _projectiles()[0]
	assert_true(shot.attack.is_ranged)
	assert_false(shot.attack.scales_with_stat, "enemy hits are flat")
	assert_eq(shot.attack.source, _drone)


func test_the_shot_hurts_the_player_for_the_flat_number() -> void:
	await _arena(Vector2(0.0, 300.0))
	_player.set_physics_process(false)  # stand still under it
	var before: int = _player.health.hp
	var landed := false
	for _i: int in 360:
		await get_tree().physics_frame
		if _player.health.hp < before:
			landed = true
			break
	assert_true(landed, "no shot reached a player standing still")
	assert_eq(before - _player.health.hp, int(_config.attack_power))


# --- Breach ---------------------------------------------------------------------------

func test_breach_drops_it_out_of_the_air_and_it_climbs_back() -> void:
	await _arena()
	assert_true(await _wait_for_state(&"Track"))
	await _settle(60)
	var y_before: float = _drone.global_position.y
	assert_true(_drone.stun(1.0))
	assert_eq(_drone.state_name(), &"Stunned")
	await _settle(30)
	assert_gt(_drone.global_position.y, y_before + 40.0, "a stunned drone did not fall")
	assert_false(_drone.contact_hitbox.is_active(), "still dangerous to touch while down")
	await _settle(60)
	assert_ne(_drone.state_name(), &"Stunned", "the stun never ended")
	var y_down: float = _drone.global_position.y
	await _settle(60)
	assert_lt(_drone.global_position.y, y_down - 40.0, "it did not climb back")


func test_a_dead_drone_falls() -> void:
	await _arena()
	await _settle(5)
	var y_before: float = _drone.global_position.y
	for _i: int in 3:
		_drone.get_node("Hurtbox").receive(Attack.make(null, Vector2.ZERO, 8.0, 0.0))
		await _settle(2)
	assert_eq(_drone.state_name(), &"Dead")
	await _settle(15)
	assert_gt(_drone.global_position.y, y_before + 20.0, "a dead drone hung in the air")
