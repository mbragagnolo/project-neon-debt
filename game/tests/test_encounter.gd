extends GutTest
## `Encounter` (src/world/encounter.gd).
##
## Regression home for a bug that every existing test missed: the combat gym
## tests only ever *inspected* the packed scene, so nothing had run an
## encounter in a live tree with an enemy actually dying in it. The tracking
## list held freed nodes, and the first Scav to die threw on the next frame.

const FLOOR_TOP := 600.0

var _root: Node2D
var _encounter: Encounter


func before_each() -> void:
	Hitstop.cancel()
	_root = Node2D.new()
	add_child_autofree(_root)


func after_each() -> void:
	Hitstop.cancel()
	Engine.time_scale = 1.0


## An encounter with `count` spawn markers, spread out so its enemies do not
## immediately pile into each other.
func _build(count: int, respawn_delay: float = 0.0) -> void:
	TestArena.solid(_root, Vector2(0, FLOOR_TOP + 100.0), Vector2(12000, 200))

	_encounter = Encounter.new()
	_encounter.enemy_scene = load("res://src/enemies/scav/scav.tscn")
	_encounter.respawn_delay = respawn_delay
	for i: int in count:
		var marker := Marker2D.new()
		marker.name = "Spawn%d" % (i + 1)
		# Far from the encounter origin, matching the real arena. Spawning near
		# the origin hides the whole class of home-relative bug, because the
		# wrong answer is still inside the leash.
		marker.position = Vector2(2900.0 + 500.0 * float(i), FLOOR_TOP)
		_encounter.add_child(marker)
	_root.add_child(_encounter)
	await wait_frames(3)


func _settle(frames: int) -> void:
	for _i: int in frames:
		await get_tree().physics_frame


## Every living enemy under the encounter, found by type rather than by asking
## the encounter — the point is to check its bookkeeping against reality.
func _living_enemies() -> Array:
	var found: Array = []
	for child in _encounter.get_children():
		if child is Enemy and is_instance_valid(child):
			found.append(child)
	return found


func test_it_spawns_one_enemy_per_marker() -> void:
	await _build(3)
	assert_eq(_living_enemies().size(), 3)
	assert_eq(_encounter.alive_count(), 3)


func test_spawns_land_on_their_markers() -> void:
	await _build(2)
	var enemies: Array = _living_enemies()
	assert_eq(enemies.size(), 2)
	# A spawner that ignores its markers piles the whole encounter on one tile.
	assert_gt(absf(enemies[0].global_position.x - enemies[1].global_position.x), 100.0)


## The regression. A dead enemy queue_frees itself, which leaves a dangling
## entry in the tracking list — and a freed node no longer satisfies a typed
## `Node` parameter, so the bookkeeping threw every frame from then on.
func test_it_survives_an_enemy_actually_dying() -> void:
	await _build(2)
	var enemies: Array = _living_enemies()

	enemies[0].queue_free()
	await _settle(5)

	assert_eq(_encounter.alive_count(), 1, "the encounter lost count after a death")
	assert_eq(_living_enemies().size(), 1)


func test_counting_stays_correct_once_the_whole_group_is_gone() -> void:
	await _build(2)
	for enemy in _living_enemies():
		enemy.queue_free()
	await _settle(5)

	assert_eq(_encounter.alive_count(), 0)


func test_it_announces_when_the_group_is_cleared() -> void:
	await _build(2)
	var cleared_count: Array[int] = [0]
	_encounter.cleared.connect(func() -> void: cleared_count[0] += 1)

	for enemy in _living_enemies():
		enemy.queue_free()
	await _settle(10)

	assert_eq(cleared_count[0], 1, "clearing the group should announce exactly once")


func test_it_repopulates_so_a_fight_can_be_rerun() -> void:
	# 0.25s respawn keeps the test quick; the gym uses 2.5s.
	await _build(2, 0.25)
	for enemy in _living_enemies():
		enemy.queue_free()
	await _settle(45)

	assert_eq(_encounter.alive_count(), 2, "the encounter never came back")


func test_a_zero_delay_encounter_stays_cleared() -> void:
	# What any shipped room wants: killed things stay killed.
	await _build(2, 0.0)
	for enemy in _living_enemies():
		enemy.queue_free()
	await _settle(45)

	assert_eq(_encounter.alive_count(), 0, "a shipped encounter respawned itself")


## The spawn ordering bug. `add_child` runs the enemy's `_ready`, which is
## where `home` is captured — so positioning it afterwards left every enemy
## believing home was the encounter's origin. Everything measured from home
## then broke at once: the patrol beat, and fatally the aggro leash, which
## kicked the enemy straight back out of Chase every frame it entered.
func test_spawned_enemies_know_where_home_is() -> void:
	await _build(2)
	for enemy in _living_enemies():
		assert_almost_eq(
			enemy.home.x,
			enemy.global_position.x,
			8.0,
			"%s spawned believing home was somewhere else" % enemy.name
		)


func test_a_spawned_enemy_can_actually_reach_its_attack() -> void:
	await _build(1)
	var scav: Enemy = _living_enemies()[0]

	# Stand next to it. A Scav that cannot leave Chase never winds up, never
	# changes colour, and never attacks — which is exactly what a broken leash
	# looks like from the player side.
	var player := TestArena.player(_root, Vector2(scav.global_position.x - 120.0, FLOOR_TOP))
	await _settle(3)
	player.global_position = Vector2(scav.global_position.x - 120.0, FLOOR_TOP)

	var reached := false
	for _i: int in 240:
		if scav.state_name() == &"Windup":
			reached = true
			break
		await get_tree().physics_frame
	assert_true(reached, "a spawned Scav never got past Patrol")
