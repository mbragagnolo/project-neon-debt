extends GutTest
## The combat gym is the M2 deliverable Marcos plays, so the things that would
## waste a tuning session get checked here: a station whose stat block quietly
## reverted, a hitbox that masks the wrong layer, an "elevated" dummy that
## turns out to be reachable by jumping.

const GYM_PATH := "res://rooms/combat_gym.tscn"
const LAYER_WORLD := 1 << 0
const LAYER_PLAYER_HURTBOX := 1 << 3
const LAYER_ENEMY := 1 << 4
const LAYER_ENEMY_HITBOX := 1 << 5
const LAYER_ENEMY_HURTBOX := 1 << 6

var _gym: Node


func before_each() -> void:
	_gym = autofree(load(GYM_PATH).instantiate())


func test_the_combat_gym_is_the_main_scene() -> void:
	# The main scene tracks the active milestone: M1 shipped the movement gym
	# here, M2 ships this one. Pressing play should always land on the thing
	# currently being judged by feel.
	assert_eq(ProjectSettings.get_setting("application/run/main_scene"), GYM_PATH)


func test_it_instances_with_a_player_and_the_five_stations() -> void:
	assert_is(_gym, Room)
	assert_eq(_gym.room_id, &"combat_gym")

	var player: Node = _gym.get_node_or_null("Player")
	assert_not_null(player, "the gym needs a player to be playable")
	assert_is(player, Player)

	var dummies: Node = _gym.get_node_or_null("Dummies")
	assert_not_null(dummies)
	assert_eq(dummies.get_child_count(), 5, "one station per pipeline rule under test")


func test_the_player_arrives_armed() -> void:
	var player: Player = _gym.get_node("Player")
	assert_not_null(player.combat_config, "no CombatConfig — nothing can be hurt")
	assert_not_null(player.melee_weapon, "no melee weapon — J does nothing")
	assert_not_null(player.ranged_weapon, "no ranged weapon — K does nothing")
	assert_gt(player.max_ammo, 0, "an empty pool makes the interlock untestable")


## The regression this file exists for. The stat blocks are set from the
## generator, and `PackedScene.pack()` is fragile about overrides reached
## *inside* an instanced sub-scene — a dummy whose DEF silently reverted to 0
## would look exactly like a pipeline bug.
func test_each_station_kept_the_stat_block_the_generator_gave_it() -> void:
	var dummies: Node = _gym.get_node("Dummies")

	var armoured: TrainingDummy = dummies.get_node("Armoured")
	assert_eq(armoured.defense, 5, "the armour station lost its DEF")

	var heavy: TrainingDummy = dummies.get_node("Heavy")
	assert_eq(heavy.stagger_threshold, 12, "the heavy station lost its threshold")
	assert_eq(heavy.max_hp, 60)

	var contact: TrainingDummy = dummies.get_node("Contact")
	assert_true(contact.hurts_on_contact, "the i-frame station stopped hitting back")

	var baseline: TrainingDummy = dummies.get_node("Baseline")
	assert_eq(baseline.defense, 0, "the baseline must stay unmodified")
	assert_eq(baseline.stagger_threshold, 1)


func test_the_armour_station_actually_produces_a_floor_one_hit() -> void:
	# The station only teaches what it is for if DEF 5 grinds the zipgun's 6
	# down to the floor — that is the "wrong tool" signal, and it is also the
	# hit that must be silent.
	var config: CombatConfig = load("res://src/combat/combat_config.tres")
	var zipgun: RangedWeapon = load("res://src/combat/weapons/zipgun.tres")
	var armoured: TrainingDummy = _gym.get_node("Dummies/Armoured")

	assert_eq(Damage.final_damage(zipgun.power, armoured.defense), 1)
	assert_eq(config.hitstop_frames_for(1), 0, "a floor-1 hit must not freeze")


func test_the_elevated_station_is_out_of_jump_reach() -> void:
	# If it can be reached on foot the ranged aiming constraint never gets
	# exercised, and the station silently stops testing anything.
	var movement: MovementConfig = load("res://src/player/movement_config.tres")
	var elevated: TrainingDummy = _gym.get_node("Dummies/Elevated")
	var baseline: TrainingDummy = _gym.get_node("Dummies/Baseline")

	var rise: float = baseline.position.y - elevated.position.y
	assert_gt(
		rise,
		movement.jump_height,
		"the elevated dummy is within jump height — aim up is no longer required"
	)


func test_combat_layers_are_wired_so_hits_can_find_hurtboxes() -> void:
	var player: Player = _gym.get_node("Player")
	var melee: Area2D = player.get_node("MeleeHitbox")
	var player_hurtbox: Area2D = player.get_node("Hurtbox")
	var dummy: TrainingDummy = _gym.get_node("Dummies/Contact")
	var dummy_hurtbox: Area2D = dummy.get_node("Hurtbox")
	var dummy_contact: Area2D = dummy.get_node("ContactHitbox")

	# Hitboxes go looking; hurtboxes are found and never look back.
	assert_eq(dummy_hurtbox.collision_layer, LAYER_ENEMY_HURTBOX)
	assert_eq(dummy_hurtbox.collision_mask, 0, "a hurtbox that scans is a hurtbox that lies")
	assert_eq(player_hurtbox.collision_layer, LAYER_PLAYER_HURTBOX)
	assert_eq(player_hurtbox.collision_mask, 0)

	assert_eq(
		melee.collision_mask & LAYER_ENEMY_HURTBOX,
		LAYER_ENEMY_HURTBOX,
		"the swing cannot see enemy hurtboxes"
	)
	assert_eq(dummy_contact.collision_layer, LAYER_ENEMY_HITBOX)
	assert_eq(
		dummy_contact.collision_mask & LAYER_PLAYER_HURTBOX,
		LAYER_PLAYER_HURTBOX,
		"contact damage cannot see the player"
	)


func test_the_dummies_are_on_the_enemy_layer_and_collide_only_with_world() -> void:
	for dummy: Node in _gym.get_node("Dummies").get_children():
		var body := dummy as CharacterBody2D
		assert_eq(body.collision_layer, LAYER_ENEMY, "'%s' is not an enemy" % dummy.name)
		# Bodies must not shove each other — overlap is how contact damage and
		# the i-frame station work at all.
		assert_eq(body.collision_mask, LAYER_WORLD, "'%s' collides with more than the world" % dummy.name)


func test_the_arena_holds_the_three_scavs_the_exit_test_asks_for() -> void:
	# The M2 exit test is "fighting 3 Scavs is legible and satisfying", so the
	# count is not decoration — two is a different fight and four is a
	# different fight.
	var arena: Node = _gym.get_node_or_null("ScavArena")
	assert_not_null(arena, "the gym has no Scav arena")
	assert_is(arena, Encounter)

	var markers: int = 0
	for child: Node in arena.get_children():
		if child is Marker2D:
			markers += 1
	assert_eq(markers, 3, "the exit test needs exactly three spawn points")
	assert_not_null((arena as Encounter).enemy_scene)


func test_the_arena_repopulates_so_the_fight_can_be_rerun() -> void:
	# Judging "legible and satisfying" means fighting them more than once, and
	# restarting the game between attempts is how a tuning session dies.
	assert_gt((_gym.get_node("ScavArena") as Encounter).respawn_delay, 0.0)


func test_the_stations_and_the_arena_are_kept_apart() -> void:
	# The stations want a still target and one question at a time; the arena is
	# the opposite. Tuning hitstop while being chased is not a tuning session.
	var last_station: TrainingDummy = _gym.get_node("Dummies/Contact")
	var first_spawn: Marker2D = _gym.get_node("ScavArena/Spawn1")
	assert_gt(first_spawn.position.x, last_station.position.x + 400.0)


func test_gym_solids_are_on_the_world_layer() -> void:
	for solid: Node in _gym.get_node("Geometry").get_children():
		assert_is(solid, StaticBody2D)
		assert_eq(
			(solid as StaticBody2D).collision_layer,
			LAYER_WORLD,
			"'%s' is not on the 'world' layer" % solid.name
		)


func test_it_declares_camera_limits_because_it_is_bigger_than_a_screen() -> void:
	assert_ne((_gym as Room).camera_limits.size, Vector2i.ZERO)
	assert_gt((_gym as Room).camera_limits.size.x, 1920)
