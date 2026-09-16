extends GutTest
## The juice layer (M7; docs/art/direction.md): a hit leaves a number and
## sparks, a landing leaves dust, and none of it touches the systems that
## emitted the signal.

var _juice: Juice
var _target: Node2D


func before_each() -> void:
	_juice = Juice.new()
	add_child_autofree(_juice)
	_target = Node2D.new()
	_target.position = Vector2(300.0, 200.0)
	add_child_autofree(_target)


func _count(type: String) -> int:
	var n: int = 0
	for child: Node in _juice.get_children():
		if child.get_class() == type:
			n += 1
	return n


func test_damage_leaves_a_number_and_sparks() -> void:
	Events.damage_dealt.emit(_target, 10, null)
	assert_eq(_count("CPUParticles2D"), 1)
	assert_eq(_count("Label"), 1)
	var label: Label = null
	for child: Node in _juice.get_children():
		if child is Label:
			label = child
	assert_eq(label.text, "10")


func test_damage_to_the_player_shows_no_number() -> void:
	_target.add_to_group(&"player")
	Events.damage_dealt.emit(_target, 10, null)
	assert_eq(_count("Label"), 0)


func test_a_landing_leaves_dust_and_a_dash_leaves_nothing_here() -> void:
	Events.player_action.emit(&"land", Vector2(100.0, 100.0), 1)
	assert_eq(_count("CPUParticles2D"), 1)
	Events.player_action.emit(&"dash", Vector2(100.0, 100.0), 1)
	assert_eq(_count("CPUParticles2D"), 1, "ghosts come from the dash state, not the action")


func test_an_enemy_death_bursts_and_shakes() -> void:
	watch_signals(Events)
	Settings.screen_shake = true
	Events.enemy_died.emit(_target, 10, 5)
	assert_gte(_count("CPUParticles2D"), 2)
	assert_signal_emitted(Events, "camera_shake_requested")


func test_the_burst_cleans_up_after_itself() -> void:
	Events.impact.emit(Vector2(50.0, 50.0), Color.WHITE)
	assert_eq(_count("CPUParticles2D"), 1)
	await wait_seconds(0.5)
	assert_eq(_count("CPUParticles2D"), 0)
