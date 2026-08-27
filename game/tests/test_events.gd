extends GutTest
## The signal bus is the wiring diagram for every later milestone, so its
## surface is worth pinning: a rename should be a deliberate, visible change.

const EventsScript := preload("res://src/core/events.gd")

const EXPECTED_SIGNALS := [
	"player_spawned", "player_died",
	"damage_dealt", "enemy_died", "hitstop_requested", "camera_shake_requested",
	"hp_changed", "ram_changed", "ammo_changed",
	"xp_gained", "level_gained", "stats_changed",
	"item_picked_up", "item_equipped", "item_unequipped", "credits_changed",
	"hack_selected", "hack_cast", "hack_failed",
	"room_entered", "room_exited", "door_opened", "save_point_activated",
	"game_saved", "game_loaded",
	"quest_offered", "quest_started", "quest_completed",
	"toast_requested",
]

var _bus: Node


func before_each() -> void:
	_bus = autofree(EventsScript.new())


func test_bus_declares_every_expected_signal() -> void:
	var declared := {}
	for sig: Dictionary in _bus.get_signal_list():
		declared[sig["name"]] = true
	for expected: String in EXPECTED_SIGNALS:
		assert_true(declared.has(expected), "signal bus is missing '%s'" % expected)


func test_bus_holds_no_state() -> void:
	# If the bus grows fields it stops being a bus and starts being a god object.
	var own_properties: Array[String] = []
	for prop: Dictionary in _bus.get_script().get_script_property_list():
		if prop["usage"] & PROPERTY_USAGE_SCRIPT_VARIABLE:
			own_properties.append(prop["name"])
	assert_eq(own_properties, [] as Array[String], "the signal bus must not store state")


func test_signals_round_trip() -> void:
	watch_signals(_bus)
	_bus.room_entered.emit(&"stacks_01")
	assert_signal_emitted_with_parameters(_bus, "room_entered", [&"stacks_01"])
